package com.example.app

import android.os.Build
import android.view.Surface
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "app/scene_camera")
            .setMethodCallHandler { call, result ->
                if (call.method == "displayRotation") {
                    result.success(displayRotationDegrees())
                } else {
                    result.notImplemented()
                }
            }
    }

    @Suppress("DEPRECATION")
    private fun displayRotationDegrees(): Int {
        val rotation = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) {
            display?.rotation
        } else {
            windowManager.defaultDisplay.rotation
        }
        return when (rotation) {
            Surface.ROTATION_90 -> 90
            Surface.ROTATION_180 -> 180
            Surface.ROTATION_270 -> 270
            else -> 0
        }
    }
}
