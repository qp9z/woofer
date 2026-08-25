package com.example.woofer

import android.content.ContentValues
import android.content.Context
import android.media.MediaScannerConnection
import android.net.Uri
import android.os.Build
import android.os.Environment
import android.provider.MediaStore
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream
import java.io.IOException

/**
 * Copies a finished download into the user's public Downloads folder and
 * returns its {uri, path} map.
 *
 * API 29+ uses MediaStore (scoped storage, no runtime permission needed); the
 * insert→copy→finalize sequence is wrapped in [withFailureCleanup] so a failure
 * after insert removes the pending row rather than leaving a phantom partial
 * file. API <=28 writes the legacy public dir after the Dart side has secured a
 * WRITE_EXTERNAL_STORAGE grant, then tells MediaScanner about the new file.
 */
object MediaStoreSaver {

    fun saveToDownloads(
        context: Context,
        sourcePath: String,
        fileName: String,
        subDir: String,
        mimeType: String,
    ): Map<String, String> {
        val app = context.applicationContext
        val src = File(sourcePath)
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.Q) {
            // API 29+ : scoped storage via MediaStore, no runtime permission needed.
            val resolver = app.contentResolver
            val values = ContentValues().apply {
                put(MediaStore.Downloads.DISPLAY_NAME, fileName)
                put(MediaStore.Downloads.MIME_TYPE, mimeType)
                put(MediaStore.Downloads.RELATIVE_PATH, "${Environment.DIRECTORY_DOWNLOADS}/$subDir")
                put(MediaStore.Downloads.IS_PENDING, 1)
            }
            val uri = resolver.insert(MediaStore.Downloads.EXTERNAL_CONTENT_URI, values)
                ?: throw IOException("MediaStore insert returned null")
            return withFailureCleanup(
                // Once insert succeeds, every later failure must remove the row.
                // Otherwise MediaStore retains an invisible IS_PENDING item and
                // whatever partial bytes were copied before the failure.
                cleanup = {
                    val deleted = resolver.delete(uri, null, null)
                    if (deleted != 1) {
                        throw IOException("Could not remove partial MediaStore item $uri")
                    }
                },
                operation = {
                    resolver.openOutputStream(uri)?.use { out ->
                        FileInputStream(src).use { it.copyTo(out) }
                    } ?: throw IOException("Could not open output stream for $uri")
                    values.clear()
                    values.put(MediaStore.Downloads.IS_PENDING, 0)
                    val updated = resolver.update(uri, values, null, null)
                    if (updated != 1) {
                        throw IOException("Could not finalize MediaStore item $uri")
                    }
                    mapOf(
                        "uri" to uri.toString(),
                        "path" to "${Environment.DIRECTORY_DOWNLOADS}/$subDir/$fileName",
                    )
                },
            )
        } else {
            // API <=28 : legacy public dir (WRITE_EXTERNAL_STORAGE granted on the Dart side).
            @Suppress("DEPRECATION")
            val downloads = Environment.getExternalStoragePublicDirectory(Environment.DIRECTORY_DOWNLOADS)
            val dir = File(downloads, subDir).apply { mkdirs() }
            val dest = File(dir, fileName)
            FileInputStream(src).use { input -> FileOutputStream(dest).use { input.copyTo(it) } }
            MediaScannerConnection.scanFile(
                app, arrayOf(dest.absolutePath), arrayOf(mimeType), null
            )
            return mapOf("uri" to Uri.fromFile(dest).toString(), "path" to dest.absolutePath)
        }
    }
}
