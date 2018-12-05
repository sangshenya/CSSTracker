//
//  CSSTrackerEventModel.m
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTrackerEventModel.h"
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>

@implementation CSSTrackerEventModel

- (int)machineType {
    return 2;
}

- (NSString *)packageName {
    return KCSSTAPPBundleID();
}

- (NSString *)versionNo {
    return KCSSTAPPVersion();
}

- (double)machineId {
//    return [MCTracker sharedInstance]->_persistence.machineId;
    return 23418412851;
}

@end
