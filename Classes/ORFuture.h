//
//  ORFuture.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/20.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>


@interface ORFuture : NSObject

+ (instancetype)future:(void (^)(void))block;

- (void)arrived:(void(^)())block;

@end


#define future(method) [ORFuture future:^{method}]
