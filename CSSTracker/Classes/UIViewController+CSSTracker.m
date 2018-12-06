//
//  UIViewController+CSSTracker.m
//  CSSDeviceInfoTool
//
//  Created by 陈坤 on 2018/12/5.
//

#import "UIViewController+CSSTracker.h"
#import <objc/runtime.h>
#import <CSSKit/NSObject+Addition.h>
#import "CSSTrackerEventModel.h"
#import "CSSTracker+Private.h"
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>

@implementation UIViewController (CSSTracker)

+ (NSArray *)funcList {
    unsigned  int count = 0;
    Method *methodList = class_copyMethodList([self class] , &count);
    NSMutableArray *array = [NSMutableArray array];
    for(int i = 0 ; i < count ; i++) {
        Method method = methodList[i];
        SEL selector = method_getName(method);
        NSString *funcName  =NSStringFromSelector(selector);
        [array addObject:funcName];
        
    }
    free(methodList);
    return array.copy;
}

+ (void)startTracker{
    NSString *select = @"aspects__viewWillAppear:";
    if (![[UIViewController funcList] containsObject:select]) {
        select = @"viewWillAppear:";
    }
    NSString *sele_JKUB = @"JKUBSaspects__viewWillAppear:";
    if ([[UIViewController funcList] containsObject:sele_JKUB]) {
        select = sele_JKUB;
    }
    
    NSString *dis_select = @"aspects__viewWillDisappear:";
    if (![[UIViewController funcList] containsObject:select]) {
        dis_select = @"viewWillDisappear:";
    }
    NSString *disSele_JKUB = @"JKUBSaspects__viewWillAppear:";
    if ([[UIViewController funcList] containsObject:sele_JKUB]) {
        dis_select = disSele_JKUB;
    }
    
    SEL selector = NSSelectorFromString(select);
    SEL dis_selector = NSSelectorFromString(dis_select);
    
    [self swizzleInstanceMethod:selector                                 with:@selector(css_trackerViewWillAppear:)];
    [self swizzleInstanceMethod:dis_selector with:@selector(css_trackerViewWillDisappear:)];
}

#pragma mark - Hook Method

- (void)css_trackerViewWillAppear:(BOOL)animated {
    [self css_trackerViewWillAppear:animated];
    
    [self persistOpenEvent];
}

- (void)css_trackerViewWillDisappear:(BOOL)animated {
    [self css_trackerViewWillDisappear:animated];
    
    [self persistCloseEvent];
}

#pragma mark - Event Persist

- (void)persistOpenEvent {
    CSSTrackerEventModel *model = [[CSSTrackerEventModel alloc] init];
    model.operationType = @"OPEN";
    model.scheme = NSStringFromClass([self class]);
    model.startTime = KCSSTDateString([NSDate date], @"yyyy-MM-dd HH:mm:ss.SSS");
//    [[MCTracker sharedInstance]->_persistence persistCustomEvent:model];
    [[CSSTracker sharedInstance] -> _persistence persistCustomEvent:model];
}

- (void)persistCloseEvent {
    CSSTrackerEventModel *model = [[CSSTrackerEventModel alloc] init];
    model.operationType = @"CLOSE";
    model.scheme = NSStringFromClass([self class]);
    model.endTime = KCSSTDateString([NSDate date], @"yyyy-MM-dd HH:mm:ss.SSS");
//    [[MCTracker sharedInstance]->_persistence persistCustomEvent:model];
    [[CSSTracker sharedInstance] -> _persistence persistCustomEvent:model];
}

@end
