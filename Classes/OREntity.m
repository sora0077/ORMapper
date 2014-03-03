//
//  OREntity.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "OREntity.h"
#import "OREntity+private.h"
#import "ORTable.h"
#import "ORTable+private.h"
#import "ORCursor.h"
#import "ORCache.h"
#import "ORDatabase.h"

#import "ORRelation.h"
#import "ORRelation+private.h"

#import "ORMacros.h"

#import <objc/objc-runtime.h>

id accessorGetter(id self, SEL _cmd)
{
    NSString *method = NSStringFromSelector(_cmd);
    return [self objectForKey:method];
}

void accessorSetter(id self, SEL _cmd, NSObject* newValue)
{
    NSString *method = NSStringFromSelector(_cmd);

    // remove set
    NSString *anID = [[[method stringByReplacingCharactersInRange:NSMakeRange(0, 3) withString:@""] lowercaseString] stringByReplacingOccurrencesOfString:@":" withString:@""];

    [self setObject:newValue forKey:anID];
}

@implementation OREntity
{
    ORTable *_table;
    NSMutableDictionary *_values, *_changes;
    NSMutableArray *_relations;
    BOOL _exists;
}

- (id)init
{
    return [self initWithValues:nil];
}

- (id)initWithValues:(NSDictionary *)values
{
    ORTable *table = [ORCache tableWithName:[[self class] tableName]];
    return [self initWithTable:table values:values];
}

- (id)initWithTable:(ORTable *)table
{
    return [self initWithTable:table values:nil];
}

- (id)initWithTable:(ORTable *)table values:(NSDictionary *)values
{
    return [self initWithTable:table values:values exists:NO];
}

- (id)initWithTable:(ORTable *)table values:(NSDictionary *)values exists:(BOOL)exists
{
    self = [super init];
    if (self) {
        _table = table;
        _values = (values ?: @{}).mutableCopy;
        _changes = @{}.mutableCopy;
        _exists = exists;

        [self awake];

        if (exists) {
            [ORCache addEntity:self];
            [self didAwakeFromFetch];
        }
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    BOOL ret = [super isEqual:object];
    if (ret == NO) {
        if (![self isKindOfClass:[object class]]) {
            return NO;
        }
        ret = [self.uuid isEqualToString:[object uuid]];
    }
    return ret;
}

+ (BOOL)resolveInstanceMethod:(SEL)aSEL
{
    NSString *method = NSStringFromSelector(aSEL);

    if ([method hasPrefix:@"set"]) {
        class_addMethod([self class], aSEL, (IMP) accessorSetter, "v@:@");
        return YES;
    } else {
        class_addMethod([self class], aSEL, (IMP) accessorGetter, "@@:");
        return YES;
    }
    return [super resolveInstanceMethod:aSEL];
}

+ (NSString *)tableName
{
    NSParameterAssert(nil);
    return nil;
}

+ (ORTable *)table
{
    return [ORCache tableWithName:[self tableName]];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"%@ %@", [super description], _values];
}

//- (BOOL)isEqual:(id)object
//{
//
//}

- (NSString *)uuid
{
    return [self objectForKey:self.table.primarykey];
}

- (ORTable *)table
{
    return _table;
}

- (BOOL)exists
{
    return _exists;
}

- (void)awake {}
- (void)willAwakeFromFetch {}
- (void)didAwakeFromFetch {}
- (void)willAwakeFromInsert {}
- (void)didAwakeFromInsert {}

- (BOOL)save
{
    if (self.exists) {
        return [self update];
    }
    return [self insert];
}

- (BOOL)insert
{
    NSParameterAssert(!self.uuid);
    NSParameterAssert(!self.exists);

    [self willAwakeFromInsert];

    if (self.table.primarykey) {
        NSUUID *uuid = [NSUUID UUID];
        [self setObject:uuid.UUIDString forKey:self.table.primarykey];
    }

    for (ORRelation *relation in _relations) {
        if ([relation isKindOfClass:[ORRelationBelongs class]]) {
            [relation sync];
        }
    }


    NSArray *columns = self.table.columns;
    NSString *sql = [NSString stringWithFormat:@"INSERT INTO <table> (%@) VALUES (:%@)", [columns componentsJoinedByString:@","], [columns componentsJoinedByString:@",:"]];
    [_values addEntriesFromDictionary:_changes];
    NSDictionary *values = [_values dictionaryWithValuesForKeys:columns];
    if (values.count == 0) return NO;

    [ORDatabase inTransaction:^{
        _exists = [self.table executeSQL:sql args:values];
        if (_exists) {
            [ORCache addEntity:self];
            [_changes removeAllObjects];
        } else {
            if (self.table.primarykey) {
                [self removeObjectForKey:self.table.primarykey];
            }

            @throw [NSException exceptionWithName:@"aaa" reason:@"" userInfo:nil];
        }

        for (ORRelation *relation in _relations) {
            [relation sync];
        }
    }];

    return _exists;
}

