import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:location_manager/location_manager.dart';

void main() => runApp(MyApp());

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  String _platformVersion = 'Unknown';

  @override
  void initState() {
    super.initState();
    initPlatformState();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> initPlatformState() async {


    await LocationManager.initialize();
    await LocationManager.monitorLocationUpdates(onLocationChange);
    await LocationManager.monitorGeoFenceEvents(onGeoFenceEvent);

    await LocationManager.startLocationTracking();

    await LocationManager.removeAllGeoFence();

//    await LocationManager.createGeoFence([
//      GeoFence("Office", 28.588557, 77.313695, 50.0, 0),
//      GeoFence("Room",28.589924, 77.306499, 100.0, 0),
//      GeoFence("Aggrawal-Sweets",28.590708, 77.307268, 100, 0),
//      GeoFence("Mid-Market",28.590062, 77.307869, 100, 0),
//      GeoFence("Round-About",28.589141, 77.308601, 100, 0),
//      GeoFence("DSI-Midway",28.589302, 77.309969, 100, 0),
//      GeoFence("Midway-Cross", 28.589796, 77.310896, 100, 0),
//      GeoFence("Midway-Cross-1", 28.589246, 77.311294, 100, 0),
//      GeoFence("Midway-Cross-2", 28.588566, 77.311762, 100, 0),
//      GeoFence("Wine-Shop", 28.587819, 77.312326, 100, 0),
//    ]);
//    await LocationManager.removeGeoFenceUsingId(["Aggrawal-Sweets"]);
  }

  static void onLocationChange(Location location) async {
//    print("Location Update Received: ${location.toString()}");
    initNotification();
    showNotification(
        "Location Received", "${location.latitude} ${location.longitude}");
  }

  static void onGeoFenceEvent(
      List<String> ids, GeoFenceEvent event, Location location) async {
//    print("GeoFence Event Received: $ids $event, $location");
    initNotification();
    showNotification("Geofence Event Received", "$event in $ids");
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Text('Running on: $_platformVersion\n'),
        ),
      ),
    );
  }

  static FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin;

  static void initNotification() async {
    flutterLocalNotificationsPlugin = new FlutterLocalNotificationsPlugin();
// initialise the plugin. app_icon needs to be a added as a drawable resource to the Android head project
    var initializationSettingsAndroid =
        new AndroidInitializationSettings('app_icon');
    var initializationSettingsIOS = new IOSInitializationSettings(
        onDidReceiveLocalNotification: onDidReceiveLocalNotification);
    var initializationSettings = new InitializationSettings(
        initializationSettingsAndroid, initializationSettingsIOS);
    flutterLocalNotificationsPlugin.initialize(initializationSettings,
        onSelectNotification: onSelectNotification);
  }

  static void showNotification(String title, String description) async {
    var androidPlatformChannelSpecifics = AndroidNotificationDetails(
        'your channel id', 'your channel name', 'your channel description',
        importance: Importance.Max, priority: Priority.High, ticker: 'ticker');
    var iOSPlatformChannelSpecifics = IOSNotificationDetails();
    var platformChannelSpecifics = NotificationDetails(
        androidPlatformChannelSpecifics, iOSPlatformChannelSpecifics);
    await flutterLocalNotificationsPlugin.show(
        0, title, description, platformChannelSpecifics,
        payload: 'item x');
  }

  static Future<void> onDidReceiveLocalNotification(
      int id, String title, String body, String payload) async {
    print("onDidReceiveLocalNotification");
  }

  static Future<void> onSelectNotification(String payload) async {
    print("onSelectNotification");
  }
}
