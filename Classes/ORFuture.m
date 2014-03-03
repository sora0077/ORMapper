//
//  ORFuture.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/20.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORFuture.h"
#import "ORDatabase.h"

@implementation ORFuture
{
    void (^_block)(void);
}


+ (instancetype)future:(void (^)(void))block
{
    ORFuture *future = [[self alloc] init];
    
    future->_block = [block copy];
    
    return future;
}

- (void)arrived:(void (^)())block
{
    dispatch_async(ormapper_queue(), ^{
        _block();
        
        block();
    });
}

@end
