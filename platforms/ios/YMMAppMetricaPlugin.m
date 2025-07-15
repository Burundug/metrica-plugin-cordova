/*
 * Version for Cordova/PhoneGap
 * You may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 * https://yandex.com/legal/appmetrica_sdk_agreement/
 */

#import "YMMAppMetricaPlugin.h"

#import <AppMetricaCore/AppMetricaCore.h>
#import <AppMetricaCrashes/AppMetricaCrashes.h>
#import <CoreLocation/CoreLocation.h>

static bool gYMMIsAppMetricaActivated = false;

@implementation YMMAppMetricaPlugin



- (void)handleOpenURL:(NSNotification *)notification
{
    [super handleOpenURL:notification];

    NSURL *URL = [notification object];
    if ([URL isKindOfClass:[NSURL class]]) {
        [self dispatchAsync:^{
            [AMAAppMetrica trackOpeningURL:URL];
        }];
    }
}

#pragma mark - Commands

- (void)activate:(CDVInvokedUrlCommand *)command
{
    NSDictionary *configurationDictionary = [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];

    [self dispatchAsync:^{
        [[self class] activateWithConfigurationDictionary:configurationDictionary];

    }];
}

- (void)reportEvent:(CDVInvokedUrlCommand *)command
{
    NSString *eventName = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSDictionary *eventParams = [command argumentAtIndex:1 withDefault:nil andClass:[NSDictionary class]];

    [self dispatchAsync:^{
        [AMAAppMetrica reportEvent:eventName
                           parameters:eventParams
                            onFailure:[self failureCallbackForCommand:command]];
    }];
}

- (void)reportError:(CDVInvokedUrlCommand *)command
{
    NSString *errorName = [command argumentAtIndex:0 withDefault:nil andClass:[NSString class]];
    NSString *errorReason = [command argumentAtIndex:1 withDefault:nil andClass:[NSString class]];
    AMAError *underlyingError = [AMAError errorWithIdentifier:@"Underlying AMAError"];
    [self dispatchAsync:^{
        AMAError *error = [AMAError errorWithIdentifier:errorName
                                                message:errorReason
                                             parameters:@{ @"foo": @"bar" }
                                              backtrace:NSThread.callStackReturnAddresses
                                        underlyingError:underlyingError];
        [[AMAAppMetricaCrashes crashes] reportError:error  onFailure:[self failureCallbackForCommand:command]];
    }];
}

- (void)setLocation:(CDVInvokedUrlCommand *)command
{
    NSDictionary *locationDictionary = [command argumentAtIndex:0 withDefault:nil andClass:[NSDictionary class]];

    [self dispatchAsync:^{
        CLLocation *location = [[self class] locationForDictionary:locationDictionary];
        AMAAppMetrica.customLocation = location;
    }];
}

- (void)setLocationTracking:(CDVInvokedUrlCommand *)command
{
    NSNumber *enabledValue = [command argumentAtIndex:0 withDefault:nil andClass:[NSNumber class]];

    if (enabledValue != nil) {
        [self dispatchAsync:^{
            AMAAppMetrica.locationTrackingEnabled = enabledValue.boolValue;
        }];
    }
}

- (AMAECommerceScreen *)createScreen:(NSDictionary *)screen {
    AMAECommerceScreen *screenObj = [[AMAECommerceScreen alloc] initWithName:screen[@"screenName"] categoryComponents:@[] searchQuery:screen[@"searchQuery"] payload:@{}];
    return screenObj;
}

- (AMAECommerceProduct *)createProduct:(NSDictionary *)product {
    AMAECommerceAmount *actualFiat = [[AMAECommerceAmount alloc] initWithUnit:product[@"currency"] value:[NSDecimalNumber decimalNumberWithString:product[@"price"]]];
    AMAECommercePrice *actualPrice = [[AMAECommercePrice alloc] initWithFiat:actualFiat internalComponents:@[]];
    AMAECommerceProduct *productObj = [[AMAECommerceProduct alloc] initWithSKU:product[@"sku"] name:product[@"name"] categoryComponents:@[] payload:@{} actualPrice:actualPrice originalPrice:actualPrice promoCodes:@[]];
    return productObj;
}

