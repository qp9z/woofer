package dev.koulei.woofer

import android.content.Context
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.FlutterEngineCache
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.plugin.common.MethodChannel

/**
 * Thin Flutter host that owns the cached engine and wires up the two platform
 * channels. All heavy lifting lives in focused components:
 *
 *  - [YtdlpBridge] — the "ytdlp" channel (Chaquopy Python bridge, blocking calls,
 *    progress relay). Long-lived and process-scoped.
 *  - [MediaStoreSaver] — copying a finished file into public Downloads.
 *  - [FileIntents] — open/share intents for a saved file.
 *  - [DownloadService] / [DownloadActionReceiver] — the foreground notification.
 *
 * The "woofer/storage" channel handler is configured here (it needs the cached
 * engine's binaryMessenger and the Activity for starting intents), but each
 * method just delegates to the component above.
 */
class MainActivity : FlutterActivity() {

    private val storageChannelName = "woofer/storage"

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

    /**
     * Called every time the Activity attaches to the (cached) engine, including
     * recreation. [YtdlpBridge.attach] and the storage handler are idempotent:
     * re-running them re-registers the handlers on the same engine without
     * duplicating plugins (Flutter registers wire-level plugin handlers once, at
     * engine creation).
     */
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // yt-dlp bridge — created once, re-attached on every recreation.
        if (ytdlpBridge == null) ytdlpBridge = YtdlpBridge(applicationContext)
        ytdlpBridge!!.attach(flutterEngine)

        val storage = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, storageChannelName)
        // Kept statically so the notification's Cancel button can reach Dart with no
        // Activity alive. It rides the cached engine's messenger, not this Activity.
        storageChannel = storage
        storage.setMethodCallHandler { call, result ->
                try {
                    when (call.method) {
                        "getSdkInt" -> result.success(Build.VERSION.SDK_INT)
                        "saveToDownloads" -> result.success(
                            MediaStoreSaver.saveToDownloads(
                                applicationContext,
                                call.argument<String>("sourcePath")!!,
                                call.argument<String>("fileName")!!,
                                call.argument<String>("subDir") ?: "woofer",
                                call.argument<String>("mimeType") ?: "application/octet-stream",
                            )
                        )
                        "openFile" -> result.success(
                            FileIntents.openFile(
                                this,
                                call.argument<String>("path")!!,
                                call.argument<String>("mimeType") ?: "*/*",
                            )
                        )
                        "shareFile" -> result.success(
                            FileIntents.shareFile(
                                this,
                                call.argument<String>("path")!!,
                                call.argument<String>("mimeType") ?: "*/*",
                            )
                        )
                        "showDownloadNotification" -> result.success(
                            DownloadService.showProgress(
                                applicationContext,
                                call.argument<String>("title") ?: "Downloading",
                                call.argument<String>("text") ?: "",
                                call.argument<Int>("percent") ?: -1,
                            )
                        )
                        "hideDownloadNotification" -> result.success(DownloadService.hide(applicationContext))
                        "showDownloadResult" -> {
                            DownloadService.showResult(
                                applicationContext,
                                call.argument<String>("title") ?: "Download",
                                call.argument<String>("text") ?: "",
                                call.argument<String>("uri"),
                                call.argument<String>("mimeType"),
                            )
                            result.success(true)
                        }
                        else -> result.notImplemented()
                    }
                } catch (e: Exception) {
                    result.error("STORAGE_ERROR", e.message, null)
                }
            }
    }

    override fun onDestroy() {
        // Nothing process-scoped is shut down here: a download in flight runs on
        // the cached engine, and the whole point of the cached engine +
        // DownloadService is that both keep going after this Activity is gone.
        // The process dies with the service, taking the executor with it.
        super.onDestroy()
    }

    companion object {
        private const val ENGINE_ID = "woofer_engine"

        /** Process-scoped yt-dlp bridge, created once, re-attached per Activity. */
        private var ytdlpBridge: YtdlpBridge? = null

        /** See configureFlutterEngine — lets DownloadActionReceiver call into Dart. */
        var storageChannel: MethodChannel? = null
    }
}
