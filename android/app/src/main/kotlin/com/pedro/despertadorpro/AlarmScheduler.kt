package com.pedro.despertadorpro

import android.app.AlarmManager
import android.app.PendingIntent
import android.os.Build
import android.content.Context
import android.content.Intent
import java.util.Calendar

object AlarmScheduler {
    private const val preferencesName = "scheduled_alarms"
    private const val keyPrefix = "alarm_"

    fun sync(context: Context, alarms: List<*>) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        val editor = preferences.edit()
        val incomingIds = mutableSetOf<Int>()

        alarms.forEach { raw ->
            val alarm = raw as? Map<*, *> ?: return@forEach
            val id = (alarm["id"] as? Number)?.toInt() ?: return@forEach
            incomingIds += id
            val enabled = alarm["enabled"] as? Boolean ?: false
            if (enabled) {
                val hour = (alarm["hour"] as? Number)?.toInt() ?: return@forEach
                val minute = (alarm["minute"] as? Number)?.toInt() ?: return@forEach
                val weekdays = (alarm["weekdays"] as? List<*>)
                    ?.mapNotNull { (it as? Number)?.toInt() }
                    ?.filter { it in 1..7 }
                    ?.distinct()
                    ?.sorted()
                    ?: emptyList()
                val appName = alarm["appName"] as? String ?: "aplicativo"
                val packageName = alarm["packageName"] as? String ?: ""
                val tone = alarm["tone"] as? String ?: "Clássico"
                editor.putString(keyPrefix + id, "$hour|$minute|${weekdays.joinToString(",")}|$appName|$packageName|$tone")
                schedule(context, id, hour, minute, weekdays, appName, packageName, tone)
            } else {
                cancel(context, id)
                editor.remove(keyPrefix + id)
            }
        }

        preferences.all.keys
            .filter { it.startsWith(keyPrefix) }
            .mapNotNull { it.removePrefix(keyPrefix).toIntOrNull() }
            .filter { it !in incomingIds }
            .forEach { cancel(context, it); editor.remove(keyPrefix + it) }
        editor.apply()
    }

    fun rescheduleAll(context: Context) {
        val preferences = context.getSharedPreferences(preferencesName, Context.MODE_PRIVATE)
        preferences.all.forEach { (key, value) ->
            if (!key.startsWith(keyPrefix) || value !is String) return@forEach
            val parts = value.split('|')
            if (parts.size != 6) return@forEach
            val id = key.removePrefix(keyPrefix).toIntOrNull() ?: return@forEach
            val hour = parts[0].toIntOrNull() ?: return@forEach
            val minute = parts[1].toIntOrNull() ?: return@forEach
            val weekdays = parts[2].split(',').mapNotNull { it.toIntOrNull() }
            schedule(context, id, hour, minute, weekdays, parts[3], parts[4], parts[5])
        }
    }

    private fun schedule(
        context: Context,
        id: Int,
        hour: Int,
        minute: Int,
        weekdays: List<Int>,
        appName: String,
        packageName: String,
        tone: String,
    ) {
        val alarmManager = context.getSystemService(AlarmManager::class.java)
        val triggerAt = nextTrigger(hour, minute, weekdays)
        val intent = Intent(context, AlarmReceiver::class.java).apply {
            putExtra("alarmId", id)
            putExtra("appName", appName)
            putExtra("appPackage", packageName)
            putExtra("tone", tone)
        }
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S &&
                !alarmManager.canScheduleExactAlarms()
            ) {
                alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            } else {
                alarmManager.setExactAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
            }
        } catch (_: SecurityException) {
            alarmManager.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, triggerAt, pendingIntent)
        }
    }

    private fun cancel(context: Context, id: Int) {
        val intent = Intent(context, AlarmReceiver::class.java)
        val pendingIntent = PendingIntent.getBroadcast(
            context,
            id,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE,
        )
        context.getSystemService(AlarmManager::class.java).cancel(pendingIntent)
        pendingIntent.cancel()
    }

    private fun nextTrigger(hour: Int, minute: Int, weekdays: List<Int>): Long {
        val now = Calendar.getInstance()
        for (offset in 0..7) {
            val candidate = Calendar.getInstance().apply {
                add(Calendar.DAY_OF_YEAR, offset)
                set(Calendar.HOUR_OF_DAY, hour)
                set(Calendar.MINUTE, minute)
                set(Calendar.SECOND, 0)
                set(Calendar.MILLISECOND, 0)
            }
            val day = candidate.get(Calendar.DAY_OF_WEEK).let { if (it == Calendar.SUNDAY) 7 else it - 1 }
            if ((weekdays.isEmpty() || day in weekdays) && candidate.after(now)) return candidate.timeInMillis
        }
        return now.timeInMillis + 60_000
    }
}