package com.pedro.despertadorpro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class AlarmReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        val alarmIntent = Intent(context, AlarmActivity::class.java).apply {
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or
                    Intent.FLAG_ACTIVITY_CLEAR_TOP or
                    Intent.FLAG_ACTIVITY_SINGLE_TOP)
            putExtra("appPackage", intent?.getStringExtra("appPackage") ?: "")
            putExtra("appName", intent?.getStringExtra("appName") ?: "aplicativo")
            putExtra("tone", intent?.getStringExtra("tone") ?: "Clássico")
        }
        context.startActivity(alarmIntent)
    }
}
