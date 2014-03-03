//
//  ORRelation+private.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/14.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORRelation.h"

@class ORDeferredQuery, OREntity;
@interface ORRelation (private)

- (NSArray *)deferredSync;
@end
