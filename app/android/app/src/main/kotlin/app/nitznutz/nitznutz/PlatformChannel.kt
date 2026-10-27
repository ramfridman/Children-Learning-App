package app.nitznutz.nitznutz

import android.app.Activity
import android.os.SystemClock
import android.provider.Settings
import android.view.WindowManager
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Small things Flutter cannot do alone:
 *  - `noBackupDir`: the app's folder that Android never backs up or copies to a new phone, where
 *    the encrypted database lives (the key is in the Keystore, so a copied file would be useless
 *    anyway; this is a second layer).
 *  - `elapsedRealtime` and `bootCount`: a clock that setting the date cannot move, so a PIN
 *    lock-out cannot be shortened by changing the time.
 *  - `takeNotificationTap`: true once for each tap on a push notification that started or brought forward the app.
 *  - `setSecure`: while true, the window cannot be screenshotted or shown in the recent-apps
 *    preview. Used on every parent screen.
 */
class PlatformChannel(private val activity: Activity) : MethodChannel.MethodCallHandler {
    companion object {
        const val NAME = "app.nitznutz/platform"
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "noBackupDir" -> result.success(activity.noBackupFilesDir.absolutePath)
            // Time since the phone started, which a change of the clock cannot move, and which boot it is.
            "elapsedRealtime" -> result.success(SystemClock.elapsedRealtime())
            "bootCount" -> result.success(
                Settings.Global.getInt(activity.contentResolver, Settings.Global.BOOT_COUNT, 0),
            )
            "takeNotificationTap" -> result.success(PushTap.take())
            "setSecure" -> {
                val secure = call.argument<Boolean>("secure") == true
                activity.runOnUiThread {
                    if (secure) {
                        activity.window.setFlags(
                            WindowManager.LayoutParams.FLAG_SECURE,
                            WindowManager.LayoutParams.FLAG_SECURE,
                        )
                    } else {
                        activity.window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                    }
                    result.success(null)
                }
            }
            else -> result.notImplemented()
        }
    }
}
