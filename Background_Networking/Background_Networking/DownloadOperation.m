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

- (void)start
{
    NSLog(@"current thread is main thread: %d", [NSThread isMainThread]);
    
    NSURLRequest* request = [NSURLRequest requestWithURL:self.url];
    
    self.isExecuting = YES;
    self.isConcurrent = YES;
    self.isFinished = NO;
    
    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
        
        self.isExecuting = YES;
        self.isConcurrent = YES;
        self.isFinished = NO;
        
        self.connection =[[NSURLConnection alloc] initWithRequest:request
                                                         delegate:self
                                                 startImmediately:NO];
        [self.connection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        [self.connection start];
    }];
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
    self.progressCallback(self.buffer.length / (float)self.expectedContentLength);
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
