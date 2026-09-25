package com.pedro.despertadorpro

import android.os.Bundle
import io.flutter.plugin.common.MethodChannel
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
	private val channelName = "com.pedro.despertadorpro/alarms"

	override fun configureFlutterEngine(flutterEngine: io.flutter.embedding.engine.FlutterEngine) {
		super.configureFlutterEngine(flutterEngine)
		MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channelName)
			.setMethodCallHandler { call, result ->
				when (call.method) {
					"syncAlarms" -> {
						val alarms = call.arguments as? List<*> ?: emptyList<Any>()
						AlarmScheduler.sync(this, alarms)
						result.success(null)
					}
					else -> result.notImplemented()
				}
			}
	}
}
