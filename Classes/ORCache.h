//
//  ORCache.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/06.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORTable, OREntity;
@interface ORCache : NSObject

+ (ORTable *)tableWithName:(NSString *)name;

+ (OREntity *)entityWithId:(id)value;
+ (void)addEntity:(OREntity *)entity;
+ (void)removeEntity:(OREntity *)entity;

@end
