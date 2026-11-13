//
//  Generated file. Do not edit.
//

// clang-format off

#import "GeneratedPluginRegistrant.h"

#if __has_include(<image_picker_ios/ImagePickerPlugin.h>)
#import <image_picker_ios/ImagePickerPlugin.h>
#else
@import image_picker_ios;
#endif

#if __has_include(<printing/PrintingPlugin.h>)
#import <printing/PrintingPlugin.h>
#else
@import printing;
#endif

#if __has_include(<record_darwin/RecordDarwinPlugin.h>)
#import <record_darwin/RecordDarwinPlugin.h>
#else
@import record_darwin;
#endif

#if __has_include(<share_plus/FPPSharePlusPlugin.h>)
#import <share_plus/FPPSharePlusPlugin.h>
#else
@import share_plus;
#endif

#if __has_include(<shared_preferences_foundation/SharedPreferencesPlugin.h>)
#import <shared_preferences_foundation/SharedPreferencesPlugin.h>
#else
@import shared_preferences_foundation;
#endif

@implementation GeneratedPluginRegistrant

+ (void)registerWithRegistry:(NSObject<FlutterPluginRegistry>*)registry {
  [ImagePickerPlugin registerWithRegistrar:[registry registrarForPlugin:@"ImagePickerPlugin"]];
  [PrintingPlugin registerWithRegistrar:[registry registrarForPlugin:@"PrintingPlugin"]];
  [RecordDarwinPlugin registerWithRegistrar:[registry registrarForPlugin:@"RecordDarwinPlugin"]];
  [FPPSharePlusPlugin registerWithRegistrar:[registry registrarForPlugin:@"FPPSharePlusPlugin"]];
  [SharedPreferencesPlugin registerWithRegistrar:[registry registrarForPlugin:@"SharedPreferencesPlugin"]];
}

@end
