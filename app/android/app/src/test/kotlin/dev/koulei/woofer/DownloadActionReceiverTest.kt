package dev.koulei.woofer

import android.content.Context
import android.content.Intent
import androidx.test.core.app.ApplicationProvider
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config
import java.nio.ByteBuffer

/**
 * The notification's Cancel button is the only way to stop a download once the
 * app has been swiped away, and it works by reaching Dart over the cached
 * engine's "woofer/storage" channel with no Activity alive. These pin that route.
 */
@RunWith(RobolectricTestRunner::class)
// SDK 34, not 35: Robolectric runs SDK 35 only on Java 21+, and CI builds on JDK 17.
@Config(sdk = [34])
class DownloadActionReceiverTest {

    /** Records every method call a channel sends, decoded the way Dart would. */
    private class RecordingMessenger : BinaryMessenger {
        val methods = mutableListOf<String>()

        override fun send(channel: String, message: ByteBuffer?) = send(channel, message, null)

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {
            message?.let {
                it.rewind() // the codec leaves the position at the end
                methods += StandardMethodCodec.INSTANCE.decodeMethodCall(it).method
            }
        }

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) = Unit
    }

    private lateinit var context: Context
    private lateinit var messenger: RecordingMessenger

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        messenger = RecordingMessenger()
        MainActivity.storageChannel = MethodChannel(messenger, "woofer/storage")
    }

    @After
    fun tearDown() {
        MainActivity.storageChannel = null
    }

    @Test
    fun `the cancel action reaches Dart as cancelDownload`() {
        DownloadActionReceiver().onReceive(context, Intent(DownloadService.ACTION_CANCEL))

        assertEquals(listOf("cancelDownload"), messenger.methods)
    }

    @Test
    fun `any other action is ignored`() {
        DownloadActionReceiver().onReceive(context, Intent("dev.koulei.woofer.SOMETHING_ELSE"))

        assertTrue(messenger.methods.isEmpty())
    }

    @Test
    fun `cancel with no engine attached is a harmless no-op`() {
        MainActivity.storageChannel = null

        DownloadActionReceiver().onReceive(context, Intent(DownloadService.ACTION_CANCEL))

        assertTrue(messenger.methods.isEmpty())
    }
}