- (BOOL)update
{
    NSParameterAssert(self.uuid);
    NSParameterAssert(self.exists);


    __block BOOL ret = NO;
    [ORDatabase inTransaction:^{
        for (ORRelation *relation in _relations) {
            [relation sync];
        }
        if (_changes.count == 0) {
            ret = YES;
            return;
        }


        NSArray *columns = _table.columns;
        NSMutableDictionary *values = [_changes dictionaryWithValuesForKeys:columns].mutableCopy;
        [_changes removeAllObjects];

        NSMutableArray *fields = @[].mutableCopy;
        for (NSString *column in columns) {
            if (values[column] && values[column] != [NSNull null]) {
                [fields addObject:[NSString stringWithFormat:@"%@=:%@", column, column]];
            } else {
                [values removeObjectForKey:column];
            }
        }

        NSString *sql = [NSString stringWithFormat:@"UPDATE <table> SET %@ WHERE <primarykey>=%@", [fields componentsJoinedByString:@","], self.uuid];
        ret = [_table executeSQL:sql args:values];
        if (!ret) {
            @throw [NSException exceptionWithName:@"aaa" reason:@"" userInfo:nil];
        }
    }];

    return ret;
}

- (BOOL)delete
{
    NSParameterAssert(self.uuid);

    __block BOOL ret = NO;
    [ORDatabase inTransaction:^{
        for (ORRelation *relation in _relations) {
            [relation delete];
        }

        ret = [[self class] deleteBy:@"<primarykey>" value:self.uuid];
        if (!ret) {
            @throw [NSException exceptionWithName:@"aaa" reason:@"" userInfo:nil];
        }
    }];

    if (ret) {
        NSDictionary *userInfo;
        NSNotification *notification = [NSNotification notificationWithName:@"OREntityOnDeleteNotification"
                                                                     object:self
                                                                   userInfo:userInfo];
        [[NSNotificationCenter defaultCenter] postNotification:notification];

        [ORCache removeEntity:self];

        [_values removeAllObjects];
        [_changes removeAllObjects];
    }

    return ret;
}

- (id)relationKey:(NSString *)key
{
    return @[self, key];
}

+ (NSArray *)findAll
{
    ORTable *table = [ORCache tableWithName:[[self class] tableName]];
    return [table findSQL:@"SELECT * FROM <table>" args:nil process:^NSArray *(ORCursor *cursor) {
        NSMutableArray *results = @[].mutableCopy;
        while (cursor.next) {
            NSDictionary *values = cursor.result;
            id pkValue = values[table.primarykey];
            OREntity *entity = [ORCache entityWithId:pkValue];
            if (entity == nil) {
                entity = [[[self class] alloc] initWithTable:table values:values exists:YES];
            }
            [results addObject:entity];
        }
        return results.count ? results : nil;
    }];
}

+ (id<OREntity>)findBy:(NSString *)keyPath value:(id)value
{
    NSParameterAssert(value);
    ORTable *table = [ORCache tableWithName:[[self class] tableName]];
    NSParameterAssert([table.columns containsObject:keyPath]);
    NSString *sql = [NSString stringWithFormat:@"SELECT * FROM <table> WHERE %@=:key LIMIT 1", keyPath];
    return [table findSQL:sql args:@{@"key": value} process:^OREntity *(ORCursor *cursor) {
        OREntity *entity = nil;
        if (cursor.next) {
            NSDictionary *values = cursor.result;
            id pkValue = values[table.primarykey];
            entity = [ORCache entityWithId:pkValue];
            if (entity == nil) {
                entity = [[[self class] alloc] initWithTable:table values:values exists:YES];
            }
        }
        return entity;
    }];
}

+ (BOOL)deleteBy:(NSString *)keyPath value:(id)value
{
    NSParameterAssert(value);
    ORTable *table = [ORCache tableWithName:[[self class] tableName]];
//    NSParameterAssert([table.columns containsObject:keyPath]);
    NSString *sql = [NSString stringWithFormat:@"DELETE FROM <table> WHERE %@=:key", keyPath];

    return [table executeSQL:sql args:@{@"key": value}];
}

- (id)valueForKey:(NSString *)key
{
    id value = [self objectForKey:key];
    return value;
}

- (void)setValue:(id)value forKey:(NSString *)key
{
    if ([self.table hasColumn:key]) {
        [self setObject:value forKey:key];
    }
}



- (id)objectForKey:(id)aKey
{
    return [_values objectForKey:aKey];
}

- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey
{
    if ([self.table hasColumn:(id)aKey]) {
        [_changes setObject:anObject forKey:aKey];
    }
    [_values setObject:anObject forKey:aKey];
}

- (void)removeObjectForKey:(id)aKey
{
    if ([self.table hasColumn:(id)aKey]) {
        [_changes setObject:[NSNull null] forKey:aKey];
    }
    [_values removeObjectForKey:aKey];
}

- (id)objectForKeyedSubscript:(id)key
{
    return [self objectForKey:key];
}

- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key
{
    if (obj) {
        [self setObject:obj forKey:key];
    } else {
        [self removeObjectForKey:key];
    }
}

- (void)addRelation:(ORRelation *)relation
{
    if (_relations == nil) {
        _relations = @[].mutableCopy;
    }
    [_relations addObject:relation];
}

@end

@implementation NSArray (OREntity)

- (BOOL)save
{
    NSException *exception;
    [ORDatabase inTransaction:^{
        for (OREntity *entity in self) {
            [entity save];
        }
    } exception:&exception];
    return exception == nil;
}

- (BOOL)delete
{
    NSException *exception;
    [ORDatabase inTransaction:^{
        for (OREntity *entity in self) {
            [entity delete];
        }
    } exception:&exception];
    return exception == nil;
}

@end
