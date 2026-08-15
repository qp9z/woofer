package com.example.woofer

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Test

class FailureCleanupTest {
    @Test
    fun `successful operation keeps the created item`() {
        var cleaned = false

        val result = withFailureCleanup(
            cleanup = { cleaned = true },
            operation = { "saved" },
        )

        assertEquals("saved", result)
        assertFalse(cleaned)
    }

    @Test
    fun `failed operation removes the partial item and keeps the original error`() {
        var cleaned = false
        val copyFailure = IllegalStateException("copy failed")

        val thrown = try {
            withFailureCleanup(
                cleanup = { cleaned = true },
                operation = { throw copyFailure },
            )
            error("operation should have failed")
        } catch (failure: IllegalStateException) {
            failure
        }

        assertTrue(cleaned)
        assertSame(copyFailure, thrown)
    }

    @Test
    fun `cleanup error is suppressed behind the original save failure`() {
        val saveFailure = IllegalStateException("finalize failed")
        val cleanupFailure = IllegalStateException("delete failed")

        val thrown = try {
            withFailureCleanup(
                cleanup = { throw cleanupFailure },
                operation = { throw saveFailure },
            )
            error("operation should have failed")
        } catch (failure: IllegalStateException) {
            failure
        }

        assertSame(saveFailure, thrown)
        assertEquals(listOf(cleanupFailure), thrown.suppressed.toList())
    }
}
