package com.example.woofer

import android.content.Context
import android.net.ConnectivityManager
import android.os.Handler
import android.os.Looper
import com.chaquo.python.PyObject
import com.chaquo.python.Python
import com.chaquo.python.android.AndroidPlatform
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors

/**
 * Owns the "ytdlp" MethodChannel: it hands `extract_info` / `download` calls to
 * the Python bridge (Chaquopy) and relays progress back to Dart as `onProgress`.
 *
 * Long-lived by design. The bridge rides the process-scoped (cached) Flutter
 * engine, so it must not be tied to any single [MainActivity]. It is created
 * once per process in [MainActivity.configureFlutterEngine] and re-attached to
 * the cached engine on every Activity recreation — Python stays started, and
 * re-setting the handler is idempotent.
 *
 * The blocking Python calls run on the process-scoped [ioExecutor]. The
 * executor is deliberately process-scoped too: a per-Activity executor would
 * leak a thread every time the Activity was recreated with the engine still
 * alive. It is never shut down — the process dies with the foreground service,
 * which takes the executor with it.
 */
class YtdlpBridge(private val appContext: Context) {

    private var ytdlpChannel: MethodChannel? = null

    /** Marshals results/progress back onto the Flutter platform thread. */
    private val uiHandler = Handler(Looper.getMainLooper())

    /** (Re)bind this bridge to [flutterEngine]. Safe to call more than once. */
    fun attach(flutterEngine: FlutterEngine) {
        if (!Python.isStarted()) {
            // applicationContext, not an Activity: Python outlives any one of them.
            Python.start(AndroidPlatform(appContext))
        }
        val channel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL)
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
                    val dir = call.argument<String>("dir") ?: appContext.cacheDir.absolutePath
                    runOnIo(result) {
                        bridge().callAttr("download", url, formatId, dir, ProgressBridge()).toString()
                    }
                }
                "cancel_download" -> {
                    // Deliberately NOT on ioExecutor: that thread is blocked inside
                    // the very download we're trying to stop, so anything queued behind it
                    // would only run once the download had already finished.
                    Thread {
                        try {
                            bridge().callAttr("request_cancel")
                        } catch (e: Throwable) {
                            // Nothing running, or Python not up yet — nothing to cancel.
                        }
                    }.start()
                    result.success(true)
                }
                "rebind_network" -> {
                    bindProcessToActiveNetwork()
                    result.success(true)
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
        val cm = appContext.getSystemService(ConnectivityManager::class.java) ?: return
        cm.activeNetwork?.let { cm.bindProcessToNetwork(it) }
    }

    /** Run [work] on the IO thread; deliver its JSON string (or a valid JSON
     *  error envelope for an unexpected native failure) back on the platform
     *  thread, as Flutter requires. */
    private fun runOnIo(result: MethodChannel.Result, work: () -> String) {
        ioExecutor.execute {
            val json = try {
                work()
            } catch (e: Throwable) {
                errorEnvelope(e)
            }
            uiHandler.post { result.success(json) }
        }
    }

    /** Build a valid JSON error envelope. A raw message can carry quotes,
     *  newlines and backslashes that would otherwise break the envelope, so it
     *  is serialized — never hand-assembled with string replaces. */
    private fun errorEnvelope(e: Throwable): String = JSONObject()
        .put("ok", false)
        .put("code", "UNKNOWN")
        .put("message", e.message ?: e.toString())
        .toString()

    /** Passed to Python; yt-dlp's progress hook calls [onProgress], which we
     *  relay to Dart as an `onProgress` call on the same channel. */
    inner class ProgressBridge {
        fun onProgress(received: Long, total: Long) {
            uiHandler.post {
                ytdlpChannel?.invokeMethod(
                    "onProgress",
                    mapOf("received" to received, "total" to total),
                )
            }
        }
    }

    companion object {
        private const val CHANNEL = "ytdlp"

        /** Process-scoped single thread for blocking Python calls. Never shut
         *  down here: the process is torn down with the foreground service. */
        private val ioExecutor: ExecutorService = Executors.newSingleThreadExecutor()
    }
}