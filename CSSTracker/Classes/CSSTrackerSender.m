//
//  CSSTrackerSender.m
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTrackerSender.h"
#import <CSSNetworkClient/CSSNetworkClient+Singletop.h>
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>
#import <CSSDeviceInfoTool/CSSEncryptAES.h>
#import <CSSDeviceInfoTool/CSSEncryptRSA.h>
#import <CSSKit/CSSMacros.h>

@implementation CSSTrackerSender{
    CSSTrackerPersistence *_persistence;
}

/**
 根据持久层初始化信息上报层,全局共享一个持久层对象
 
 @param persistence 持久层对象
 @return return value description
 */
- (instancetype)initWithPersistence:(CSSTrackerPersistence *)persistence{
    if (self = [super init]) {
        _persistence = persistence;
    }
    return self;
}

/**
 上报自定义信息
 */
- (void)sendCustomEvents{
    NSString *filePath = [_persistence nextArchivedCustomEventsPath];
    if (!filePath) {
        return;
    }
    NSData *data = [_persistence uploadCustomEventsDataWithPath:filePath];
    if (!data.length) {
        //TODO:描述错误
        return;
    }
    
    @weakify(self);
    [[CSSNetworkClient css_sharedClient] POST:@"/log/oplog.json" data:data headers:nil completion:^(CSSHTTPOperation *operation, id result, NSError *error) {
        @strongify(self);
        if (!error) {
            //            NSLog(@"send custom events succeeded: %@", filePath);
            [self->_persistence clearFile:filePath error:nil];
            [self sendCustomEvents];
        } else {
            //TODO:描述错误
            //            NSLog(@"send custom events error:%@", error.localizedDescription);
        }
    }];
    
}

/**
 上报启动列表信息
 */
- (void)sendStartList{
    if (_persistence.machineId <= 0) {
        return;
    }
    NSMutableDictionary *parame = [NSMutableDictionary dictionary];
    [parame setValue:KCSSTAPPBundleID() forKey:@"packageName"];
    [parame setValue:@(self->_persistence.machineId) forKey:@"machineId"];
    [parame setValue:KCSSTDateString([NSDate date], @"yyyy-MM-dd HH:mm:ss") forKey:@"startTime"];
    
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:@[parame] options:NSJSONWritingPrettyPrinted error:nil];
    NSString *jsonString = [[NSString alloc]initWithData:jsonData encoding:NSUTF8StringEncoding];
    
    NSString *aeskey = KCSSTRandomStringOfLength(16);
    NSString *aesContent = KCSSTAESEncryptString(jsonString, aeskey);
    
    NSString *aeskeyOfRSA = [CSSEncryptRSA encryptString:aeskey publicKey:@"MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQC9AnMx0xJR5Oy/7k0MPedEsYLv3U3iRue/+GyqBEH4rQB6rKp54NeKr8B5kZWx0KvRjlnEyz44pMc495ZTsr2gJwjPRPIUVfmLQuB6qXOngf5O2E5X9YpXPKURi2UWzpVabHiD1nD7tJoyE8HMYCa7zQOaG45oJOXLBOPpFdppPQIDAQAB"];
    
    if (kStringIsEmpty(aesContent) || kStringIsEmpty(aeskeyOfRSA)) {
        return;
    }
    
    // 转成 @"jsons=XXXXXXX"的字符串方式,用formdata上传
    NSDictionary *contentDic = @{@"content":aesContent, @"key":aeskeyOfRSA, @"terminal": @"ios",@"machineId":[NSString stringWithFormat:@"%f",self->_persistence.machineId]};
    NSData *contentJsonData = [NSJSONSerialization dataWithJSONObject:contentDic options:NSJSONWritingPrettyPrinted error:nil];
    NSString *base64ContentJsonString = [contentJsonData base64EncodedStringWithOptions:0];
    NSString *inputString = [@"jsons=" stringByAppendingFormat:@"%@", base64ContentJsonString];
    NSData *inputData = [inputString dataUsingEncoding:NSUTF8StringEncoding];
    
    [[CSSNetworkClient css_sharedClient] POST:@"/log/strlog.json" data:inputData headers:@{@"Content-Type":@"application/x-www-form-urlencoded"} completion:^(CSSHTTPOperation *operation, id result, NSError *error) {
        
    }];
    
}

@end
