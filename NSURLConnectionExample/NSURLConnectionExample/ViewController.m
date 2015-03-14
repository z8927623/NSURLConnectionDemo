//
//  ViewController.m
//  NSURLConnectionExample
//
//  Created by wildyao on 14/12/19.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import "ViewController.h"
#import "OperationDownloader.h"
#import "ThreadDownloader.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIButton *button = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [button setTitle:@"Download" forState:UIControlStateNormal];
    button.frame = CGRectMake(100, 100, 100, 30);
    [button addTarget:self action:@selector(toggleButton) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:button];
}

- (void)toggleButton
{
//    NSString *URLString = @"http://ww3.sinaimg.cn/bmiddle/72953575jw1emks8w24s5j20xc18ggx8.jpg";
    NSString *URLString = @"http://c.hiphotos.baidu.com/image/pic/item/5fdf8db1cb13495453bb9e33554e9258d1094a3b.jpg";
    
    // 1 OperationDownloader
//    OperationDownloader *downloader = [OperationDownloader downloadWithURL:[NSURL URLWithString:URLString] timeoutInterval:15 success:^(id responseData) {
//        
//        NSLog(@"get data size: %lu", [(NSData *)responseData length]);
//        NSLog(@"success block in main thread?: %d", [NSThread isMainThread]);
//        
//    } failure:^(NSError *error) {
//        
//        NSLog(@"failure block in main thread?: %d", [NSThread isMainThread]);
//    }];
//    
//    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
//    [queue addOperation:downloader];

    
    // 2 ThreadDownloader
    ThreadDownloader *downloader = [ThreadDownloader downloadWithURL:[NSURL URLWithString:URLString] timeoutInterval:15 success:^(id responseData) {
        
        NSLog(@"get data size: %lu", [(NSData *)responseData length]);
        NSLog(@"success block in main thread?: %d", [NSThread isMainThread]);

    } failure:^(NSError *error) {
        NSLog(@"failure block in main thread?: %d", [NSThread isMainThread]);
    }];
    
    NSLog(@"started downloader: %@", downloader.URL.absoluteString);

}

@end
