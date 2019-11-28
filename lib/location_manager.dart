import 'dart:async';
import 'dart:ui';

import 'package:flutter/services.dart';

import 'callback_dispatcher.dart';

class LocationManager {
  static const MethodChannel _foregroundChannel =
      const MethodChannel(Constants.FOREGROUND_CHANNEL_ID);

  static Future initialize() async {
    return _foregroundChannel.invokeMethod(Constants.METHOD_PLUGIN_INITIALIZE, {
      Constants.ARG_CALLBACK_DISPATCHER:
          PluginUtilities.getCallbackHandle(callbackDispatcher).toRawHandle()
    });
  }

  static Future startLocationTracking() async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_START_LOCATION_TRACKING);
  }

  static Future stopLocationTracking() async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_STOP_LOCATION_TRACKING);
  }

  static Future createGeoFence(List<GeoFence> geoFences) async {
    return _foregroundChannel.invokeMethod(
        Constants.METHOD_PLUGIN_CREATE_GEOFENCE,
        {"geofences": geoFences.map((v) => v.toJson()).toList()});
  }

  static Future removeGeoFenceUsingId(List<String> ids) async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID, {"geofence_ids": ids});
  }

  static Future<List<String>> getActiveGeoFence() async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_GET_ACTIVE_GEOFENCE);
  }

  static Future removeAllGeoFence() async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_REMOVE_ALL_GEOFENCE);
  }

  static Future monitorGeoFenceEvents(
      void Function(List<String> ids, GeoFenceEvent, Location) onGeoFenceEvent) async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT, {
      Constants.ARG_GEOFENCE_EVENT_CALLBACK:
          PluginUtilities.getCallbackHandle(onGeoFenceEvent).toRawHandle()
    });
  }

  static Future monitorLocationUpdates(
      void Function(Location) onLocationChange) async {
    return _foregroundChannel
        .invokeMethod(Constants.METHOD_PLUGIN_MONITOR_LOCATION_UPDATE, {
      Constants.ARG_LOCATION_UPDATE_CALLBACK:
          PluginUtilities.getCallbackHandle(onLocationChange).toRawHandle()
    });
  }
}

class Location {
  final double latitude;
  final double longitude;
  final double accuracy;
  final double altitude;
  final double speed;
  final double speedAccuracy;
  final double heading;

  Location._(this.latitude, this.longitude, this.accuracy, this.altitude,
      this.speed, this.speedAccuracy, this.heading);

  factory Location.fromJson(Map<dynamic, dynamic> json) {
    return Location._(
        json[Constants.ARG_LATITUDE],
        json[Constants.ARG_LONGITUDE],
        json[Constants.ARG_ACCURACY],
        json[Constants.ARG_ALTITUDE],
        json[Constants.ARG_SPEED],
        json[Constants.ARG_SPEED_ACCURACY],
        json[Constants.ARG_HEADING]);
  }

  @override
  String toString() {
    return 'Location{latitude: $latitude, longitude: $longitude, accuracy: $accuracy, altitude: $altitude, speed: $speed, speedAccuracy: $speedAccuracy, heading: $heading}';
  }
}

class GeoFence {
  final String id;
  final double latitude;
  final double longitude;
  final double radius;
  final int expiryInSec;

  GeoFence(
      this.id, this.latitude, this.longitude, this.radius, this.expiryInSec);

  factory GeoFence.fromJson(Map<dynamic, dynamic> json) {
    return GeoFence(
        json[Constants.ARG_GEOFENCE_ID],
        json[Constants.ARG_LATITUDE],
        json[Constants.ARG_LONGITUDE],
        json[Constants.ARG_GEOFENCE_RADIUS],
        json[Constants.ARG_GEOFENCE_EXP]);
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data[Constants.ARG_GEOFENCE_ID] = this.id;
    data[Constants.ARG_LATITUDE] = this.latitude;
    data[Constants.ARG_LONGITUDE] = this.longitude;
    data[Constants.ARG_GEOFENCE_RADIUS] = this.radius;
    data[Constants.ARG_GEOFENCE_EXP] = this.expiryInSec;
    return data;
  }

  @override
  String toString() {
    return 'GeoFence{id: $id, latitude: $latitude, longitude: $longitude, radius: $radius}';
  }
}

enum GeoFenceEvent { enter, exit, unknown }

class Constants {
  static const String FOREGROUND_CHANNEL_ID =
      'plugin/location_manager/foreground_channel';
  static const String BACKGROUND_CHANNEL_ID =
      'plugin/location_manager/background_channel';

  static const String METHOD_SERVICE_INITIALIZED =
      "LocationManagerPlugin.initialize";
  static const String METHOD_PLUGIN_INITIALIZE = 'LocationManager.initialize';
  static const String METHOD_PLUGIN_START_LOCATION_TRACKING =
      'LocationManager.startLocationTracking';
  static const String METHOD_PLUGIN_STOP_LOCATION_TRACKING =
      'LocationManager.stopLocationTracking';
  static const String METHOD_PLUGIN_GET_LAST_LOCATION =
      'LocationManager.getLastLocation';
  static const String METHOD_PLUGIN_GET_CURRENT_LOCATION =
      'LocationManager.getCurrentLocation';
  static const String METHOD_PLUGIN_CREATE_GEOFENCE =
      'LocationManager.createGeoFence';
  static const String METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID =
      'LocationManager.removeGeoFenceUsingId';
  static const String METHOD_PLUGIN_REMOVE_GEOFENCE =
      'LocationManager.removeGeoFence';
  static const String METHOD_PLUGIN_GET_ACTIVE_GEOFENCE =
      'LocationManager.getActiveGeoFence';
  static const String METHOD_PLUGIN_REMOVE_ALL_GEOFENCE =
      'LocatorService.removeAllGeoFence';
  static const String METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT =
      'LocationManager.monitorGeoFenceEvents';
  static const String METHOD_PLUGIN_MONITOR_LOCATION_UPDATE =
      'LocationManager.monitorLocationUpdates';

  static const String ARG_GEOFENCE_ID = 'id';
  static const String ARG_GEOFENCE_RADIUS = 'radius';
  static const String ARG_GEOFENCE_EXP = 'expInSec';
  static const String ARG_LATITUDE = 'latitude';
  static const String ARG_LONGITUDE = 'longitude';
  static const String ARG_ACCURACY = 'accuracy';
  static const String ARG_ALTITUDE = 'altitude';
  static const String ARG_SPEED = 'speed';
  static const String ARG_SPEED_ACCURACY = 'speed_accuracy';
  static const String ARG_HEADING = 'heading';
  static const String ARG_CALLBACK = 'callback';
  static const String ARG_LOCATION = 'location';
  static const String ARG_SETTINGS = 'settings';
  static const String ARG_CALLBACK_DISPATCHER = 'callbackDispatcher';
  static const String ARG_INTERVAL = 'interval';
  static const String ARG_DISTANCE_FILTER = 'distanceFilter';
  static const String ARG_LOCATION_PERMISSION_MSG = 'requestPermissionMsg';
  static const String ARG_NOTIFICATION_TITLE = 'notificationTitle';
  static const String ARG_NOTIFICATION_MSG = 'notificationMsg';

  static const String ARG_GEOFENCE_EVENT_CALLBACK = 'onGeoFenceEventArg';
  static const String ARG_LOCATION_UPDATE_CALLBACK = 'onLocationChangeArg';
}
