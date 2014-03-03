//
//  ORCache.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/06.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORCache.h"
#import "ORTable.h"
#import "ORTable+private.h"
#import "ORDatabase.h"
#import "OREntity.h"

@implementation ORCache
{
    NSMutableDictionary *_tables;
    NSMutableDictionary *_entities;
}

- (id)init
{
    self = [super init];
    if (self) {
        _tables = @{}.mutableCopy;
        _entities = @{}.mutableCopy;
    }
    return self;
}

+ (instancetype)sharedCache
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (ORTable *)tableWithName:(NSString *)name
{
    ORCache *cache = [self sharedCache];
    ORTable *table = cache->_tables[name];
    if (table == nil) {
        table = [[ORTable alloc] initWithName:name];
        cache->_tables[name] = table;
        [table setup];
    }
    return table;
}

+ (OREntity *)entityWithId:(id)value
{
    if (value == nil) return nil;
//    NSString *key = [NSString stringWithFormat:@"%@::%@", table.name, [value description]];

    ORCache *cache = [self sharedCache];
    return cache->_entities[value];
}

+ (void)addEntity:(OREntity *)entity
{
    ORCache *cache = [self sharedCache];

    id value = entity.uuid;
    if (value == nil) return;
//    NSString *key = [NSString stringWithFormat:@"%@::%@", entity.table.name, [value description]];

    if (cache->_entities[value] == nil) {
        cache->_entities[value] = entity;
    }
}

+ (void)removeEntity:(OREntity *)entity
{
    ORCache *cache = [self sharedCache];
    id value = entity.uuid;
    if (value == nil) return;
    [cache->_entities removeObjectForKey:value];
}

@end
