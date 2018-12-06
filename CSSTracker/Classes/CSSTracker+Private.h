//
//  CSSTracker+Private.h
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTracker.h"
#import "CSSTrackerSender.h"

NS_ASSUME_NONNULL_BEGIN

@interface CSSTracker (){
@package
    CSSTrackerPersistence *_persistence; ///< 持久层,唯一
    CSSTrackerSender *_sender; ///< 信息上报,唯一
}

+ (instancetype)sharedInstance;

@end

NS_ASSUME_NONNULL_END
