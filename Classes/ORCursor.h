//
//  ORCursor.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/07.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ORCursor : NSObject <NSFastEnumeration>

- (BOOL)next;
- (NSDictionary *)result;
- (void)close;

- (NSArray *)map:(id (^)(NSDictionary *result, BOOL *cancel))block;

@end
