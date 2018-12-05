//
//  CSSTrackerPersistence.m
//  CSSTracker
//
//  Created by 陈坤 on 2018/12/5.
//

#import "CSSTrackerPersistence.h"
#import <CSSDeviceInfoTool/CSSDeviceInfoTool.h>
#import <CSSKit/CSSMacros.h>
#import <CSSKit/NSObject+Addition.h>

#define MCTrackerMaxCacheFileSize 512 * 1024 //512KB

@implementation CSSTrackerPersistence{
    NSFileManager *_fileManager;
    
    NSString *_eventDir;
    NSFileHandle *_eventFileHandle;
    NSMutableArray<CSSTrackerEventModel *> *_eventInfoArray;
    dispatch_queue_t _eventIOQueue;
}

- (instancetype)init {
    if (self = [super init]) {
        _fileManager = [NSFileManager defaultManager];
        
        _eventInfoArray = [NSMutableArray array];
        _eventDir = [NSString stringWithFormat:@"%@/%@", KCSSTCacheDirectory(), @"event"];
        _eventIOQueue = dispatch_queue_create("css_custom_event", DISPATCH_QUEUE_SERIAL);
        
        NSError *error;
        [_fileManager createDirectoryAtPath:_eventDir withIntermediateDirectories:YES attributes:nil error:&error];
        if (error) {
            //TODO:错误描述
        }
        //TODO:日志记录
    }
    return self;
}

- (void)setMachineId:(double)machineId {
    _machineId = machineId;
    
    dispatch_async(_eventIOQueue, ^{
        // _machineId存在,临时内存缓存转到磁盘中去
        if (_machineId > 0 && _eventInfoArray.count > 0) {
            [_eventInfoArray enumerateObjectsUsingBlock:^(CSSTrackerEventModel * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
                [self persistCustomEvent:obj];
            }];
            [_eventInfoArray removeAllObjects];
        }
    });
}

#pragma mark - 增

- (void)persistCustomEvent:(CSSTrackerEventModel *)info {
    dispatch_async(_eventIOQueue, ^{
        if (self.machineId <= 0) {
            [_eventInfoArray addObject:info]; // 如果唯一机器码尚未获取到,临时添加到内存缓存中去
            return;
        }
        
        NSError *error;
        NSData *toSave = [info css_serializationToJsonDataWithError:&error];
        if (error) {
            //TODO:错误描述
            return;
        }
        
        _eventFileHandle = [self updateFileHandle:_eventFileHandle directory:_eventDir];
        if (!_eventFileHandle) {
            //TODO:错误描述
            return;
        }
        
        // 数据包装成 '@{},@{},@{}...'
        if (_eventFileHandle.offsetInFile > 0) {
            [_eventFileHandle writeData:[@"," dataUsingEncoding:NSUTF8StringEncoding]];
        }
        [_eventFileHandle writeData:toSave];
    });
}

#pragma mark - 查

- (NSData *)uploadCustomEventsDataWithPath:(NSString *)filePath {
    if (!filePath) return nil;
    __block NSData *archivedData;
    dispatch_sync(_eventIOQueue, ^{
        archivedData = [NSData dataWithContentsOfFile:filePath];
    });
    if (archivedData.length <= 0) return nil;
    
    // 数据封装成 '@[@{},@{},@{}...]'
    NSMutableData *uploadData = [NSMutableData dataWithData:[@"[" dataUsingEncoding:NSUTF8StringEncoding]];
    [uploadData appendData:archivedData];
    [uploadData appendData:[@"]" dataUsingEncoding:NSUTF8StringEncoding]];
    return uploadData;
}

// do not user this method in _eventsIOQueue which will cause dead lock
- (NSString *)nextArchivedCustomEventsPath {
    NSString *path = [self nextArchivedPathForDirectory:_eventDir fileHandle:&_eventFileHandle inQueue:_eventIOQueue];
    return path;
}

