//
//  DownloadOperation.h
//  Background_Networking
//
//  Created by wildyao on 14/12/16.
//  Copyright (c) 2014年 Wild Yaoyao. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface DownloadOperation : NSOperation

- (id)initWithURL:(NSURL *)url;

@property (readonly, nonatomic, strong) NSError *error;
@property (nonatomic, strong) NSData *data;
@property (nonatomic, copy) void (^progressCallback)(float);

@end
