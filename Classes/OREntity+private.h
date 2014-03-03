//
//  OREntity+private.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/09.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "OREntity.h"

@class ORRelation;
@interface OREntity (private)

- (id)initWithTable:(ORTable *)table values:(NSDictionary *)values exists:(BOOL)exists;

- (void)addRelation:(ORRelation *)relation;

@end
