//
//  CSSTrackerCrash.m
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTrackerCrash.h"
#include <libkern/OSAtomic.h>
#include <execinfo.h>
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>
#import <CSSKit/CSSMacros.h>
#import "CSSTrackerEventModel.h"
#import <CSSKit/NSArray+Addition.h>
#import "CSSTracker+Private.h"

@implementation CSSTrackerCrash

//收集崩溃的上下文信息
void uncaughtExceptionHandler(NSException *exception){
    NSArray *stackArry= [exception callStackSymbols];
    NSString *reason = [exception reason];
    NSString *name = [exception name];
    NSString *exceptionInfo = [NSString stringWithFormat:@"Exception name:%@\nException reatoin:%@\nException stack :%@",name,reason,stackArry];
    
    [CSSTrackerCrash saveExceptionInfo:exceptionInfo];
}

//回调函数中收集调用堆栈信息
void SignalExceptionHandler(int signal){
    NSMutableString *mstr = [[NSMutableString alloc] init];
    [mstr appendString:@"Stack:\n"];
    void* callstack[128];
    int i, frames = backtrace(callstack, 128);
    char** strs = backtrace_symbols(callstack, frames);
    for (i = 0; i <frames; ++i) {
        [mstr appendFormat:@"%s\n", strs[i]];
    }
    [CSSTrackerCrash saveExceptionInfo:mstr];
}

//注册信号处理回调函数
void InstallSignalHandler(void){
    signal(SIGHUP, SignalExceptionHandler);//程序终端中止信号
    signal(SIGINT, SignalExceptionHandler);//程序键盘终端信号
    signal(SIGQUIT, SignalExceptionHandler);//这个异常是由于其它进程拥有高优先级且可以管理本进程（因此被高优先级进程Kill掉）所导致。SIGQUIT不代表进程发生Crash了，但是它确实反映了某种不合理的行为
    
    signal(SIGABRT, SignalExceptionHandler);//程序终止命令中止信号
    signal(SIGILL, SignalExceptionHandler);//程序非法指令信号
    signal(SIGSEGV, SignalExceptionHandler);//程序无效内存中止信号
    signal(SIGFPE, SignalExceptionHandler);//程序浮点异常信号
    signal(SIGBUS, SignalExceptionHandler);//程序内存字节未对齐中止信号
    signal(SIGPIPE, SignalExceptionHandler);//程序Socket发送失败中止信号
}

#pragma mark - 将崩溃信息存储到临时存储地址
+ (void)saveExceptionInfo:(NSString *)exceptionInfo{
    NSString *libPath = [self exceptionInfoPath];
    if (![[NSFileManager defaultManager] fileExistsAtPath:libPath]){
        [[NSFileManager defaultManager] createDirectoryAtPath:libPath withIntermediateDirectories:YES attributes:nil error:nil];
    }
    NSString *timeString = KCSSTDateString([NSDate date], @"yyyy-MM-dd HH:mm:ss.SSS");
    
    NSString * savePath = [libPath stringByAppendingFormat:@"/error.%@.log",timeString];
    
    [exceptionInfo writeToFile:savePath atomically:YES encoding:NSUTF8StringEncoding error:nil];
}

#pragma mark - 获取崩溃信息临时存储地址
+ (NSString *)exceptionInfoPath{
    return [[NSSearchPathForDirectoriesInDomains(NSCachesDirectory, NSUserDomainMask, YES) objectAtIndex:0] stringByAppendingPathComponent:@"CSSException"];
}

#pragma mark - 获取崩溃信息并上传
+ (BOOL)getExceptionInfoUpload{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libPath  = [self exceptionInfoPath];
    NSArray *fileList = [[NSArray alloc] init];
    NSError *error = nil;
    //fileList便是包含有该文件夹下所有文件的文件名及文件夹名的数组
    fileList = [fileManager contentsOfDirectoryAtPath:libPath error:&error];
    
    if (kArrayIsEmpty(fileList)) {//说明没有文件
        return YES;
    }
    //在上面那段程序中获得的fileList中列出文件夹名
    for (NSString *file in fileList) {
        NSString *path = [libPath stringByAppendingPathComponent:file];
        if ([file containsString:@"error"]) {
            //获取信息
            CSSTrackerEventModel *model = [[CSSTrackerEventModel alloc]init];
            model.operationType = @"CRASH";
            //崩溃信息
            NSString *crashInfo = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
            model.scheme = kStringIsEmpty(crashInfo)?@"":crashInfo;
            NSArray *strArray = [file componentsSeparatedByString:@"."];
            //时间
            model.startTime = kStringIsEmpty([strArray objectOrNilAtIndex:1])?KCSSTDateString([NSDate date], @"yyyy-MM-dd HH:mm:ss.SSS"):[strArray objectOrNilAtIndex:1];
            //发送
            [[CSSTracker sharedInstance] -> _persistence persistCustomEvent:model];
//            [[MCTracker sharedInstance] ->_persistence persistCustomEvent:model];
            //删除文件
            [fileManager removeItemAtPath:path error:nil];
        }
    }
    return YES;
}

@end
