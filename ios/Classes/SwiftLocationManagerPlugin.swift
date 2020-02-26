import Flutter
import UIKit
import CoreLocation
import NotificationCenter

var registerPlugins: FlutterPluginRegistrantCallback? = nil
var initialized = false
var instance: SwiftLocationManagerPlugin? = nil

public class SwiftLocationManagerPlugin: NSObject {
    
    private var headlessRunner: FlutterEngine?
    private var callbackChannel: FlutterMethodChannel?
    private var mainChannel: FlutterMethodChannel?
    private var registrarInstance: FlutterPluginRegistrar?
    private var locationManager: CLLocationManager?
    
    private var locationEventQueue: [[AnyHashable : AnyHashable]] = [[:]]
    private var geofenceEventQueue: [[AnyHashable : AnyHashable]] = [[:]]
    
    init(_ registrar: FlutterPluginRegistrar?) {
        print("Initializing Plugin")
        super.init()
        locationManager = CLLocationManager()
        locationManager?.delegate = self
        locationManager?.desiredAccuracy = kCLLocationAccuracyBestForNavigation
        locationManager?.distanceFilter = 0.1
        if #available(iOS 11.0, *) {
            locationManager?.showsBackgroundLocationIndicator = false
        }
        locationManager?.pausesLocationUpdatesAutomatically = false
        if #available(iOS 9.0, *) {
            locationManager?.allowsBackgroundLocationUpdates = true
        }
        self.registrarInstance = registrar
        mainChannel = FlutterMethodChannel(name: Constants.FOREGROUND_CHANNEL_ID, binaryMessenger: (registrar?.messenger())!)
        registrar?.addMethodCallDelegate(self, channel: mainChannel!)
        
    }
    
    func startHeadlesService(_ handle: Int64) {
        print("Starting HeadlesService")
        setCallbackDispatcherHandle(handle)
        let info = FlutterCallbackCache.lookupCallbackInformation(handle)
        assert(info != nil, "Failed to find callback")
        headlessRunner?.destroyContext();
        headlessRunner = FlutterEngine(name: "LocationManagerIsolate", project: nil, allowHeadlessExecution: true)
        headlessRunner?.run(withEntrypoint: info?.callbackName, libraryURI: info?.callbackLibraryPath)
        callbackChannel = FlutterMethodChannel(name: Constants.BACKGROUND_CHANNEL_ID, binaryMessenger: (headlessRunner?.binaryMessenger)!)
        assert(registerPlugins != nil, "Failed to set registerPlugins")
        
        // Once our headless runner has been started, we need to register the application's plugins
        // with the runner in order for them to work on the background isolate. `registerPlugins` is
        // a callback set from AppDelegate.m in the main application. This callback should register
        // all relevant plugins (excluding those which require UI).
        if(headlessRunner != nil){
            registerPlugins?(headlessRunner!)}
        if(callbackChannel != nil){
            registrarInstance?.addMethodCallDelegate(self, channel: callbackChannel!)}
    }
    
    private func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        print("Application Launched because of : \(String(describing: launchOptions))")
        // Check to see if we're being launched due to a location event.
        if launchOptions?[UIApplication.LaunchOptionsKey.location] != nil {
            // Restart the headless service.
            startHeadlesService(getCallbackDispatcherHandle())
            startLocationTracking()
        }
        return true
    }
    
    public func applicationWillTerminate(_ application: UIApplication) {
        print("Entering Termination")
        locationManager?.stopUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()
    }
    
    public func applicationWillEnterForeground(_ application: UIApplication) {
        print("Entering Forground")
        locationManager?.stopMonitoringSignificantLocationChanges()
        locationManager?.startUpdatingLocation()
    }
}


extension SwiftLocationManagerPlugin: FlutterPlugin{
    
    public class func register(with registrar: FlutterPluginRegistrar) {
        print("Registering Registrar")
        instance = SwiftLocationManagerPlugin(registrar)
        registrar.addApplicationDelegate(instance!)
    }
    
