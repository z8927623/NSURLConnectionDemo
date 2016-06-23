//
//  AppDelegate.m
//  Background_Networking
//
//  Created by wildyao on 14/12/16.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import "AppDelegate.h"
#import "DownloadOperation.h"

@interface AppDelegate ()


@property (nonatomic, strong) DownloadOperation *downloadOperation;

@property (nonatomic, strong) DownloadOperation *downloadOperation2;

@property (nonatomic, strong) DownloadOperation *downloadOperation3;

@end

@implementation AppDelegate

@synthesize downloadOperation = _downloadOperation;

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.window.backgroundColor = [UIColor whiteColor];
    
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    operationQueue.maxConcurrentOperationCount = 3;
    
    _downloadOperation = [[DownloadOperation alloc] initWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/tm/TM2013Preview1.exe"]];
    _downloadOperation2 = [[DownloadOperation alloc] initWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/tm/TM2013Preview1.exe"]];
    _downloadOperation3 = [[DownloadOperation alloc] initWithURL:[NSURL URLWithString:@"http://dldir1.qq.com/qqfile/tm/TM2013Preview1.exe"]];
    [operationQueue addOperation:_downloadOperation];
    [operationQueue addOperation:_downloadOperation2];
    [operationQueue addOperation:_downloadOperation3];
//    [operationQueue addOperationWithBlock:^{
//         NSLog(@"next operation");
//    }];
    
    // start会运行在调用他的线程上
//    [_downloadOperation start];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    button.frame = CGRectMake((self.window.bounds.size.width-300)/2, 10, 300, 80);
    [self.window addSubview:button];
    [button setTitle:@"Cancel" forState:UIControlStateNormal];
    [button addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    
    // 完成或取消时候要执行的block
    _downloadOperation.completionBlock = ^{
        NSLog(@"here");
        NSLog(@"thread: %@", @([NSThread isMainThread]));
        dispatch_async(dispatch_get_main_queue(), ^{
            button.userInteractionEnabled = NO;
            NSLog(@"thread: %@", @([NSThread isMainThread]));
        });
    };
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    progressView.progress = 0;
    progressView.frame = CGRectMake(0, 120, self.window.frame.size.width, 20);
    [self.window addSubview:progressView];
    // 定义block
    _downloadOperation.progressCallback = ^(float progress) {
        progressView.progress = progress;
    };
    
    [self.window makeKeyAndVisible];
    
    return YES;
}


- (void)cancel:(id)sender
{
    [_downloadOperation cancel];
}

- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
