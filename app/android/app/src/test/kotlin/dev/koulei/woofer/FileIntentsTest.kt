package dev.koulei.woofer

import android.app.Activity
import android.content.ContentProvider
import android.content.ContentValues
import android.content.Intent
import android.database.Cursor
import android.net.Uri
import androidx.core.content.FileProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import java.io.File

/**
 * [FileIntents] is what the Library tab's open/share actions end up calling, so
 * these pin the behaviours that matter: a saved file reaches other apps through a
 * content:// URI with a read grant (never a raw file path), and a MediaStore row
 * the user has since deleted fails cleanly instead of launching a viewer onto a
 * dead URI.
 */
@RunWith(RobolectricTestRunner::class)
// SDK 34, not 35: Robolectric runs SDK 35 only on Java 21+, and CI builds on JDK 17.
@Config(sdk = [34])
class FileIntentsTest {

    /** Stands in for MediaStore: serves a row whose real type is video/mp4. */
    class VideoTypeProvider : ContentProvider() {
        override fun onCreate() = true
        override fun getType(uri: Uri): String = "video/mp4"
        override fun query(u: Uri, p: Array<String>?, s: String?, a: Array<String>?, o: String?): Cursor? = null
        override fun insert(uri: Uri, values: ContentValues?): Uri? = null
        override fun delete(uri: Uri, s: String?, a: Array<String>?) = 0
        override fun update(uri: Uri, v: ContentValues?, s: String?, a: Array<String>?) = 0
    }

    private lateinit var activity: Activity
    private val served = Uri.parse("content://woofer.test.media/downloads/7")

    @Before
    fun setUp() {
        activity = Robolectric.buildActivity(Activity::class.java).create().get()
        Robolectric.setupContentProvider(VideoTypeProvider::class.java, "woofer.test.media")
        // FileProvider caches its roots per authority in a static map for the life
        // of the JVM. Robolectric gives every test a fresh temp data dir but keeps
        // the classloader, so without this the second file test looks up the first
        // test's cache dir ("Failed to find configured root"). On a device the dirs
        // never move, so this is a test-only concern.
        FileProvider::class.java.getDeclaredField("sCache").apply { isAccessible = true }
            .let { (it.get(null) as MutableMap<*, *>).clear() }
    }

    // --- content:// (what history stores on API 29+). Host-independent. ----------

    @Test
    fun `a deleted MediaStore row fails instead of launching a viewer`() {
        // Nothing serves this URI, so its type can't be resolved — exactly what a
        // MediaStore row looks like after the user deletes the file.
        val opened = FileIntents.openFile(activity, "content://media/external/downloads/404", "video/mp4")

        assertFalse(opened)
        assertNull(shadowOf(activity).nextStartedActivity)
    }

    @Test
    fun `a live row is opened with its real type and a read grant`() {
        val opened = FileIntents.openFile(activity, served.toString(), "*/*")

        assertTrue(opened)
        val intent = shadowOf(activity).nextStartedActivity
        assertEquals(Intent.ACTION_VIEW, intent.action)
        assertEquals(served, intent.data)
        // The caller's "*/*" must not win: players only match a concrete type.
        assertEquals("video/mp4", intent.type)
        assertTrue(intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
    }

    @Test
    fun `sharing a live row launches a chooser carrying it as EXTRA_STREAM`() {
        val shared = FileIntents.shareFile(activity, served.toString(), "*/*")

        assertTrue(shared)
        val chooser = shadowOf(activity).nextStartedActivity
        assertEquals(Intent.ACTION_CHOOSER, chooser.action)
        val send = chooser.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
        assertNotNull(send)
        assertEquals(Intent.ACTION_SEND, send!!.action)
        assertEquals("video/mp4", send.type)
        assertEquals(served, send.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java))
        assertTrue(send.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
    }

    // --- plain file paths (legacy API <= 28 history rows): wrapped by FileProvider.
    //
    // androidx FileProvider matches a file to its configured root with a literal
    // '/' (FileProvider$SimplePathStrategy.belongsToRoot), and a JVM on Windows
    // hands it '\' paths, so it can never match there. These therefore only run on
    // a POSIX host (the Linux CI job); on Windows they are skipped, not faked.

    private fun cacheFile(): File {
        assumeTrue("FileProvider needs POSIX path separators", File.separatorChar == '/')
        // The cache dir is one of the roots in res/xml/provider_paths.xml.
        return File(activity.cacheDir, "clip.mp4").apply { writeText("x") }
    }

    @Test
    fun `a file path is opened through the FileProvider with a read grant`() {
        val file = cacheFile()
        try {
            assertTrue(FileIntents.openFile(activity, file.absolutePath, "*/*"))

            val intent = shadowOf(activity).nextStartedActivity
            assertEquals(Intent.ACTION_VIEW, intent.action)
            assertEquals("content", intent.data?.scheme)
            assertEquals("${activity.packageName}.fileprovider", intent.data?.authority)
            assertNotEquals("*/*", intent.type)
            assertTrue(intent.flags and Intent.FLAG_GRANT_READ_URI_PERMISSION != 0)
        } finally {
            file.delete()
        }
    }

    @Test
    fun `a file uri is wrapped like a plain path`() {
        val file = cacheFile()
        try {
            assertTrue(FileIntents.openFile(activity, "file://${file.absolutePath}", "*/*"))
            assertEquals("content", shadowOf(activity).nextStartedActivity.data?.scheme)
        } finally {
            file.delete()
        }
    }

    @Test
    fun `sharing a file path carries a content uri as EXTRA_STREAM`() {
        val file = cacheFile()
        try {
            assertTrue(FileIntents.shareFile(activity, file.absolutePath, "*/*"))

            val chooser = shadowOf(activity).nextStartedActivity
            val send = chooser.getParcelableExtra(Intent.EXTRA_INTENT, Intent::class.java)
            assertEquals(
                "content",
                send!!.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)?.scheme,
            )
        } finally {
            file.delete()
        }
    }
}
