//
//  CSSTrackerSender.h
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import <Foundation/Foundation.h>
#import "CSSTrackerPersistence.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSSTrackerSender : NSObject

/**
 根据持久层初始化信息上报层,全局共享一个持久层对象
 
 @param persistence 持久层对象
 @return return value description
 */
- (instancetype)initWithPersistence:(CSSTrackerPersistence *)persistence;

/**
 上报自定义信息
 */
- (void)sendCustomEvents;

/**
 上报启动列表信息
 */
- (void)sendStartList;

@end

NS_ASSUME_NONNULL_END
