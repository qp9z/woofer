package com.example.woofer

/**
 * Run [operation], invoking [cleanup] only if it fails. Cleanup failure is kept
 * as a suppressed exception so the original copy/finalization error remains the
 * one reported to Flutter.
 */
internal inline fun <T> withFailureCleanup(
    cleanup: () -> Unit,
    operation: () -> T,
): T = try {
    operation()
} catch (failure: Throwable) {
    try {
        cleanup()
    } catch (cleanupFailure: Throwable) {
        failure.addSuppressed(cleanupFailure)
    }
    throw failure
}
