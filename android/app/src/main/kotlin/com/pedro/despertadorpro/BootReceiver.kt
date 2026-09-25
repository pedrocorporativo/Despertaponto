package com.pedro.despertadorpro

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent?) {
        // Ponto de extensão para reagendar alarmes persistidos após reinicialização.
        // A versão Flutter persiste os alarmes em SharedPreferences.
    }
}
