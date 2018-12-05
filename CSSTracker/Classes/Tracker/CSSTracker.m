//
//  CSSTracker.m
//  Pods
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTracker.h"
#import "UIViewController+CSSTracker.h"
#import "UIApplication+CSSTracker.h"
#import "CSSTrackerCrash.h"
#import "CSSTrackerSendParameter.h"
#import "CSSTrackerSender.h"
#import <MCLocationManager/MCLocationManager.h>
#import "CSSTracker+Private.h"
#import <CSSKit/NSObject+Addition.h>
#import <CSSKit/CSSCGUtilities.h>
#import <CSSKit/CSSMacros.h>
#import <CSSKit/NSDictionary+Addition.h>
#import <CSSNetworkClient/CSSNetworkClient+Singletop.h>

#define kCSSTMachineIdKey @"CSSTRACKER_MACHINEID"

typedef void(^CSSTrackerProvingBlock)(BOOL success);

@implementation CSSTracker{
    NSString *_serviceDomain; ///< 指定上报域名
    CSSTrackerProvingBlock _provingBlock; ///< 设备验证回调
    BOOL _provingSuccess; ///< 设备校验是否成功
    BOOL _startListSend;
}

+ (void)startTrackerWithServiceDomain:(NSString *)serviceDomain provingSuccess:(void (^)(BOOL success))provingBlock {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [UIViewController startTracker];
        [UIApplication startTracker];
        
        InstallSignalHandler();//信号量异常
        NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);//OC崩溃
        [CSSTracker sharedInstance]->_serviceDomain = serviceDomain;
        [CSSTracker sharedInstance]->_provingBlock = provingBlock;
        
        // 校验机器码,并初始化各种参数(sendParameter中有耗时参数,异步请求)
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            [[CSSTracker sharedInstance] provingMachineId];
            dispatch_async(dispatch_get_main_queue(), ^{
                [[MCLocationManager sharedInstance] locateByGpsWithAuthorizationJudge:YES];
            });
        });
        
        // 当唯一机器码存在, 则可以上报信息
        if ([CSSTracker sharedInstance]->_persistence.machineId > 0) {
            [CSSTrackerCrash getExceptionInfoUpload];//获取临时存储的崩溃信息
            [[CSSTracker sharedInstance]->_sender sendCustomEvents];
        }
    });
}

+ (BOOL)provingSuccess {
    return [CSSTracker sharedInstance]->_provingSuccess;
}

+ (double)machineId {
    return [CSSTracker sharedInstance]->_persistence.machineId;
}

+ (instancetype)sharedInstance {
    static CSSTracker *tracker;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        tracker = [[CSSTracker alloc] init];
    });
    return tracker;
}

- (instancetype)init {
    if (self = [super init]) {
        _persistence = [[CSSTrackerPersistence alloc] init];
        _persistence.machineId = [[NSUserDefaults standardUserDefaults] doubleForKey:kCSSTMachineIdKey];
        
        [self initSenderWithDomain:self->_serviceDomain];
    }
    return self;
}

- (void)initSenderWithDomain:(NSString *)serviceDomain {
    _sender = [[CSSTrackerSender alloc]initWithPersistence:_persistence];
}

- (void)provingMachineId {
    if (self->_persistence.machineId > 0) {
        // 本地已存在machineId
        self->_provingSuccess = YES;
        
        if (self->_provingBlock) {
            self->_provingBlock(YES);
            self->_provingBlock = nil;
        }
        
        // 发送启动列表上报信息
        _startListSend = YES;
        [self->_sender sendStartList];
    }
    
    NSMutableDictionary *parame = [[CSSTrackerSendParameter sharedInstance] css_toDic];
    if (self->_persistence.machineId > 0) {
        [parame setValue:@(self->_persistence.machineId) forKey:@"machineId"];
    }
    @weakify(self);
    //
    [[CSSNetworkClient css_sharedClient] POST:@"/log/malog.json" parameters:parame completion:^(CSSHTTPOperation *operation, id result, NSError *error) {
        @strongify(self);
        BOOL success = [[result objectOrNilForKey:@"success"] boolValue];
        if (success) {
            NSLog(@"success");
            double machineId = [[result objectOrNilForKey:@"data"] doubleValue];
            self->_persistence.machineId = machineId;
            // 缓存机器码到本地
            [[NSUserDefaults standardUserDefaults] setDouble:machineId forKey:kCSSTMachineIdKey];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            // 发送启动列表上报信息
            if (self->_startListSend == NO && machineId > 0) [self->_sender sendStartList];
            
            self->_provingSuccess = YES;
            if (self->_provingBlock) self->_provingBlock(self->_provingSuccess);
            
        } else {
            self->_provingSuccess = NO;
            if (self->_provingBlock) self->_provingBlock(self->_provingSuccess);
            //            NSLog(@"SDK校验失败");
        }
    }];
}

@end