- (AMAECommercePrice *)createPrice:(NSDictionary *)product {
    AMAECommerceAmount *priceObj = [[AMAECommerceAmount alloc] initWithUnit:product[@"currency"] value:[NSDecimalNumber decimalNumberWithString:product[@"price"]]];
    AMAECommercePrice *actualPrice = [[AMAECommercePrice alloc] initWithFiat:priceObj internalComponents:@[]];

    return actualPrice;
}

- (AMAECommerceCartItem *)createCartItem:(NSDictionary *)product {
    AMAECommerceScreen *screen = [self createScreen:@{}];

    AMAECommerceProduct *productObj = [self createProduct:product];

    AMAECommerceReferrer *referrer = [[AMAECommerceReferrer alloc] initWithType:@"" identifier:@"" screen:screen];

    NSDecimalNumber *quantity = [NSDecimalNumber decimalNumberWithString:product[@"quantity"]];

    AMAECommercePrice *actualPrice = [self createPrice:product];

    AMAECommerceCartItem *cartItem = [[AMAECommerceCartItem alloc]  initWithProduct:productObj quantity:quantity revenue:actualPrice referrer:referrer];

    return cartItem;
}

// Используйте его, чтобы сообщить об открытии какой-либо страницы, например: списка товаров, поиска, главной страницы.