    public class func setPluginRegistrantCallback(_ callback: @escaping FlutterPluginRegistrantCallback) {
        print("Registering Plugin Callback")
        registerPlugins = callback
    }
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        print("Handle Dart Method \(call.method)")
        let arguments = call.arguments as? [String: Any]
        switch call.method {
        case Constants.METHOD_SERVICE_INITIALIZED:
            let lock = DispatchQueue(label: "self")
            lock.sync {
                initialized = true
                while locationEventQueue.count > 0 {
                    let event = locationEventQueue[0] as [AnyHashable : AnyHashable]
                    locationEventQueue.remove(at: 0)
                    callbackChannel?.invokeMethod(Constants.ARG_LOCATION_UPDATE, arguments: event)
                }
                while geofenceEventQueue.count > 0 {
                    let event = geofenceEventQueue[0] as [AnyHashable : AnyHashable]
                    geofenceEventQueue.remove(at: 0)
                    callbackChannel?.invokeMethod(Constants.ARG_GEOFENCE_EVENT, arguments: event)
                }
            }
            result(NSNumber())
            break
        case Constants.METHOD_PLUGIN_INITIALIZE:
            let callbackDispatcher = (arguments?[Constants.ARG_CALLBACK_DISPATCHER] as? NSNumber)?.int64Value ?? 0
            startHeadlesService(callbackDispatcher)
            print("Dart Background Callback Channel initialized")
            result(nil)
            break
        case Constants.METHOD_PLUGIN_MONITOR_LOCATION_UPDATE:
            print("Location Callback: \((arguments?[Constants.ARG_LOCATION_UPDATE] as? NSNumber)?.int64Value ?? 0)")
            let callbackHandle = (arguments?[Constants.ARG_LOCATION_UPDATE] as? NSNumber)?.int64Value ?? 0
            setLocationUpdateHandle(callbackHandle)
            print("Location Event Callback Channel initialized")
            result(nil)
            break
        case Constants.METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT:
            print("GeoFence Callback: \((arguments?[Constants.ARG_GEOFENCE_EVENT] as? NSNumber)?.int64Value ?? 0)")
            
            let callbackHandle = (arguments?[Constants.ARG_GEOFENCE_EVENT] as? NSNumber)?.int64Value ?? 0
            setGeofenceEventHandle(callbackHandle)
            print("GeoFence Event Callback Channel initialized")
            result(nil)
            break
        case Constants.METHOD_PLUGIN_START_LOCATION_TRACKING:
            startLocationTracking()
            setTracking(isTracking: true)
            result(nil)
            break
        case Constants.METHOD_PLUGIN_STOP_LOCATION_TRACKING:
            stopLocationTracking()
            setTracking(isTracking: false)
            result(nil)
            break
        case Constants.METHOD_PLUGIN_CREATE_GEOFENCE:
            let geofenceData = arguments?["geofences"] as? [[String: Any]]
            geofenceData?.forEach({ (arg0) in
                let geofence = arg0 as [String: Any]
                addGeofence(id: geofence["id"] as! String, latitude: geofence["latitude"] as! Double, longitude: geofence["longitude"] as! Double, radius: geofence["radius"] as! Double)
            })
            result(nil)
            break
        case Constants.METHOD_PLUGIN_REMOVE_ALL_GEOFENCE:
            locationManager?.monitoredRegions.forEach({ (region) in
                if(!region.identifier.contains("Location")){
                    locationManager?.stopMonitoring(for: region)
                }
                print("Geoference Removed Id: \(region.identifier)")
            })
            result(nil)
            break
        case Constants.METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID:
            let geofenceIds = arguments?["geofence_ids"] as? [String]
            locationManager?.monitoredRegions.forEach({ (region) in
                geofenceIds?.forEach({ (id) in
                    if(id == region.identifier){
                        locationManager?.stopMonitoring(for: region)
                        print("Geoference Removed Id: \(id)")
                    }
                    
                })
            })
            result(nil)
            break
        default:
            result(FlutterMethodNotImplemented)
            break
        }
    }
    
}

/* -------------------------------- Location Manager Delegates ------------------------ */
extension SwiftLocationManagerPlugin: CLLocationManagerDelegate{
    
    public func locationManagerDidPauseLocationUpdates(_ manager: CLLocationManager) {
        print("Location Tracking Paused")
    }
    
