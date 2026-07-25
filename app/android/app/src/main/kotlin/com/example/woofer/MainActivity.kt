package com.example.woofer

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.ConnectivityManager
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.ContextCompat
import androidx.core.content.FileProvider
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException
import java.util.concurrent.Executors

class MainActivity : FlutterActivity() {

    private val channelName = "woofer/storage"
    private val ytdlpChannelName = "ytdlp"

    // yt-dlp calls block; run them off the platform thread to avoid ANRs.
    private val ioExecutor = Executors.newSingleThreadExecutor()
    private var ytdlpChannel: MethodChannel? = null

    /**
     * Use one process-scoped engine instead of the per-Activity default, so a
     * download (which runs in Dart) isn't killed when the Activity is.
     *
     * Deliberately created here on first attach rather than pre-warmed in an
     * Application: that keeps the cold-start ordering identical to before, so
     * `getInitialMedia()` still sees the share intent that launched the app.
     * Caching only changes what happens on the way *out* — the engine outlives
     * the Activity, and DownloadService keeps the process alive around it.
     */
    override fun provideFlutterEngine(context: Context): FlutterEngine {
        val cache = FlutterEngineCache.getInstance()
        cache.get(ENGINE_ID)?.let { return it }
        val engine = FlutterEngine(applicationContext)
        engine.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint.createDefault())
        cache.put(ENGINE_ID, engine)
        return engine
    }

    /** The cache owns the engine now, not this Activity. */
    override fun shouldDestroyEngineWithHost(): Boolean = false

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        configureYtdlpChannel(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
            .setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                        "saveToDownloads" -> result.success(
                            saveToDownloads(
                                call.argument<String>("sourcePath")!!,
                                call.argument<String>("fileName")!!,
                                call.argument<String>("subDir") ?: "woofer",
                                call.argument<String>("mimeType") ?: "application/octet-stream",
                            )
                        )
                        "openFile" -> result.success(
                            openFile(
                                call.argument<String>("path")!!,
                                call.argument<String>("mimeType") ?: "*/*",
                            )
                        )
                        "shareFile" -> result.success(
                            shareFile(
                                call.argument<String>("path")!!,
                                call.argument<String>("mimeType") ?: "*/*",
                            )
                        )
                        "showDownloadNotification" -> result.success(
                            showDownloadNotification(
                                call.argument<String>("title") ?: "Downloading",
                                call.argument<Int>("percent") ?: -1,
                            )
                        )
                        "hideDownloadNotification" -> result.success(hideDownloadNotification())
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.message, null)
                }
            }
    }

    /**
     * The "ytdlp" channel: `extract_info` and `download` delegate to the Python
     * bridge. Both Python functions return a JSON envelope string that we pass
     * straight through to Dart; work runs on [ioExecutor] and results/progress
     * are marshaled back onto the platform thread (Flutter requires it).
     */
    private fun configureYtdlpChannel(flutterEngine: FlutterEngine) {
        if (!Python.isStarted()) {
            // applicationContext, not the Activity: Python outlives it now.
            Python.start(AndroidPlatform(applicationContext))
        }
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, ytdlpChannelName)
        ytdlpChannel = channel
        channel.setMethodCallHandler { call, result ->
            // Bind the process to the active network before any Python networking.
            // Android auto-binds Java/Flutter sockets, but Python's C sockets are
            // unbound, so their DNS lookups fail ("No address associated with
            // hostname") until the whole process is bound to a network.
            bindProcessToActiveNetwork()
            when (call.method) {
                "extract_info" -> {
                    val url = call.argument<String>("url")!!
                    runOnIo(result) { bridge().callAttr("extract_info", url).toString() }
                }
                "download" -> {
                    val url = call.argument<String>("url")!!
                    val formatId = call.argument<String>("format_id")!!
                    val dir = call.argument<String>("dir") ?: applicationContext.cacheDir.absolutePath
                    runOnIo(result) {
                        bridge().callAttr("download", url, formatId, dir, ProgressBridge()).toString()
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun bridge(): PyObject = Python.getInstance().getModule("ytdlp_bridge")

    /** Bind every socket this process opens (including Chaquopy Python's) to the
     *  current active network, so Python DNS resolution works. Re-run per call so
     *  a network switch (Wi-Fi ↔ cellular) is picked up. */
    private fun bindProcessToActiveNetwork() {
        val cm = applicationContext.getSystemService(ConnectivityManager::class.java) ?: return
        cm.activeNetwork?.let { cm.bindProcessToNetwork(it) }
    }

    /** Run [work] on the IO thread; deliver its JSON string (or an error envelope
     *  for an unexpected native failure) back on the platform thread. */
    private fun runOnIo(result: MethodChannel.Result, work: () -> String) {
        ioExecutor.execute {
            val json = try {
                work()
            } catch (e: Throwable) {
                val msg = (e.message ?: e.toString()).replace('"', '\'').replace('\n', ' ')
                """{"ok":false,"code":"UNKNOWN","message":"$msg"}"""
            }
            runOnUiThread { result.success(json) }
        }
    }

    /** Passed to Python; yt-dlp's progress hook calls [onProgress], which we relay
     *  to Dart as an `onProgress` call on the same channel. */
    inner class ProgressBridge {
        fun onProgress(received: Long, total: Long) {
            runOnUiThread {
                ytdlpChannel?.invokeMethod("onProgress", mapOf("received" to received, "total" to total))
            }
        }
    }

    override fun onDestroy() {
        // Deliberately NOT shutting down ioExecutor: a download in flight is running
        // on it, and the whole point of the cached engine + DownloadService is that
        // it keeps going after this Activity is gone. The process dies with the
        // service, which takes the executor with it.
        super.onDestroy()
    }

    /** Start — or refresh — the foreground service that keeps a download alive. */
    private fun showDownloadNotification(title: String, percent: Int): Boolean {
        val intent = Intent(applicationContext, DownloadService::class.java)
            .putExtra(DownloadService.EXTRA_TITLE, title)
            .putExtra(DownloadService.EXTRA_PERCENT, percent)
        ContextCompat.startForegroundService(applicationContext, intent)
        return true
    }

    private fun hideDownloadNotification(): Boolean {
        applicationContext.stopService(Intent(applicationContext, DownloadService::class.java))
        return true
    }

    /** Copy [sourcePath] into public Downloads/[subDir], returning its uri + path. */
    private fun saveToDownloads(
        sourcePath: String,
        fileName: String,
        subDir: String,
        mimeType: String,
    ): Map<String, String> {
        val src = File(sourcePath)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // API 29+ : scoped storage via MediaStore, no runtime permission needed.
            val resolver = applicationContext.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$subDir")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("MediaStore insert returned null")
            resolver.openOutputStream(uri)?.use { out ->
                FileInputStream(src).use { it.copyTo(out) }
            } ?: throw IOException("Could not open output stream for $uri")
            values.clear()
            values.put(MediaStore.Downloads.IS_PENDING, 0)
            resolver.update(uri, values, null, null)
            return mapOf(
                "uri" to uri.toString(),
                "path" to "${Environment.DIRECTORY_DOWNLOADS}/$subDir/$fileName",
            )
        } else {
            // API <=28 : legacy public dir (WRITE_EXTERNAL_STORAGE granted on the Dart side).
            @Suppress("DEPRECATION")
            val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val dir = File(downloads, subDir).apply { mkdirs() }
            val dest = File(dir, fileName)
            FileInputStream(src).use { input -> FileOutputStream(dest).use { input.copyTo(it) } }
            MediaScannerConnection.scanFile(
                applicationContext, arrayOf(dest.absolutePath), arrayOf(mimeType), null
            )
            return mapOf("uri" to Uri.fromFile(dest).toString(), "path" to dest.absolutePath)
        }
    }

    private fun openFile(pathOrUri: String, mimeType: String): Boolean {
        val uri = shareableUri(pathOrUri)
        // Players declare video/* or audio/* filters, so ACTION_VIEW with the caller's
        // "*/*" resolves to nothing. MediaStore (content://) and FileProvider (by
        // extension) both know the real type. A null type on a content:// uri means
        // the row is gone — the user deleted the file — so fail instead of launching
        // a player onto a dead uri.
        val type = resolveType(uri)
        if (type == null && pathOrUri.startsWith("content://")) return false
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, type ?: mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    private fun shareFile(pathOrUri: String, mimeType: String): Boolean {
        val uri = shareableUri(pathOrUri)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = resolveType(uri) ?: mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(intent, "Share").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            startActivity(chooser)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** The concrete MIME type behind [uri], or null if it can't be determined
     *  (unknown extension, or a MediaStore row whose file no longer exists). */
    private fun resolveType(uri: Uri): String? =
        try { applicationContext.contentResolver.getType(uri) } catch (e: Exception) { null }

    /** content:// stays as-is; a file path/uri is wrapped by FileProvider for sharing. */
    private fun shareableUri(pathOrUri: String): Uri {
        if (pathOrUri.startsWith("content://")) return Uri.parse(pathOrUri)
        val path = if (pathOrUri.startsWith("file://")) Uri.parse(pathOrUri).path ?: pathOrUri else pathOrUri
        return FileProvider.getUriForFile(applicationContext, "$packageName.fileprovider", File(path))
    }

    companion object {
        private const val ENGINE_ID = "woofer_engine"
    }
}
