//
//  DownloadOperation.m
//  Background_Networking
//
//  Created by wildyao on 14/12/16.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import "DownloadOperation.h"

@interface DownloadOperation () <NSURLConnectionDelegate>

@property (nonatomic, strong) NSURL *url;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *buffer;
@property (nonatomic) long long int expectedContentLength;
@property (nonatomic, readwrite) NSError *error;

@property (nonatomic) BOOL isExecuting;
@property (nonatomic) BOOL isConcurrent;
@property (nonatomic) BOOL isFinished;

@end

@implementation DownloadOperation

- (id)initWithURL:(NSURL *)url
{
    self = [super init];
    if (self) {
        self.url = url;
    }
    
    return self;
}

+ (void)networkRequestThreadEntryPoint:(id)__unused object {
    @autoreleasepool {
        [[NSThread currentThread] setName:@"BackgroundNetworking"];
        
        NSRunLoop *runLoop = [NSRunLoop currentRunLoop];
//        [runLoop addPort:[NSMachPort port] forMode:NSDefaultRunLoopMode];
        [runLoop run];
    }
}

+ (NSThread *)networkRequestThread {
    static NSThread *_networkRequestThread = nil;
    static dispatch_once_t oncePredicate;
    dispatch_once(&oncePredicate, ^{
        _networkRequestThread = [[NSThread alloc] initWithTarget:self selector:@selector(networkRequestThreadEntryPoint:) object:nil];
        [_networkRequestThread start];
    });
    
    return _networkRequestThread;
}

- (void)start
{
    NSLog(@"current thread is main thread: %d", [NSThread isMainThread]);
    
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    
//    self.isExecuting = YES;
//    self.isConcurrent = YES;
//    self.isFinished = NO;
    
    
    // way 1
//    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
//    
//        self.isExecuting = YES;
//        self.isConcurrent = YES;
//        self.isFinished = NO;
//        
//        self.connection =[[NSURLConnection alloc] initWithRequest:request
//                                                         delegate:self
//                                                 startImmediately:NO];
//        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//        [self.connection start];
//    }];
    
    
    // way 2
    self.isExecuting = YES;
    self.isConcurrent = YES;
    self.isFinished = NO;
    
    // 后台线程的RunLoop是默认没有启动的。 后台线程的RunLoop没有启动的情况下的现象就是：“代码执行完，线程就结束被回收了”。就像我们简单的程序执行完就退出了。 所以如果我们希望在代码执行完成后还要保留线程等待一些异步的事件时，比如NSURLConnection和NSTimer， 就需要手动启动后台线程的RunLoop。 启动RunLoop，我们需要设定RunLoop的模式，我们可以设置 NSDefaultRunLoopMode。 那默认就是监听所有时间源：
    // (1)
//    self.connection =[[NSURLConnection alloc] initWithRequest:request
//                                                     delegate:self
//                                             startImmediately:NO];
//    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    // Core Foundation
//    CFRunLoopRun();   // 使用CFRunLoopStop(CFRunLoopGetCurrent());来停止或者所有事件源或者timer移除
    
    
    // (2)
//    self.connection =[[NSURLConnection alloc] initWithRequest:request
//                                                     delegate:self
//                                             startImmediately:NO];
//
//    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//    [self.connection start];
//    [[NSRunLoop currentRunLoop] run];
    
    [self performSelector:@selector(operationDidStart) onThread:[[self class] networkRequestThread] withObject:nil waitUntilDone:NO modes:@[NSRunLoopCommonModes]];
}

- (void)operationDidStart
{
    NSURLRequest *request = [NSURLRequest requestWithURL:self.url];
    self.connection =[[NSURLConnection alloc] initWithRequest:request
                                                     delegate:self
                                             startImmediately:NO];
    
    [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
    [self.connection start];
}

- (void)cancel
{
    [super cancel];
    
    [self.connection cancel];
    
    self.isFinished = YES;
    self.isExecuting = NO;
}

#pragma mark - Setters

- (void)setIsExecuting:(BOOL)isExecuting
{
    [self willChangeValueForKey:@"isExecuting"];
    _isExecuting = isExecuting;
    [self didChangeValueForKey:@"isExecuting"];
}

- (void)setIsFinished:(BOOL)isFinished
{
    [self willChangeValueForKey:@"isFinished"];
    _isFinished = isFinished;
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark NSURLConnectionDelegate

- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response
{
    return request;
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.expectedContentLength = response.expectedContentLength;
    self.buffer = [NSMutableData data];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.buffer appendData:data];
    // 调用block
    if (self.progressCallback) {
        self.progressCallback(self.buffer.length / (float)self.expectedContentLength);
    }
}

- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse
{
    return cachedResponse;
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    self.data = self.buffer;
    self.buffer = nil;
    
    self.isExecuting = NO;
    self.isFinished = YES;
}

- (void)connection:(NSURLConnection*)connection didFailWithError:(NSError*)error
{
    self.error = error;
    
    self.isExecuting = NO;
    self.isFinished = YES;
}

@end
