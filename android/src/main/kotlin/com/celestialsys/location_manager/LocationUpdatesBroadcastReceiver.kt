package com.celestialsys.location_manager

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent

import io.flutter.view.FlutterMain

class LocationUpdatesBroadcastReceiver : BroadcastReceiver() {

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent != null) {
            FlutterMain.ensureInitializationComplete(context, null)
            if (ACTION_LOCATION_UPDATE == intent.action) {
                LocationUpdatesIntentService.enqueueWork(context, intent)
            }
            if (ACTION_GEOFENCE_EVENT == intent.action) {
                LocationUpdatesIntentService.enqueueWork(context, intent)
            }
        }
    }
}

