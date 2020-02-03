@file:Suppress("DEPRECATION")

package com.celestialsys.location_manager

import android.content.Context
import android.location.Location
import android.preference.PreferenceManager

var LAST_LOCATION : Location ? = null
const val CALLBACK_DISPATCHER_HANDLE_KEY = "pluginCallDispatcherHandleKey"
const val LOCATION_UPDATE_HANDLE_KEY = "pluginLocationUpdateHandleKey"
const val GEOFENCE_EVENT_HANDLE_KEY = "pluginGeofenceEventHandleKey"

const val METHOD_SERVICE_INITIALIZED = "LocationManagerPlugin.initialize";

const val METHOD_PLUGIN_INITIALIZE = "LocationManager.initialize"
const val METHOD_PLUGIN_START_LOCATION_TRACKING =
        "LocationManager.startLocationTracking"
const val METHOD_PLUGIN_STOP_LOCATION_TRACKING =
        "LocationManager.stopLocationTracking"
const val METHOD_PLUGIN_GET_LAST_LOCATION =
        "LocationManager.getLastLocation"
const val METHOD_PLUGIN_GET_CURRENT_LOCATION =
        "LocationManager.getCurrentLocation"
const val METHOD_PLUGIN_CREATE_GEOFENCE =
        "LocationManager.createGeoFence"
const val METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID =
        "LocationManager.removeGeoFenceUsingId"
const val METHOD_PLUGIN_REMOVE_GEOFENCE =
        "LocationManager.removeGeoFence"
const val METHOD_PLUGIN_GET_ACTIVE_GEOFENCE =
        "LocationManager.getActiveGeoFence"
const val METHOD_PLUGIN_REMOVE_ALL_GEOFENCE =
        "LocatorService.removeAllGeoFence"
const val METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT =
        "LocationManager.monitorGeoFenceEvents"
const val METHOD_PLUGIN_MONITOR_LOCATION_UPDATE =
        "LocationManager.monitorLocationUpdates"


const val ARG_LATITUDE = "latitude"
const val ARG_LONGITUDE = "longitude"
const val ARG_ACCURACY = "accuracy"
const val ARG_ALTITUDE = "altitude"
const val ARG_SPEED = "speed"
const val ARG_SPEED_ACCURACY = "speed_accuracy"
const val ARG_HEADING = "heading"
const val ARG_LOCATION = "location"

const val ARG_LOCATION_UPDATE = "onLocationChangeArg"

const val ARG_GEOFENCE_ID = "id"
const val ARG_GEOFENCE_RADIUS = "radius"

const val ARG_GEOFENCE_EXP = "expInSec"
const val ARG_SETTINGS = "settings"
const val ARG_INTERVAL = "interval"
const val ARG_DISTANCE_FILTER = "distanceFilter"
const val ARG_LOCATION_PERMISSION_MSG = "requestPermissionMsg"
const val ARG_NOTIFICATION_TITLE = "notificationTitle"
const val ARG_NOTIFICATION_MSG = "notificationMsg"

const val ARG_GEOFENCE_EVENT = "onGeoFenceEventArg"


const val ARG_CALLBACK_DISPATCHER = "callbackDispatcher"

const val FOREGROUND_CHANNEL_ID =
        "plugin/location_manager/foreground_channel"
const val BACKGROUND_CHANNEL_ID =
        "plugin/location_manager/background_channel"

const val KEY_LOCATION_UPDATES_REQUESTED = "location-updates-requested"

const val KEY_GEOFENCE_IDS = "geofenceIdsKey"

const val ACTION_LOCATION_UPDATE = "LocationManager.ACTION_LOCATION_UPDATE"
const val ACTION_GEOFENCE_EVENT = "LocationManager.ACTION_GEOFENCE_EVENT"


fun setCallbackDispatcherHandle(context: Context, handle: Long) {
    PreferenceManager.getDefaultSharedPreferences(context)
            .edit()
            .putLong(CALLBACK_DISPATCHER_HANDLE_KEY, handle)
            .apply()
}

fun getCallbackDispatcherHandle(context: Context): Long {
    return PreferenceManager.getDefaultSharedPreferences(context)
            .getLong(CALLBACK_DISPATCHER_HANDLE_KEY, 0)
}

fun setLocationUpdateHandle(context: Context, handle: Long) {
    PreferenceManager.getDefaultSharedPreferences(context)
            .edit()
            .putLong(LOCATION_UPDATE_HANDLE_KEY, handle)
            .apply()
}

fun getLocationUpdateHandle(context: Context): Long {
    return PreferenceManager.getDefaultSharedPreferences(context)
            .getLong(LOCATION_UPDATE_HANDLE_KEY, 0)
}

fun setGeoFenceEventHandle(context: Context, handle: Long) {
    PreferenceManager.getDefaultSharedPreferences(context)
            .edit()
            .putLong(GEOFENCE_EVENT_HANDLE_KEY, handle)
            .apply()
}

fun getGeoFenceEventHandle(context: Context): Long {
    return PreferenceManager.getDefaultSharedPreferences(context)
            .getLong(GEOFENCE_EVENT_HANDLE_KEY, 0)
}


fun setRequesting(context: Context, value: Boolean) {
    PreferenceManager.getDefaultSharedPreferences(context)
            .edit()
            .putBoolean(KEY_LOCATION_UPDATES_REQUESTED, value)
            .apply()
}

fun getRequesting(context: Context): Boolean {
    return PreferenceManager.getDefaultSharedPreferences(context)
            .getBoolean(KEY_LOCATION_UPDATES_REQUESTED, false)
}


fun setGeofenceIds(context: Context, value: List<String>) {
    PreferenceManager.getDefaultSharedPreferences(context)
            .edit()
            .putStringSet(KEY_GEOFENCE_IDS, value.toMutableSet())
            .apply()
}

fun getGeofenceIds(context: Context): List<String>? {
    return PreferenceManager.getDefaultSharedPreferences(context)
            .getStringSet(KEY_GEOFENCE_IDS, mutableSetOf())?.toList()
}