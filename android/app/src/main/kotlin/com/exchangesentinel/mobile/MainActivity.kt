package com.exchangesentinel.mobile

import android.content.Intent
import android.os.Build
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val channel = "exchange_sentinel/alarm"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, channel).setMethodCallHandler { call, result ->
            when (call.method) {
                "start" -> {
                    val intent = Intent(this, UrgentAlarmService::class.java).apply {
                        putExtra("title", call.argument<String>("title") ?: "Deal needs attention")
                        putExtra("body", call.argument<String>("body") ?: "Open Exchange Sentinel")
                    }
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) startForegroundService(intent) else startService(intent)
                    result.success(true)
                }
                "stop" -> { stopService(Intent(this, UrgentAlarmService::class.java)); result.success(true) }
                else -> result.notImplemented()
            }
        }
    }
}
