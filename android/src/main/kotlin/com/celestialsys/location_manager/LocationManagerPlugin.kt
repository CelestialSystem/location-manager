package com.celestialsys.location_manager

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.util.Log
import com.google.android.gms.location.*
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.plugin.common.PluginRegistry.Registrar

class LocationManagerPlugin(private val context: Context) : MethodCallHandler {

    private var fusedLocationProviderClient: FusedLocationProviderClient? = null

    private var geofencingClient: GeofencingClient? = null

    companion object {
        const val TAG = "LocationManagerPlugin"

        private const val UPDATE_INTERVAL = (5 * 1000).toLong()
        private const val FASTEST_UPDATE_INTERVAL = UPDATE_INTERVAL / 2
        private const val MAX_WAIT_TIME = UPDATE_INTERVAL * 3

        @JvmStatic
        fun registerWith(registrar: Registrar) {
            val channel = MethodChannel(registrar.messenger(), FOREGROUND_CHANNEL_ID)
            channel.setMethodCallHandler(LocationManagerPlugin(context = registrar.activeContext()))
        }
    }

    private fun getLocationUpdatePendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, LocationUpdatesBroadcastReceiver::class.java)
        intent.action = ACTION_LOCATION_UPDATE
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }

    private fun getLocationRequest(): LocationRequest {
        val mLocationRequest = LocationRequest()
        mLocationRequest.interval = UPDATE_INTERVAL
        mLocationRequest.fastestInterval = FASTEST_UPDATE_INTERVAL
        mLocationRequest.priority = LocationRequest.PRIORITY_HIGH_ACCURACY
        mLocationRequest.maxWaitTime = MAX_WAIT_TIME
        return mLocationRequest
    }


    private fun getGeoFenceEventPendingIntent(context: Context): PendingIntent {
        val intent = Intent(context, LocationUpdatesBroadcastReceiver::class.java)
        intent.action = ACTION_GEOFENCE_EVENT
        return PendingIntent.getBroadcast(context, 0, intent, PendingIntent.FLAG_UPDATE_CURRENT)
    }


    private fun getGeofencingRequest(geofences: List<Geofence>): GeofencingRequest {
        val builder = GeofencingRequest.Builder()
        builder.setInitialTrigger(GeofencingRequest.INITIAL_TRIGGER_ENTER)
        builder.addGeofences(geofences)
        return builder.build()
    }

    private fun initialize(context: Context) {
        try {
            fusedLocationProviderClient = LocationServices.getFusedLocationProviderClient(context)
        } catch (e: SecurityException) {
            Log.e(TAG, "Some Error while initializing location manager (initialize)", e)
        }
        try {
            geofencingClient = LocationServices.getGeofencingClient(context)
        } catch (e: SecurityException) {
            Log.e(TAG, "Some Error while initializing Geofencing Client (initialize)", e)
        }
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        Log.e(TAG, "Method Called: ${call.method} Arguments: ${call.arguments<Map<Any, Any>>()}")
        when (call.method) {
            METHOD_PLUGIN_INITIALIZE -> {
                initialize(context)
                val args: Map<Any, Any> = call.arguments()
                setCallbackDispatcherHandle(context, args[ARG_CALLBACK_DISPATCHER] as Long)
                return result.success(null)
            }

            METHOD_PLUGIN_START_LOCATION_TRACKING -> {
                try {
                    fusedLocationProviderClient?.requestLocationUpdates(getLocationRequest(), getLocationUpdatePendingIntent(context))
                    setRequesting(context, true)
                } catch (e: SecurityException) {
                    setRequesting(context, false)
                    Log.e(TAG, "Some Error while requesting location update (requestLocationUpdates)", e)
                }
                return result.success(null)
            }

            METHOD_PLUGIN_STOP_LOCATION_TRACKING -> {
                try {
                    fusedLocationProviderClient?.removeLocationUpdates(getLocationUpdatePendingIntent(context))
                    setRequesting(context, true)
                } catch (e: SecurityException) {
                    setRequesting(context, false)
                    Log.e(TAG, "Some Error while removing location update (removeLocationUpdates)", e)
                }
                return result.success(null)
            }

            METHOD_PLUGIN_GET_LAST_LOCATION -> {
            }

            METHOD_PLUGIN_GET_CURRENT_LOCATION -> {
            }

            METHOD_PLUGIN_CREATE_GEOFENCE -> {
                val args: Map<Any, List<Map<Any, Any>>> = call.arguments()
                val geofences = args["geofences"]?.map {
                    Geofence.Builder()
                            .setRequestId(it[ARG_GEOFENCE_ID].toString())
                            .setCircularRegion(it[ARG_LATITUDE].toString().toDouble(), it[ARG_LONGITUDE].toString().toDouble(), it[ARG_GEOFENCE_RADIUS].toString().toFloat())
                            .setExpirationDuration(Geofence.NEVER_EXPIRE)
                            .setTransitionTypes(Geofence.GEOFENCE_TRANSITION_ENTER or Geofence.GEOFENCE_TRANSITION_EXIT)
                            .build()
                }
                geofences?.let {
                    geofencingClient?.addGeofences(getGeofencingRequest(geofences), getGeoFenceEventPendingIntent(context))?.run {
                        addOnSuccessListener {
                            args["geofences"]?.map { it.toString() }?.let {
                                setGeofenceIds(context, it)
                            }
                            Log.w(TAG, "Geofences Successfully Added")
                        }
                        addOnFailureListener {
                            Log.e(TAG, "Error while Adding Geofences", it)
                        }
                    }
                }
                return result.success(null)
            }

            METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID -> {
                val args: Map<Any, List<Any>> = call.arguments()
                val geofenceIds = args["geofence_ids"]?.map { it.toString() }?.toMutableList()
                geofenceIds?.let { ids ->
                    geofencingClient?.removeGeofences(ids)?.run {
                        addOnSuccessListener {
                            Log.w(TAG, "Geofences $ids Successfully Removed")
                        }
                        addOnFailureListener {
                            Log.e(TAG, "Error while removing Geofences $ids ", it)
                        }
                    }
                }
                return result.success(null)
            }
            METHOD_PLUGIN_GET_ACTIVE_GEOFENCE -> {
                return result.success(getGeofenceIds(context))
            }

            METHOD_PLUGIN_REMOVE_ALL_GEOFENCE -> {
                geofencingClient?.removeGeofences(getGeoFenceEventPendingIntent(context))?.run {
                    addOnSuccessListener {
                        setGeofenceIds(context, mutableListOf())
                        Log.w(TAG, "All Geofences Successfully Removed")
                    }
                    addOnFailureListener {
                        Log.e(TAG, "Error while removing All Geofences", it)
                    }
                }
                return result.success(null)
            }

            METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT -> {
                val args: Map<Any, Any> = call.arguments()
                setGeoFenceEventHandle(context, args[ARG_GEOFENCE_EVENT] as Long)
                return result.success(null)
            }

            METHOD_PLUGIN_MONITOR_LOCATION_UPDATE -> {
                val args: Map<Any, Any> = call.arguments()
                setLocationUpdateHandle(context, args[ARG_LOCATION_UPDATE] as Long)
                return result.success(null)
            }

            else -> result.notImplemented()
        }
    }
}
