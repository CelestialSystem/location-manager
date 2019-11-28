package com.celestialsys.location_manager_example

import com.celestialsys.location_manager.LocationUpdatesIntentService
import io.flutter.app.FlutterApplication
import io.flutter.plugin.common.PluginRegistry
import io.flutter.plugins.GeneratedPluginRegistrant

class Application : FlutterApplication(), PluginRegistry.PluginRegistrantCallback {
    override fun onCreate() {
        super.onCreate()
        LocationUpdatesIntentService.setPluginRegistrant(this)
    }

    override fun registerWith(p0: PluginRegistry?) {
        GeneratedPluginRegistrant.registerWith(p0)
    }
}