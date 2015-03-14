//
//  ThreadDownloader.m
//  NSURLConnectionExample
//
//  Created by wildyao on 14/12/25.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import "ThreadDownloader.h"

@interface ThreadDownloader ()

@property (nonatomic, readwrite, strong) NSURL *URL;
@property (nonatomic, readwrite, strong) NSMutableData *responseData;
@property (nonatomic, readwrite, strong) NSURLConnection *connection;
@property (nonatomic, readwrite, assign) NSTimeInterval timeoutInterval;
@property (nonatomic, readwrite, copy) void (^downloaderCompletedBlock)();
@property (nonatomic, readwrite, strong) NSError *error;

@end

@implementation ThreadDownloader

+ (void)networkEntry:(id)__unused object
{
    @autoreleasepool {
        NSLog(@"1 current thread: %@  %d", [NSThread currentThread], [NSThread isMainThread]);
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
        // 向当前runloop添加事件源
        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

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
    NSLog(@"2 current thread: %@  %d", [NSThread currentThread], [NSThread isMainThread]);
    NSLog(@"3 current run loop is main run loop?: %d", [NSRunLoop currentRunLoop] == [NSRunLoop mainRunLoop]);
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:self.URL cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:self.timeoutInterval];
    [request setHTTPMethod:@"GET"];

    // 1
    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
 
    // 2
    // (1)
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
//    // 向当前runloop添加事件源
//    [currentRunLoop addPort:[NSPort port] forMode:NSDefaultRunLoopMode];
//    [self.connection scheduleInRunLoop:currentRunLoop forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    [currentRunLoop run];
    
    // (2)
//    self.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:NO];
//    NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
//    [self.connection scheduleInRunLoop:currentRunLoop forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    CFRunLoopRun();
}

- (void)cancel
{
    if (self.connection) {
        [self.connection cancel];
        self.connection = nil;
    }
}

+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
              failure:(void (^)(NSError *error))failure
{
    NSLog(@"create downloader in main thread?: %d", [NSThread isMainThread]);
    
    ThreadDownloader *downloader = [[ThreadDownloader alloc] init];
    downloader.URL = URL;
    downloader.timeoutInterval = timeoutInterval;
    [downloader setCompletionBlockWithSuccess:success failure:failure];
    
    // start in main thread
//    [downloader performSelectorOnMainThread:@selector(start) withObject:nil waitUntilDone:NO];
    // GCD start in main thread
//    dispatch_async(dispatch_get_main_queue(), ^{
//        [downloader start];
//    });
    // NSOperationQueue start in main thread
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//        [downloader start];
//    }];
    
    // start on GCD global queue
//    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        [downloader start];
//    });
    
    
    // 1. start in another thread. AFNetworking way
    [downloader performSelector:@selector(start) onThread:[[self class] networkThread] withObject:nil waitUntilDone:NO];
    
    // 2. start in another thread. normal way
//    NSThread *newThread = [[NSThread alloc] initWithTarget:downloader selector:@selector(start) object:nil];
//    [newThread start];
    
    return downloader;
}

- (void)setCompletionBlockWithSuccess:(void (^)(id responseData))success
                              failure:(void (^)(NSError *error))failure
{
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
    NSLog(@"connectionDidFinishLoading in main thread?: %d", [NSThread isMainThread]);
    
    self.connection = nil;
    self.downloaderCompletedBlock();
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    self.error = error;
    self.connection = nil;
    self.responseData = nil;
    self.downloaderCompletedBlock();
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return nil;
}

@end