    public func locationManagerDidResumeLocationUpdates(_ manager: CLLocationManager) {
        print("Location Tracking Resumed")
    }
    
    public func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        //        print("Location Received: \(locations.last!.coordinate.latitude) \(locations.last!.coordinate.longitude)")
        if(isTracking()){
            self.sendLocationEvent(location: locations.last!)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didEnterRegion region: CLRegion) {
        //        print("Entering in Region: \(region.identifier)")
        if let location = manager.location {
            self.sendGeofenceEvent(geofenceIds: [region.identifier], event: "ENTERED", location: location)
        }
    }
    
    public func locationManager(_ manager: CLLocationManager, didStartMonitoringFor region: CLRegion) {
        //        print("Monitoring Region: \(region.identifier)")
    }
    
    public func locationManager(_ manager: CLLocationManager, didExitRegion region: CLRegion) {
        //        print("Exiting from Region: \(region.identifier)")
        if let location = manager.location {
            self.sendGeofenceEvent(geofenceIds: [region.identifier], event: "EXITED", location: location)
        }
    }
    
    func addGeofence(id: String, latitude: Double, longitude: Double, radius: Double){
        self.takePermission()
        let geofenceRegionCenter = CLLocationCoordinate2DMake(latitude, longitude);
        let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter, radius: radius, identifier: id);
        geofenceRegion.notifyOnExit = true;
        geofenceRegion.notifyOnEntry = true;
        self.startMonitoringGeofence(geofence: geofenceRegion)
        print("Geofence Added addGeofence(id: String, latitude: Double, longitude: Double, radius: Double)")
    }
    
    func addGeofence(location: CLLocation){
        self.takePermission()
        let geofenceRegionCenter = CLLocationCoordinate2DMake(location.coordinate.latitude, location.coordinate.longitude);
        let geofenceRegion = CLCircularRegion(center: geofenceRegionCenter, radius: 300, identifier: "REGION-\(location.coordinate.latitude)-\(location.coordinate.longitude)");
        geofenceRegion.notifyOnExit = true;
        geofenceRegion.notifyOnEntry = true;
        self.startMonitoringGeofence(geofence: geofenceRegion)
        print("Geofence Added addGeofence(location: CLLocation)")
    }
    
    func takePermission(){
        locationManager?.requestAlwaysAuthorization()
    }
    
    func startLocationTracking(){
        self.takePermission()
        locationManager?.startUpdatingLocation()
        locationManager?.startMonitoringSignificantLocationChanges()
        print("Location Tracking Started")
    }
    
    func stopLocationTracking() {
        locationManager?.stopUpdatingLocation()
        print("Location Tracking Stopped")
    }
    
    func startMonitoringGeofence(geofence: CLRegion){
        self.locationManager?.startMonitoring(for: geofence)
    }
    
    func stopMonitoringGeofence(geofence: CLRegion){
        self.locationManager?.stopMonitoring(for: geofence)
        print("Monitoring Stopped for Geofence Region: \(geofence.identifier)")
    }
}

/* -------------------------------- Other Background Callback helper ------------------------ */
extension SwiftLocationManagerPlugin {
    
    /* This method will send Location Event to Dart Code in Sync manner */
    func sendLocationEvent(location: CLLocation){
        if let callback = callbackChannel {
            let lock = DispatchQueue(label: "self")
            lock.sync {
                let locationMap = [
                    Constants.ARG_LATITUDE: NSNumber(value: location.coordinate.latitude),
                    Constants.ARG_LONGITUDE: NSNumber(value: location.coordinate.longitude),
                    Constants.ARG_ACCURACY: NSNumber(value: location.horizontalAccuracy),
                    Constants.ARG_ALTITUDE: NSNumber(value: location.altitude),
                    Constants.ARG_SPEED: NSNumber(value: location.speed),
                    Constants.ARG_SPEED_ACCURACY: NSNumber(value: 0.0),
                    Constants.ARG_HEADING: NSNumber(value: location.course)
                ]
                var map: [AnyHashable : AnyHashable]=[:]
                map = [
                    Constants.ARG_LOCATION_UPDATE: NSNumber(value: getLocationUpdateHandle()),
                    Constants.ARG_LOCATION: locationMap
                ]
                if(initialized){
                    print("Sending Location Event: \(location.coordinate.latitude) \(location.coordinate.longitude)")
                    callback.invokeMethod(Constants.ARG_LOCATION_UPDATE, arguments: map)
                } else {
                    locationEventQueue.append(map)
                }
                return
            }
        }
    }
    
