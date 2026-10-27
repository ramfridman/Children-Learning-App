package app.nitznutz.nitznutz

import android.content.Intent

/**
 * Remembers that the app was opened by a tap on a push notification, so that Flutter can ask at once, before Firebase
 * or the database are ready. The push library puts its message id in the extras of the intent the tap starts the
 * app with; nothing else about the message is read.
 */
object PushTap {
    @Volatile
    private var pending = false

    fun mark(intent: Intent?) {
        if (intent?.extras?.containsKey("google.message_id") == true) pending = true
    }

    /** True once for each tap. */
    fun take(): Boolean {
        val was = pending
        pending = false
        return was
    }
}
