package com.example.woofer

import android.app.Notification
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.app.Service
import android.content.Intent
import android.os.Build
import android.os.IBinder
import androidx.core.app.NotificationCompat

/**
 * Holds the process at foreground priority for the length of a download.
 *
 * It runs no download logic itself — the pipeline stays in Dart. Its only job is
 * to stop Android from reclaiming a backgrounded WOOFER mid-transfer (Samsung's
 * reaper is especially quick), and to keep the process alive after the task is
 * swiped away so the cached FlutterEngine — and the download running on it —
 * survives. The notification isn't decoration: posting one is the price of a
 * foreground service, so it may as well carry the progress.
 */
class DownloadService : Service() {

    override fun onBind(intent: Intent?): IBinder? = null

    /** Called both to start and to update — re-issuing startForeground refreshes it. */
    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        val title = intent?.getStringExtra(EXTRA_TITLE) ?: "Downloading"
        val percent = intent?.getIntExtra(EXTRA_PERCENT, -1) ?: -1
        startForeground(NOTIFICATION_ID, buildNotification(title, percent))
        // Never auto-restart: the Dart side owns the download, and a service that
        // came back without it would sit there notifying a download that is gone.
        return START_NOT_STICKY
    }

    private fun buildNotification(title: String, percent: Int): Notification {
        ensureChannel()
        val open = PendingIntent.getActivity(
            this,
            0,
            Intent(this, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP),
            PendingIntent.FLAG_IMMUTABLE,
        )
        val indeterminate = percent < 0
        return NotificationCompat.Builder(this, CHANNEL_ID)
            .setContentTitle(title)
            .setContentText(if (indeterminate) "Working…" else "$percent%")
            .setSmallIcon(android.R.drawable.stat_sys_download)
            .setContentIntent(open)
            .setOngoing(true)
            .setOnlyAlertOnce(true)
            .setProgress(100, if (indeterminate) 0 else percent, indeterminate)
            .build()
    }

    private fun ensureChannel() {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.O) return
        val manager = getSystemService(NotificationManager::class.java) ?: return
        if (manager.getNotificationChannel(CHANNEL_ID) != null) return
        manager.createNotificationChannel(
            // LOW: an ongoing progress bar shouldn't buzz the phone.
            NotificationChannel(CHANNEL_ID, "Downloads", NotificationManager.IMPORTANCE_LOW)
        )
    }

    companion object {
        const val CHANNEL_ID = "woofer_downloads"
        const val NOTIFICATION_ID = 1
        const val EXTRA_TITLE = "title"
        const val EXTRA_PERCENT = "percent"
    }
}
