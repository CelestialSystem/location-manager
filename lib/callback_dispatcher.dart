import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'location_manager.dart';

@pragma('vm:entry-point')
void callbackDispatcher() {
  const MethodChannel _backgroundChannel =
      const MethodChannel(Constants.BACKGROUND_CHANNEL_ID);
  WidgetsFlutterBinding.ensureInitialized();

  _backgroundChannel.setMethodCallHandler((MethodCall call) async {
    if (call.method == Constants.ARG_GEOFENCE_EVENT_CALLBACK) {
      final Map<dynamic, dynamic> args = call.arguments;
      final Function geoFenceEventCallback =
          PluginUtilities.getCallbackFromHandle(CallbackHandle.fromRawHandle(
              args[Constants.ARG_GEOFENCE_EVENT_CALLBACK]));
      final Location location = Location.fromJson(args[Constants.ARG_LOCATION]);
      GeoFenceEvent event = GeoFenceEvent.exit;
      if (args["geoFenceEvent"] == "ENTERED") {
        event = GeoFenceEvent.enter;
      } else if (args["geoFenceEvent"] == "EXITED") {
        event = GeoFenceEvent.exit;
      } else if (args["geoFenceEvent"] == "UNKNOWN") {
        event = GeoFenceEvent.unknown;
      } else {
        event = GeoFenceEvent.unknown;
      }
      var ids = args["geofenceIds"].cast<String>();
      geoFenceEventCallback(ids, event, location);
    }
    if (call.method == Constants.ARG_LOCATION_UPDATE_CALLBACK) {
      final Map<dynamic, dynamic> args = call.arguments;
      final Function locationUpdateCallback =
          PluginUtilities.getCallbackFromHandle(CallbackHandle.fromRawHandle(
              args[Constants.ARG_LOCATION_UPDATE_CALLBACK]));

      final Location location = Location.fromJson(args[Constants.ARG_LOCATION]);
      locationUpdateCallback(location);
    }
  });
  _backgroundChannel.invokeMethod(Constants.METHOD_SERVICE_INITIALIZED);
}
