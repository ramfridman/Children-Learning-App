package app.nitznutz.nitznutz

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        PushTap.mark(intent)
        // The channel a push from the server names. Quiet by default (no sound), so an alert never startles a child nearby.
        val manager = getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(
            NotificationChannel("alerts", getString(R.string.alerts_channel_name), NotificationManager.IMPORTANCE_DEFAULT).apply {
                setSound(null, null)
            },
        )
    }

    // The app was already running and a tap on a notification brought it forward.
    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        PushTap.mark(intent)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, DeviceKeyChannel.NAME).setMethodCallHandler(DeviceKeyChannel())
        MethodChannel(messenger, PlatformChannel.NAME).setMethodCallHandler(PlatformChannel(this))
    }
}
