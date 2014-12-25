//
//  ThreadDownloader.h
//  NSURLConnectionExample
//
//  Created by wildyao on 14/12/25.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ThreadDownloader : NSObject

@property (nonatomic, readonly, strong) NSURL *URL;
@property (nonatomic, readonly, strong) NSMutableData *responseData;

+ (id)downloadWithURL:(NSURL *)URL
      timeoutInterval:(NSTimeInterval)timeoutInterval
              success:(void (^)(id responseData))success
                failure:(void (^)(NSError *error))failure;

@end