    /* This method will send Geofence Event to Dart Code in Sync manner */
    func sendGeofenceEvent(geofenceIds: [String], event: String, location: CLLocation){
        if let callback = callbackChannel {
            let lock = DispatchQueue(label: "self")
            lock.sync {
                let locationMap = [
                    Constants.ARG_LATITUDE: NSNumber(value: location.coordinate.latitude),
                    Constants.ARG_LONGITUDE: NSNumber(value: location.coordinate.longitude),
                    Constants.ARG_ACCURACY: NSNumber(value: location.horizontalAccuracy),
                    Constants.ARG_ALTITUDE: NSNumber(value: location.altitude),
                    Constants.ARG_SPEED: NSNumber(value: location.speed),
                    Constants.ARG_SPEED_ACCURACY: NSNumber(value: 0.0),
                    Constants.ARG_HEADING: NSNumber(value: location.course)
                ]
                var map: [AnyHashable : AnyHashable] = [:]
                map = [
                    Constants.ARG_GEOFENCE_EVENT: NSNumber(value: getGeofenceEventHandle()),
                    Constants.ARG_LOCATION: locationMap,
                    "geoFenceEvent":event,
                    "geofenceIds": geofenceIds
                ]
                if(initialized){
                    print("Sending Geofence Event: \(geofenceIds) \(event)  \(location.coordinate.latitude) \(location.coordinate.longitude)")
                    callback.invokeMethod(Constants.ARG_GEOFENCE_EVENT, arguments: map)
                } else {
                    geofenceEventQueue.append(map)
                }
                return
            }
        }
    }
}

/* -------------------------------- User Preferences & Local Notifications Functions ------------------------ */
extension SwiftLocationManagerPlugin {
    
    func sendNotification(title: String, description: String) {
        var userInfo: [AnyHashable : Any] = [:]
        userInfo["notification_id"] = "notificationID"
        let localNotification = UILocalNotification()
        localNotification.userInfo = userInfo // set the push id
        localNotification.alertBody = "Some Description" // Set the
        
        
        localNotification.fireDate = Date().addingTimeInterval(0) // Fire the notification now
        localNotification.timeZone = NSTimeZone.system
        localNotification.repeatInterval = []
        
        UIApplication.shared.scheduleLocalNotification(localNotification) // Ask
    }
    
    func getCallbackDispatcherHandle() -> Int64 {
        let handle = UserDefaults.standard.object(forKey: "kCallbackDispatcherKey")
        if handle == nil {
            return 0
        }
        return (handle as? NSNumber)?.int64Value ?? 0
    }
    
    func setCallbackDispatcherHandle(_ handle: Int64) {
        UserDefaults.standard.set(NSNumber(value: handle), forKey: "kCallbackDispatcherKey")
    }
    
    func getLocationUpdateHandle() -> Int64 {
        let handle = UserDefaults.standard.object(forKey: "kLocationUpdateHandleKey")
        if handle == nil {
            return 0
        }
        return (handle as? NSNumber)?.int64Value ?? 0
    }
    
    func setLocationUpdateHandle(_ handle: Int64) {
        UserDefaults.standard.set(NSNumber(value: handle), forKey: "kLocationUpdateHandleKey")
    }
    
    
    func getGeofenceEventHandle() -> Int64 {
        let handle = UserDefaults.standard.object(forKey: "kGeofenceEventKey")
        if handle == nil {
            return 0
        }
        return (handle as? NSNumber)?.int64Value ?? 0
    }
    
    func setTracking(isTracking: Bool) {
        UserDefaults.standard.set(isTracking, forKey: "kIsTracking")
    }
    
    
    func isTracking() -> Bool {
        return UserDefaults.standard.bool(forKey: "kIsTracking")
    }
    
