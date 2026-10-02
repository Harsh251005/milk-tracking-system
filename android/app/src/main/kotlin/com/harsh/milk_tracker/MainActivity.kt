package com.harsh.milk_tracker

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // Lets the app share its own installed APK ("Share Milk Tracker"),
        // so first installs don't depend on a browser download.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "milk_tracker/app")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "installedApkPath" -> result.success(applicationInfo.sourceDir)
                    else -> result.notImplemented()
                }
            }
    }
}
