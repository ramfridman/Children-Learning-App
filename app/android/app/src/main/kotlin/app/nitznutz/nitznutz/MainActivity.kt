package app.nitznutz.nitznutz

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        val messenger = flutterEngine.dartExecutor.binaryMessenger
        MethodChannel(messenger, DeviceKeyChannel.NAME).setMethodCallHandler(DeviceKeyChannel())
        MethodChannel(messenger, PlatformChannel.NAME).setMethodCallHandler(PlatformChannel(this))
    }
}