    func setGeofenceEventHandle(_ handle: Int64) {
        UserDefaults.standard.set(NSNumber(value: handle), forKey: "kGeofenceEventKey")
    }
}

/* --------------------------------- Constants --------------------------------- */
public class Constants {
    // Callback HANDLES
    static var CALLBACK_DISPATCHER_HANDLE_KEY = "pluginCallDispatcherHandleKey"
    static var LOCATION_UPDATE_HANDLE_KEY = "pluginLocationUpdateHandleKey"
    static var GEOFENCE_EVENT_HANDLE_KEY = "pluginGeofenceEventHandleKey"
    
    static var METHOD_SERVICE_INITIALIZED = "LocationManagerPlugin.initialize";
    
    // Methods from Flutter Plugin
    static var METHOD_PLUGIN_INITIALIZE = "LocationManager.initialize"
    static var METHOD_PLUGIN_START_LOCATION_TRACKING =
    "LocationManager.startLocationTracking"
    static var METHOD_PLUGIN_STOP_LOCATION_TRACKING =
    "LocationManager.stopLocationTracking"
    static var METHOD_PLUGIN_GET_LAST_LOCATION =
    "LocationManager.getLastLocation"
    static var METHOD_PLUGIN_GET_CURRENT_LOCATION =
    "LocationManager.getCurrentLocation"
    static var METHOD_PLUGIN_CREATE_GEOFENCE =
    "LocationManager.createGeoFence"
    static var METHOD_PLUGIN_REMOVE_GEOFENCE_USING_ID =
    "LocationManager.removeGeoFenceUsingId"
    static var METHOD_PLUGIN_REMOVE_GEOFENCE =
    "LocationManager.removeGeoFence"
    static var METHOD_PLUGIN_GET_ACTIVE_GEOFENCE =
    "LocationManager.getActiveGeoFence"
    static var METHOD_PLUGIN_REMOVE_ALL_GEOFENCE =
    "LocatorService.removeAllGeoFence"
    static var METHOD_PLUGIN_MONITOR_GEOFENCE_EVENT =
    "LocationManager.monitorGeoFenceEvents"
    static var METHOD_PLUGIN_MONITOR_LOCATION_UPDATE =
    "LocationManager.monitorLocationUpdates"
    
    
    // Arguments
    static var ARG_LATITUDE = "latitude"
    static var ARG_LONGITUDE = "longitude"
    static var ARG_ACCURACY = "accuracy"
    static var ARG_ALTITUDE = "altitude"
    static var ARG_SPEED = "speed"
    static var ARG_SPEED_ACCURACY = "speed_accuracy"
    static var ARG_HEADING = "heading"
    static var ARG_LOCATION = "location"
    
    static var ARG_LOCATION_UPDATE = "onLocationChangeArg"
    
    static var ARG_GEOFENCE_ID = "id"
    static var ARG_GEOFENCE_RADIUS = "radius"
    
    static var ARG_GEOFENCE_EXP = "expInSec"
    static var ARG_SETTINGS = "settings"
    static var ARG_INTERVAL = "interval"
    static var ARG_DISTANCE_FILTER = "distanceFilter"
    static var ARG_LOCATION_PERMISSION_MSG = "requestPermissionMsg"
    static var ARG_NOTIFICATION_TITLE = "notificationTitle"
    static var ARG_NOTIFICATION_MSG = "notificationMsg"
    
    static var ARG_GEOFENCE_EVENT = "onGeoFenceEventArg"
    
    
    static var ARG_CALLBACK_DISPATCHER = "callbackDispatcher"
    
    // Channel Ids
    static var FOREGROUND_CHANNEL_ID =
    "plugin/location_manager/foreground_channel"
    static var BACKGROUND_CHANNEL_ID =
    "plugin/location_manager/background_channel"
    
    // Prefrences Keys
    static var KEY_LOCATION_UPDATES_REQUESTED = "location-updates-requested"
    
    static var KEY_GEOFENCE_IDS = "geofenceIdsKey"
    
    // Actions
    static var ACTION_LOCATION_UPDATE = "LocationManager.ACTION_LOCATION_UPDATE"
    static var ACTION_GEOFENCE_EVENT = "LocationManager.ACTION_GEOFENCE_EVENT"
    
}