- (void)showScreen:(CDVInvokedUrlCommand *)command {
    NSDictionary* args = [command.arguments objectAtIndex:0];
    AMAECommerceScreen *screenObj = [self createScreen:args];
    [AMAAppMetrica reportECommerce:[AMAECommerce showScreenEventWithScreen:screenObj] onFailure:nil];
    CDVPluginResult* pluginResult = nil;
    if (args != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ecommerce sending"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}


- (void)showProductCard:(CDVInvokedUrlCommand *)command {
    NSDictionary* args = [command.arguments objectAtIndex:0];
    AMAECommerceScreen *screen = [self createScreen:@{}];
    AMAECommerceProduct *productObj = [self createProduct:args];
    [AMAAppMetrica reportECommerce:[AMAECommerce showProductCardEventWithProduct:productObj screen:screen] onFailure:nil];
    CDVPluginResult* pluginResult = nil;
    if (args != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ecommerce sending"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)addToCart:(CDVInvokedUrlCommand *)command {
    NSDictionary* args = [command.arguments objectAtIndex:0];
    AMAECommerceCartItem *cartItem = [self createCartItem:args];
    [AMAAppMetrica reportECommerce:[AMAECommerce addCartItemEventWithItem:cartItem] onFailure:nil];
    CDVPluginResult* pluginResult = nil;
    if (args != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ecommerce sending"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)removeFromCart:(CDVInvokedUrlCommand *)command {
    NSDictionary* args = [command.arguments objectAtIndex:0];
    AMAECommerceCartItem *cartItem = [self createCartItem:args];
    [AMAAppMetrica reportECommerce:[AMAECommerce removeCartItemEventWithItem:cartItem] onFailure:nil];
    CDVPluginResult* pluginResult = nil;
    if (args != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ecommerce sending"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}

- (void)finishCheckout:(CDVInvokedUrlCommand *)command {
    NSDictionary* args = [command.arguments objectAtIndex:0];
    NSString* identifier = [args objectForKey:@"identifier"];
    NSArray<NSDictionary *> * products = [args objectForKey:@"products"];
    NSMutableArray *cartItems = [[NSMutableArray alloc] init];
        for(int i=0; i< products.count; i++){
           [cartItems addObject:[self createCartItem:products[i]]];
        }
    AMAECommerceOrder *order = [[AMAECommerceOrder alloc] initWithIdentifier:identifier
                                                                       cartItems:cartItems
                                                                         payload:@{}];

        [AMAAppMetrica reportECommerce:[AMAECommerce purchaseEventWithOrder:order] onFailure:nil];
    CDVPluginResult* pluginResult = nil;
    if (args != nil) {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_OK messageAsString:@"Ecommerce sending"];
    } else {
        pluginResult = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR messageAsString:@"Arg was null"];
    }
    [self.commandDelegate sendPluginResult:pluginResult callbackId:command.callbackId];
}



#pragma mark - Utils

- (void (^)(NSError *error))failureCallbackForCommand:(CDVInvokedUrlCommand *)command
{
    return ^(NSError * _Nonnull error) {
        CDVPluginResult *result = [CDVPluginResult resultWithStatus:CDVCommandStatus_ERROR
                                                    messageAsString:error.description];
        [self.commandDelegate sendPluginResult:result callbackId:command.callbackId];
    };
}

+ (AMAAppMetricaConfiguration *)configurationForDictionary:(NSDictionary *)configurationDictionary
{
    NSString *apiKey = configurationDictionary[@"apiKey"];

    AMAAppMetricaConfiguration *configuration = [[AMAAppMetricaConfiguration alloc] initWithAPIKey:apiKey];

    NSNumber *handleFirstActivationAsUpdate = configurationDictionary[@"handleFirstActivationAsUpdate"];
    NSNumber *sessionTimeout = configurationDictionary[@"sessionTimeout"];
    NSNumber *crashReporting = configurationDictionary[@"crashReporting"];
    NSString *appVersion = configurationDictionary[@"appVersion"];
    NSNumber *logs = configurationDictionary[@"logs"];
    NSDictionary *customLocationDictionary = configurationDictionary[@"location"];
    NSDictionary *preloadInfoDictionary = configurationDictionary[@"preloadInfo"];

    if (handleFirstActivationAsUpdate != nil) {
        configuration.handleFirstActivationAsUpdate = [handleFirstActivationAsUpdate boolValue];
    }
    if (sessionTimeout != nil) {
        configuration.sessionTimeout = [sessionTimeout unsignedIntegerValue];
    }
    if (appVersion != nil) {
        configuration.appVersion = appVersion;
    }

    if (preloadInfoDictionary != nil) {
        NSString *trackingID = preloadInfoDictionary[@"trackingId"];
        AMAAppMetricaPreloadInfo *preloadInfo =
            [[AMAAppMetricaPreloadInfo alloc] initWithTrackingIdentifier:trackingID];
        NSDictionary *additionalInfo = preloadInfoDictionary[@"additionalParams"];
        for (NSString *key in additionalInfo) {
            [preloadInfo setAdditionalInfo:additionalInfo[key] forKey:key];
        }
        configuration.preloadInfo = preloadInfo;
    }

    return configuration;
}

+ (CLLocation *)locationForDictionary:(NSDictionary *)locationDictionary
{
    if (locationDictionary == nil) {
        return nil;
    }

    NSNumber *latitude = locationDictionary[@"latitude"];
    NSNumber *longitude = locationDictionary[@"longitude"];
    NSNumber *altitude = locationDictionary[@"altitude"];
    NSNumber *horizontalAccuracy = locationDictionary[@"accuracy"];
    NSNumber *verticalAccuracy = locationDictionary[@"verticalAccuracy"];
    NSNumber *course = locationDictionary[@"course"];
    NSNumber *speed = locationDictionary[@"speed"];
    NSNumber *timestamp = locationDictionary[@"timestamp"];

    NSDate *locationDate = timestamp != nil ? [NSDate dateWithTimeIntervalSince1970:timestamp.doubleValue] : [NSDate date];
    CLLocationCoordinate2D coordinate = CLLocationCoordinate2DMake(latitude.doubleValue, longitude.doubleValue);
    CLLocation *location = [[CLLocation alloc] initWithCoordinate:coordinate
                                                         altitude:altitude.doubleValue
                                               horizontalAccuracy:horizontalAccuracy.doubleValue
                                                 verticalAccuracy:verticalAccuracy.doubleValue
                                                           course:course.doubleValue
                                                            speed:speed.doubleValue
                                                        timestamp:locationDate];
    return location;
}

- (void)dispatchAsync:(dispatch_block_t)block
{
    [self.commandDelegate runInBackground:block];
}

+ (void)activateWithConfigurationDictionary:(NSDictionary *)configuration
{
    AMAAppMetricaConfiguration *config = [[self class] configurationForDictionary:configuration];
    [AMAAppMetrica activateWithConfiguration:config];
    gYMMIsAppMetricaActivated = true;
}

+ (bool)isAppMetricaActivated
{
    return gYMMIsAppMetricaActivated;
}

@end
