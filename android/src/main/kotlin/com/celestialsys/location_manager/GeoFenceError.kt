package com.celestialsys.location_manager

import android.content.Context
import com.google.android.gms.location.GeofenceStatusCodes
import com.google.android.gms.common.api.ApiException


internal object GeofenceErrorMessages {

    fun getErrorString(context: Context, e: Exception): String {
        return if (e is ApiException) {
            getErrorString(context, e.statusCode)
        } else {
            "Unknown GeoFence Error"
        }
    }

    fun getErrorString(context: Context, errorCode: Int): String {
        return when (errorCode) {
            GeofenceStatusCodes.GEOFENCE_NOT_AVAILABLE -> "GeoFence not available"
            GeofenceStatusCodes.GEOFENCE_TOO_MANY_GEOFENCES -> "To many GeoFence Added"
            GeofenceStatusCodes.GEOFENCE_TOO_MANY_PENDING_INTENTS -> "To0 many GeoFence Event Pending"
            else -> "Unknown GeoFence Error"
        }
    }
}
