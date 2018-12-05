//
//  CSSTrackerCrash.h
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CSSTrackerCrash : NSObject

//上传错误信息
+ (BOOL)getExceptionInfoUpload;

//// 崩溃时的回调函数
void uncaughtExceptionHandler(NSException *exception);

//注册信号处理回调函数
void InstallSignalHandler(void);

@end

NS_ASSUME_NONNULL_END
