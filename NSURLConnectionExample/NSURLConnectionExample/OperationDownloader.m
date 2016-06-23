//
//  OperationDownloader.m
//  NSURLConnectionExample
//
//  Created by wildyao on 14/12/22.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import "OperationDownloader.h"

@interface OperationDownloader ()
{
    BOOL finished;
    BOOL executing;
}

@property (nonatomic, readwrite, strong) NSURL *URL;
@property (nonatomic, readwrite, strong) NSMutableData *responseData;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, readwrite, copy) void (^downloaderCompletedBlock)();
@property (nonatomic, readwrite, strong) NSError *error;
@property (nonatomic, readwrite, strong) NSRecursiveLock *lock;   // 递归锁

@end

@implementation OperationDownloader

- (id)init
{
    self = [super init];
    if (self) {
        self.lock = [[NSRecursiveLock alloc] init];
        self.lock.name = @"com.recursive.lock";
    }
    return self;
}

+ (void)networkEntry:(id)__unused object
{
    @autoreleasepool {
        NSLog(@"1 current thread is main thread: %d", [NSThread isMainThread]);
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        // 添加port事件源
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

// 独立开启线程，并启用其runloop
+ (NSThread *)networkThread
{
    static NSThread *_networkThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkEntry:) object:nil];
        [_networkThread start];
    });
    
    return _networkThread;
}

- (void)start
{
    [self.lock lock];
    
    NSLog(@"2 current thread is main thread: %d", [NSThread isMainThread]);
    
    if (self.isCancelled) {
        [self willChangeValueForKey:@"isFinished"];
        finished = YES;
        [self didChangeValueForKey:@"isFinished"];
        return;
    }

    [self willChangeValueForKey:@"isExecuting"];
    
    // If you are performing this on a background thread, the thread is probably exiting before the delegates can be called.
    // 1. http://stackoverflow.com/questions/9223537/asynchronous-nsurlconnection-with-nsoperation
    // 2. http://cocoaintheshell.com/2011/04/nsurlconnection-synchronous-asynchronous/
//    [self operationDidStart];
    
    // AFNetworking way
//    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkThread] withObject:nil waitUntilDone:NO];
    
    
//    [self.lock lock];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
    [request setHTTPMethod:@"GET"];
    
    // way 1  mainRunLoop
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
    
    // way 2
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    [[NSRunLoop currentRunLoop] run];
    
        // way 3
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    CFRunLoopRun();
    
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
    CFRunLoopRun();
//    [[NSRunLoop currentRunLoop] run];
    
    NSLog(@"thread: %@", [NSThread currentThread]);
    
    [self.lock unlock];

    executing = YES;
    
    [self didChangeValueForKey:@"isExecuting"];
    
    [self.lock unlock];
}

- (void)dealloc {
    NSLog(@"dealloc");
}

- (void)cancel
{
    [self.lock lock];
    
    [super cancel];
    
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
    
    [self.lock unlock];
}


- (BOOL)isConcurrent
{
    return YES;
}

- (BOOL)isFinished
{
    return finished;
}

- (BOOL)isExecuting
{
    return executing;
}

+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
              failure:(void (^)(NSError *error))failure
{
    NSLog(@"create downloader in main thread?: %d", [NSThread isMainThread]);
    
    OperationDownloader *downloader = [[OperationDownloader alloc] init];
    downloader.URL = URL;
    downloader.timeoutInterval = timeoutInterval;
    [downloader setCompletionBlockWithSuccess:success failure:failure];
    
    return downloader;
}

- (void)setCompletionBlockWithSuccess:(void (^)(id responseData))success
                              failure:(void (^)(NSError *error))failure
{
    [self.lock lock];
    
    __weak typeof(self) weakSelf = self;
    // 定义block
    self.downloaderCompletedBlock = ^{
        if (weakSelf.error) {
            if (failure) {
                failure(weakSelf.error);
            }
        } else {
            if (success) {
                success(weakSelf.responseData);
            }
        }
    };
    
    [self.lock unlock];
}

- (void)operationDidStart
{
//    [self.lock lock];
//    
//    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
//    [request setHTTPMethod:@"GET"];
//    
//    // way 1  mainRunLoop
////    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
////    [self.connection scheduleInRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
////    [self.connection start];
//    
//    // way 2  currentRunLoop
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    [[NSRunLoop currentRunLoop] run];
//
////    // way 3  using AFNetworking way
////    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
////    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
////    [self.connection start];
////    CFRunLoopRun();
//    
//    [self.lock unlock];
}

- (void)operationDidFinish
{
    [self.lock lock];
    
    [self willChangeValueForKey:@"isFinished"];
    [self willChangeValueForKey:@"isExecuting"];

    executing = NO;
    finished = YES;
    
    [self didChangeValueForKey:@"isFinished"];
    [self didChangeValueForKey:@"isExecuting"];
    
    [self.lock unlock];
}

#pragma mark - NSURLConnectionDelegate

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    if (![response respondsToSelector:@selector(statusCode)] || [((NSHTTPURLResponse *)response) statusCode] < 400) {
        NSInteger expectedSize = response.expectedContentLength > 0 ? (NSInteger)response.expectedContentLength : 0;
        self.responseData = [[NSMutableData alloc] initWithCapacity:expectedSize];
    } else {
        [connection cancel];
        
        NSError *error = [[NSError alloc] initWithDomain:NSURLErrorDomain code:[(NSHTTPURLResponse *)response statusCode] userInfo:nil];
        self.error = error;
        self.connection = nil;
        self.responseData = nil;
        self.downloaderCompletedBlock();
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.responseData appendData:data];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"hehe thread: %@", [NSThread currentThread]);
    
    NSLog(@"connectionDidFinishLoading in main thread?: %d", [NSThread isMainThread]);
    
    self.connection = nil;
    self.downloaderCompletedBlock();
    
    [self operationDidFinish];
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    self.connection = nil;
    self.responseData = nil;
    self.downloaderCompletedBlock();
    
    [self operationDidFinish];
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

@end
