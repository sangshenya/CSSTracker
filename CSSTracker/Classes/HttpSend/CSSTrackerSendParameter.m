//
//  CSSTrackerSendParameter.m
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTrackerSendParameter.h"
#import <MCLocationManager/MCLocationManager.h>
#import <CSSKit/CSSMacros.h>
#import <CSSKit/CSSCGUtilities.h>
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>

#define kCSSTParameterUnknown @"unknown"

@implementation CSSTrackerSendParameter

+ (instancetype)sharedInstance {
    static CSSTrackerSendParameter *sendParameter;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sendParameter = [[CSSTrackerSendParameter alloc] init];
    });
    return sendParameter;
}

- (id)init {
    if (self = [super init]) {
        _screenWidth = kScreenWidth;
        _screenHeight = kScreenHeight;
        _ua = KCSSTWebviewUA(); //耗时操作
        _imsi = kStringIsEmpty(KCSSTIMSI()) ? kCSSTParameterUnknown : KCSSTIMSI();
        _machineType = 2;
        _sdScreendpi = [CSSDeviceInfoTool devicePPI];
        _osVersion = KCSSTSystemVersion();
        _vendor = @"apple";
        _modelNo = [CSSDeviceInfoTool deviceModel];
        _rawModelNo = [CSSDeviceInfoTool rawDeviceModel];
        _idfa = KCSSTIDFA();
        _openUdid = KCSSTOpenUDID(nil); //耗时操作
        _deviceType = KCSSTDeviceType();
        _idfv = KCSSTIDFV();
        _language = KCSSTDeviceLanguage();
        _isroot = KCSSTDeviceJailbroken() ? 1 : 0;
        _mcc = KCSSTMCC();
        _cpuType = KCSSTDeviceCPUType();
        _cpuSubtype = KCSSTDeviceCPUSubType();
    }
    return self;
}

- (NSString *)networkType {
    return KCSSTNetworkType();
}


- (NSString *)lat {
    return [NSString stringWithFormat:@"%.2f", [MCLocationManager sharedInstance].latitude];
}

- (NSString *)lng {
    return [NSString stringWithFormat:@"%.2f", [MCLocationManager sharedInstance].longitude];
}

- (NSString *)ip {
    NSString *ip = kStringIsEmpty(KCSSTNetworkIP(YES)) ? kCSSTParameterUnknown : KCSSTNetworkIP(YES);
    return ip;
}

- (NSString *)orientation {
    return KCSSTDeviceOrientation();
}

- (int)battery {
    return KCSSTDeviceBattery();
}

- (NSString *)country {
    return [MCLocationManager sharedInstance].ISOcountryCode;
}

- (int)coordinateType {
    return [MCLocationManager sharedInstance].coordinate_type;
}

- (double)locaAccuracy {
    return [MCLocationManager sharedInstance].coordinate_accuracy;
}

- (double)coordTime {
    return [MCLocationManager sharedInstance].coordinate_time;
}

- (NSString *)bssId {
    return [CSSDeviceInfoTool wifiBSSID];
}

- (NSString *)ssid {
    return [CSSDeviceInfoTool wifiSSID];
}

@end
