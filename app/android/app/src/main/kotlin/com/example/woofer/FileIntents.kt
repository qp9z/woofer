package com.example.woofer

import android.app.Activity
import android.content.ActivityNotFoundException
import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.core.content.FileProvider
import java.io.File

/**
 * Opens and shares a saved file through an external app via ACTION_VIEW /
 * ACTION_SEND chooser. Stateless — the call site (an Activity) starts the
 * intents, so this stays a thin, focused helper.
 */
object FileIntents {

    fun openFile(activity: Activity, pathOrUri: String, mimeType: String): Boolean {
        val uri = shareableUri(activity, pathOrUri)
        // Players declare video/* or audio/* filters, so ACTION_VIEW with the caller's
        // "*/*" resolves to nothing. MediaStore (content://) and FileProvider (by
        // extension) both know the real type. A null type on a content:// uri means
        // the row is gone — the user deleted the file — so fail instead of launching
        // a player onto a dead uri.
        val type = resolveType(activity, uri)
        if (type == null && pathOrUri.startsWith("content://")) return false
        val intent = Intent(Intent.ACTION_VIEW).apply {
            setDataAndType(uri, type ?: mimeType)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION or Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            activity.startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    fun shareFile(activity: Activity, pathOrUri: String, mimeType: String): Boolean {
        val uri = shareableUri(activity, pathOrUri)
        val intent = Intent(Intent.ACTION_SEND).apply {
            type = resolveType(activity, uri) ?: mimeType
            putExtra(Intent.EXTRA_STREAM, uri)
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        val chooser = Intent.createChooser(intent, "Share").apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return try {
            activity.startActivity(chooser)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }

    /** The concrete MIME type behind [uri], or null if it can't be determined
     *  (unknown extension, or a MediaStore row whose file no longer exists). */
    private fun resolveType(context: Context, uri: Uri): String? =
        try { context.contentResolver.getType(uri) } catch (e: Exception) { null }

    /** content:// stays as-is; a file path/uri is wrapped by FileProvider for sharing. */
    private fun shareableUri(context: Context, pathOrUri: String): Uri {
        if (pathOrUri.startsWith("content://")) return Uri.parse(pathOrUri)
        val path = if (pathOrUri.startsWith("file://")) Uri.parse(pathOrUri).path ?: pathOrUri else pathOrUri
        return FileProvider.getUriForFile(
            context.applicationContext,
            "${context.packageName}.fileprovider",
            File(path),
        )
    }
}
