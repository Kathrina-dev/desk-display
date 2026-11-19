package com.kathrina.deskstand.desk_display

import android.os.Bundle
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.android.FlutterActivity
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
	private val channelName = "com.kathrina.deskstand/lock"

	override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName).setMethodCallHandler { call, result ->
			when (call.method) {
				"startLock" -> {
					startLockTask()
					result.success(null)
				}
				"stopLock" -> {
					stopLockTask()
					finishAndRemoveTask()
					result.success(null)
				}
				else -> result.notImplemented()
			}
		}
	}
}
