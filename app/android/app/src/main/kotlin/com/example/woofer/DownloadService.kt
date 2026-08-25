package com.example.woofer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat

/**
 * Holds the process at foreground priority for the length of a download, and owns
 * every notification WOOFER posts.
 *
 * It runs no download logic itself — the pipeline stays in Dart, which also writes
 * the copy (so the notification says exactly what the Downloading/Processing
 * screens say). This side owns the chrome: the brand mark, the accent tint, the
 * progress bar, and the taps.
 *
 * Two channels on purpose. Progress is an ongoing, silent, unswipeable
 * notification tied to the service's lifetime; the outcome is a separate,
 * dismissible one that has to outlive the service — stopping the service tears
 * down its own notification, so a result posted on it would vanish instantly.
 */
class DownloadService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    /** Called both to start and to update — re-issuing startForeground refreshes it. */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Downloading"
        val text = intent?.getStringExtra(EXTRA_TEXT).orEmpty()
        val percent = intent?.getIntExtra(EXTRA_PERCENT, -1) ?: -1
        startForeground(PROGRESS_ID, progressNotification(title, text, percent))
        // Never auto-restart: the Dart side owns the download, and a service that
        // came back without it would sit there notifying a download that is gone.
        return START_NOT_STICKY
    }

    private fun progressNotification(title: String, text: String, percent: Int): Notification {
        ensureChannels()
        val indeterminate = percent < 0
        return baseBuilder(CHANNEL_PROGRESS)
            .setContentTitle(title)
            .setContentText(text)
            .setContentIntent(openAppIntent())
            .setProgress(100, if (indeterminate) 0 else percent, indeterminate)
            .setOngoing(true) // can't be swiped away while it's actually running
            .setOnlyAlertOnce(true)
            .setSilent(true)
            .setCategory(NotificationCompat.CATEGORY_PROGRESS)
            .addAction(
                NotificationCompat.Action.Builder(
                    android.R.drawable.ic_menu_close_clear_cancel,
                    "Cancel",
                    broadcast(ACTION_CANCEL, REQUEST_CANCEL),
                ).build()
            )
            .build()
    }

    private fun ensureChannels() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_PROGRESS) == null) {
            manager.createNotificationChannel(
                // LOW: an ongoing progress bar must never buzz the phone.
                NotificationChannel(CHANNEL_PROGRESS, "Downloads", NotificationManager.IMPORTANCE_LOW)
                    .apply { description = "Progress while a download is running." }
            )
        }
        if (manager.getNotificationChannel(CHANNEL_RESULT) == null) {
            manager.createNotificationChannel(
                // DEFAULT: finishing (or failing) is worth one quiet heads-up.
                NotificationChannel(CHANNEL_RESULT, "Finished downloads", NotificationManager.IMPORTANCE_DEFAULT)
                    .apply { description = "When a download finishes or fails." }
            )
        }
    }

    private fun baseBuilder(channel: String) =
        NotificationCompat.Builder(this, channel)
            .setSmallIcon(R.drawable.ic_stat_woofer)
            .setColor(ContextCompat.getColor(this, R.color.brand_accent))
            .setColorized(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)

    private fun openAppIntent(): PendingIntent = PendingIntent.getActivity(
        this,
        REQUEST_OPEN_APP,
        Intent(this, MainActivity::class.java)
            .setAction(Intent.ACTION_MAIN)
            .addCategory(Intent.CATEGORY_LAUNCHER)
            .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
        PendingIntent.FLAG_IMMUTABLE,
    )

    private fun broadcast(action: String, requestCode: Int): PendingIntent = PendingIntent.getBroadcast(
        this,
        requestCode,
        Intent(this, DownloadActionReceiver::class.java).setAction(action).setPackage(packageName),
        PendingIntent.FLAG_IMMUTABLE,
    )

    companion object {
        const val CHANNEL_PROGRESS = "woofer_downloads"
        const val CHANNEL_RESULT = "woofer_download_results"
        const val PROGRESS_ID = 1
        const val RESULT_ID = 2

        const val EXTRA_TITLE = "title"
        const val EXTRA_TEXT = "text"
        const val EXTRA_PERCENT = "percent"

        const val ACTION_CANCEL = "com.example.woofer.CANCEL_DOWNLOAD"

        private const val REQUEST_OPEN_APP = 10
        private const val REQUEST_CANCEL = 11
        private const val REQUEST_OPEN_FILE = 12

        /** Start — or refresh — the foreground service with an updated progress
         *  notification. The service lives for the whole download. */
        fun showProgress(context: Context, title: String, text: String, percent: Int) {
            val app = context.applicationContext
            val intent = Intent(app, DownloadService::class.java)
                .putExtra(EXTRA_TITLE, title)
                .putExtra(EXTRA_TEXT, text)
                .putExtra(EXTRA_PERCENT, percent)
            ContextCompat.startForegroundService(app, intent)
        }

        /** Stop the foreground service, which tears down its progress notification. */
        fun hide(context: Context) {
            context.applicationContext.stopService(
                Intent(context.applicationContext, DownloadService::class.java)
            )
        }

        /**
         * Post the outcome. [uri]/[mimeType] non-null makes tapping it open the saved
         * file; otherwise the tap just brings WOOFER back up (what a failure wants).
         * Posted straight through NotificationManager so it survives the service
         * stopping, which is what removes the progress notification.
         */
        fun showResult(
            context: Context,
            title: String,
            text: String,
            uri: String?,
            mimeType: String?,
        ) {
            val app = context.applicationContext
            val open = if (uri != null) {
                PendingIntent.getActivity(
                    app,
                    REQUEST_OPEN_FILE,
                    Intent(Intent.ACTION_VIEW)
                        .setDataAndType(Uri.parse(uri), mimeType ?: "*/*")
                        .addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK),
                    PendingIntent.FLAG_IMMUTABLE,
                )
            } else {
                PendingIntent.getActivity(
                    app,
                    REQUEST_OPEN_APP,
                    Intent(app, MainActivity::class.java)
                        .setAction(Intent.ACTION_MAIN)
                        .addCategory(Intent.CATEGORY_LAUNCHER)
                        .addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP),
                    PendingIntent.FLAG_IMMUTABLE,
                )
            }
            val notification = NotificationCompat.Builder(app, CHANNEL_RESULT)
                .setSmallIcon(R.drawable.ic_stat_woofer)
                .setColor(ContextCompat.getColor(app, R.color.brand_accent))
                .setContentTitle(title)
                .setContentText(text)
                // Titles run long; let the shade expand rather than ellipsize.
                .setStyle(NotificationCompat.BigTextStyle().bigText(text))
                .setContentIntent(open)
                .setAutoCancel(true)
                .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
                .build()
            try {
                NotificationManagerCompat.from(app).notify(RESULT_ID, notification)
            } catch (e: SecurityException) {
                // POST_NOTIFICATIONS denied — the download still completed; the UI says so.
            }
        }
    }
}

/** Routes the notification's Cancel button back into the Dart controller. */
class DownloadActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if (intent.action != DownloadService.ACTION_CANCEL) return
        // onReceive is already on the main thread, which is where a MethodChannel
        // has to be invoked from. The channel rides the cached engine, so this
        // still works with no Activity around.
        MainActivity.storageChannel?.invokeMethod("cancelDownload", null)
    }
}
