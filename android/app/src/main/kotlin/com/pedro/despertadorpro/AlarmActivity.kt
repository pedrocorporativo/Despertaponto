package com.pedro.despertadorpro

import android.app.Activity
import android.content.Intent
import android.os.Bundle
import android.view.Gravity
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.graphics.Color
import android.view.WindowManager

class AlarmActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        window.addFlags(
            WindowManager.LayoutParams.FLAG_KEEP_SCREEN_ON or
            WindowManager.LayoutParams.FLAG_SHOW_WHEN_LOCKED or
            WindowManager.LayoutParams.FLAG_TURN_SCREEN_ON
        )

        val appName = intent.getStringExtra("appName") ?: "aplicativo"
        val pkg = intent.getStringExtra("appPackage") ?: ""

        val root = LinearLayout(this).apply {
            orientation = LinearLayout.VERTICAL
            gravity = Gravity.CENTER
            setPadding(40, 40, 40, 40)
            setBackgroundColor(Color.rgb(9, 10, 16))
        }

        val title = TextView(this).apply {
            text = "Hora de acordar"
            textSize = 28f
            setTextColor(Color.WHITE)
            gravity = Gravity.CENTER
        }

        val subtitle = TextView(this).apply {
            text = "Desligue o alarme para abrir $appName"
            textSize = 16f
            setTextColor(Color.LTGRAY)
            gravity = Gravity.CENTER
            setPadding(0, 20, 0, 40)
        }

        val stop = Button(this).apply {
            text = "DESLIGAR E ABRIR $appName"
            setOnClickListener {
                if (pkg.isNotBlank()) {
                    try {
                        val launch = packageManager.getLaunchIntentForPackage(pkg)
                        if (launch != null) {
                            launch.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(launch)
                        }
                    } catch (_: Exception) {}
                }
                finish()
            }
        }

        root.addView(title)
        root.addView(subtitle)
        root.addView(stop)
        setContentView(root)
    }
}
