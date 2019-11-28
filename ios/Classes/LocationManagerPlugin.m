#import "LocationManagerPlugin.h"
#import <location_manager/location_manager-Swift.h>

@implementation LocationManagerPlugin
+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
  [SwiftLocationManagerPlugin registerWithRegistrar:registrar];
}
@end
