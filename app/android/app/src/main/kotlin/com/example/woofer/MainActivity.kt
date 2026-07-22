package com.example.woofer

import android.content.ActivityNotFoundException
import android.content.ContentValues
import android.content.Intent
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

class MainActivity : FlutterActivity() {

    private val channelName = "woofer/storage"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
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
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.message, null)
                }
            }
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
            val resolver = contentResolver
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
            MediaScannerConnection.scanFile(this, arrayOf(dest.absolutePath), arrayOf(mimeType), null)
            return mapOf("uri" to Uri.fromFile(dest).toString(), "path" to dest.absolutePath)
        }
    }

    private fun openFile(pathOrUri: String, mimeType: String): Boolean {
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(shareableUri(pathOrUri), mimeType)
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
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = mimeType
            putExtra(Intent.EXTRA_STREAM, shareableUri(pathOrUri))
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

    /** content:// stays as-is; a file path/uri is wrapped by FileProvider for sharing. */
    private fun shareableUri(pathOrUri: String): Uri {
        if (pathOrUri.startsWith("content://")) return Uri.parse(pathOrUri)
        val path = if (pathOrUri.startsWith("file://")) Uri.parse(pathOrUri).path ?: pathOrUri else pathOrUri
        return FileProvider.getUriForFile(this, "$packageName.fileprovider", File(path))
    }
}