// 此处用__strong修饰fileHandle,所以传进来变量的地址应该是instance variable, 这里不用本地变量且采用__autoreleasing的原因是,*filehandle = nil后,外部真实地址并没有nil,导致后面调用handle奔溃
- (NSString *)nextArchivedPathForDirectory:(NSString *)directory fileHandle:(NSFileHandle * __strong *)fileHandle inQueue:(dispatch_queue_t)queue {
    __block NSString *archivedPath;
    dispatch_sync(queue, ^{
        for (NSString *fileName in [_fileManager enumeratorAtPath:directory]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*\\.archive$"];
            if ([predicate evaluateWithObject:fileName]) {
                archivedPath = [NSString stringWithFormat:@"%@/%@", directory, fileName];
            }
        }
        // if no archived file found
        for (NSString *fileName in [_fileManager enumeratorAtPath:directory]) {
            NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^[0-9]+\\.?[0-9]*$"];
            if ([predicate evaluateWithObject:fileName]) {
                if (*fileHandle) {
                    [*fileHandle closeFile];
                    *fileHandle = nil;
                }
                NSError *error;
                archivedPath = [NSString stringWithFormat:@"%@/%@.archive", directory, fileName];
                [_fileManager moveItemAtPath:[NSString stringWithFormat:@"%@/%@", directory, fileName] toPath:archivedPath error:&error];
                if (error) {
                    archivedPath = nil;
                    //TODO:描述错误
                    //                    NSLog(@"archive file %@ fail", fileName);
                    continue;
                }
            }
        }
    });
    return archivedPath;
}

#pragma mark - 删

- (void)clearFile:(NSString *)filePath error:(NSError **)error {
    [_fileManager removeItemAtPath:filePath error:error];
    if (error) {
        //TODO:错误描述
    } else {
        //TODO:成功描述
    }
}

- (void)clearFiles:(NSArray<NSString *> *)filePaths {
    __block NSError *error;
    [filePaths enumerateObjectsUsingBlock:^(NSString * _Nonnull filePath, NSUInteger idx, BOOL * _Nonnull stop) {
        [self clearFile:filePath error:&error];
    }];
}

#pragma mark - Update FileHandle

- (NSFileHandle *)updateFileHandle:(NSFileHandle *)oldFileHandle directory:(NSString *)directory {
    if (oldFileHandle) {
        if (oldFileHandle.offsetInFile < MCTrackerMaxCacheFileSize) {
            return oldFileHandle;
        } else {
            [oldFileHandle closeFile];
            oldFileHandle = nil;
        }
    }
    
    NSString *availableFile;
    for (NSString *fileName in [_fileManager enumeratorAtPath:directory]) {
        NSString *normalFilePattern = @"^[0-9]+\\.?[0-9]*$";
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", normalFilePattern];
        if ([predicate evaluateWithObject:fileName]) {
            NSString *filePath = [NSString stringWithFormat:@"%@/%@", directory, fileName];
            NSFileHandle *readFileHandle = [NSFileHandle fileHandleForReadingAtPath:filePath];
            [readFileHandle seekToEndOfFile];
            if (readFileHandle.offsetInFile < MCTrackerMaxCacheFileSize) {
                availableFile = filePath;
                [readFileHandle closeFile];
                readFileHandle = nil;
                break;
            }
            [readFileHandle closeFile];
            readFileHandle = nil;
        }
    }
    if (!availableFile) {
        availableFile = [NSString stringWithFormat:@"%@/%f", directory, [[NSDate date] timeIntervalSince1970]];
        BOOL success = [_fileManager createFileAtPath:availableFile contents:nil attributes:nil];
        if (!success) {
            //TODO:错误描述
            return nil;
        }
    }
    
    oldFileHandle = [NSFileHandle fileHandleForUpdatingAtPath:availableFile];
    [oldFileHandle seekToEndOfFile];
    
    return oldFileHandle;
}

@end
