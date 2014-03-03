//
//  ORRelation.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORRelation.h"
#import "ORRelation+private.h"
#import "ORTable.h"
#import "OREntity.h"
#import "OREntity+private.h"
#import "ORCursor.h"
#import "ORCache.h"
#import "ORRelation.h"

#import "ORMacros.h"

#import <STDeferred/STDeferred.h>

@interface ORRelation ()

@property (nonatomic, readwrite) ORRelationType type;
@property (nonatomic, readonly) ORTable *foreignTable;
@property (nonatomic, readonly) NSString *throughUsingKey, *throughOwnerKey;
@property (nonatomic, readonly) Class foreignClass, throughClass;
@end

@implementation ORRelation
{
    ORRelationType _type;
    __weak OREntity *_entity;
    ORTable *_foreignTable;
    NSString *_throughUsingKey, *_throughOwnerKey;
    Class _foreignClass;
}

+ (instancetype)relationWithEntity:(OREntity *)entity forKey:(NSString *)inKey
{
    ORRelation *relation = [[self alloc] init];
    relation->_entity = entity;
    relation->_throughOwnerKey = inKey;

    return relation;
}

- (ORRelationBelongs *)belongs:(Class)entityClass
{
    return [[ORRelationBelongs alloc] initWithRelation:self foreignClass:entityClass];
}

- (ORRelationHasMany *)hasMany:(Class)entityClass
{
    return [self hasMany:entityClass forKey:nil through:Nil];
}

- (ORRelationHasMany *)hasMany:(Class)entityClass forKey:(NSString *)usingKey through:(__unsafe_unretained Class)throughClass
{
    return [[ORRelationHasMany alloc] initWithRelation:self foreignClass:entityClass through:throughClass using:usingKey];
}

- (id)initWithRelation:(ORRelation *)relation foreignClass:(Class)foreignClass
{
    return [self initWithRelation:relation foreignClass:foreignClass through:Nil using:nil];
}

- (id)initWithRelation:(ORRelation *)relation foreignClass:(Class)foreignClass through:(Class)throughClass using:(NSString *)usingKey
{
    self = [super init];
    if (self) {
        _entity = relation->_entity;
        _foreignClass = foreignClass;
        _foreignTable = [foreignClass table];

        _throughClass = throughClass;
        _throughUsingKey = usingKey;
        _throughOwnerKey = relation->_throughOwnerKey;

        [_entity addRelation:self];
    }
    return self;
}

- (void)update {}

@end

@implementation ORRelationBelongs
{
    OREntity *_ref;
    NSMapTable
}

- (id)initWithRelation:(ORRelation *)relation foreignClass:(Class)foreignClass
{
    self = [super initWithRelation:relation foreignClass:foreignClass];
    if (self) {
        self.type = ORRelationTypeBelongsTo;

    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)onDeleteNotification:(NSNotification *)notification
{
    self.ref = nil;
}

- (OREntity *)ref
{
    return _ref;
}

- (void)setRef:(OREntity *)ref
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    if (ref.exists) {
        id uuid = [ref objectForKey:ref.table.primarykey];
        [self.entity setObject:uuid forKey:self.throughOwnerKey];

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(onDeleteNotification:)
                                                     name:@"OREntityOnDeleteNotification"
                                                   object:ref];
    }
    _ref = ref;
}

- (BOOL)fetch
{
    if (!self.entity.exists) return NO;

    ORTable *table = self.foreignTable;
    NSString *foreignKey = [self.entity objectForKey:self.throughOwnerKey];
    NSString *sql = [NSString stringWithFormat:@"SELECT <table>.* FROM <table> WHERE %@=:foreignKey LIMIT 1", table.primarykey];

    self.ref = [table findSQL:sql args:@{@"foreignKey": foreignKey} process:^id(ORCursor *cursor) {
        OREntity *entity = nil;
        if (cursor.next) {
            NSDictionary *values = cursor.result;
            id pkValue = values[table.primarykey];
            entity = [ORCache entityWithId:pkValue];
            if (entity == nil) {
                entity = [[self.foreignClass alloc] initWithTable:table values:values exists:YES];
            }
        }
        return entity;
    }];

    return YES;
}

- (BOOL)sync
{
    if (!self.entity.exists) return NO;

    if (_ref && !_ref.exists) {
        [_ref save];
    }
    if (_ref) {

        id primarykey = [_ref objectForKey:_ref.table.primarykey];
        id ownerValue = [self.entity objectForKey:self.throughOwnerKey];
        if (![primarykey isEqual:ownerValue]) {
            [self.entity setObject:primarykey forKey:self.throughOwnerKey];
            //        [self.entity save];
        }
    }

    return YES;
}

- (BOOL)delete
{
    self.ref = nil;
    return YES;
}

@end

@implementation ORRelationHasMany
{
    NSMutableArray *_ref;
    BOOL _dirty;
}

- (id)initWithRelation:(ORRelation *)relation foreignClass:(Class)foreignClass through:(Class)throughClass using:(NSString *)usingKey
{
    self = [super initWithRelation:relation foreignClass:foreignClass through:throughClass using:usingKey];
    if (self) {
        self.type = ORRelationTypeHasMany;
    }
    return self;
}

- (NSArray *)ref
{
    return _ref;
}

- (void)setRef:(NSArray *)ref
{
    _dirty = YES;
    _ref = ref.mutableCopy;
}

- (NSUInteger)count
{
    return _ref.count;
}

- (void)add:(OREntity *)entity
{
    if (_ref == nil) {
        [self fetch];
    }
    if (_ref && ![_ref containsObject:entity]) {
        _dirty = YES;
        [_ref addObject:entity];
    }
}

- (void)remove:(OREntity *)entity
{
    if (_ref == nil) {
        [self fetch];
    }
    if (_ref && ![_ref containsObject:entity]) {
        _dirty = YES;
        [_ref removeObject:entity];
    }
}

- (BOOL)fetch
{
    if (!self.entity.exists) return NO;
    if (self.throughClass) {
        ORTable *table = [self.foreignClass table];
        ORTable *join = [self.throughClass table];

        NSString *joinKey = [join foreignKeyFrom:self.throughUsingKey];
        NSString *whereKey = [join foreignKeyFrom:self.throughOwnerKey];
//        @"SELECT <table>.* FROM <table> LEFT JOIN <join1> ON <table>.<join1_key>=<join1>.<using_key> WHERE <join1>.<owner_key>=:where_key"
        NSString *sql = [NSString stringWithFormat:@"SELECT <table>.* FROM <table> LEFT JOIN %@ ON <table>.%@=%@.%@ WHERE %@.%@=:%@", join.name, joinKey, join.name, self.throughUsingKey, join.name, self.throughOwnerKey, whereKey];
        _ref = [table findSQL:sql args:@{whereKey: [self.entity objectForKey:whereKey]} process:^id(ORCursor *cursor) {
            NSMutableArray *items = @[].mutableCopy;
            while (cursor.next) {
                OREntity *entity = [[self.foreignClass alloc] initWithTable:table values:cursor.result exists:YES];
                [items addObject:entity];
            }
            return items;
        }];
    }
    _dirty = NO;
    return YES;
}

- (BOOL)sync
{
    if (!_dirty) return YES;
    if (!self.entity.exists) {
        [self.entity save];
    }
    
    // Remove all temporary table entity
    ORTable *join = [self.throughClass table];
    NSString *whereKey = self.entity[[join foreignKeyFrom:self.throughOwnerKey]];
    [self.throughClass deleteBy:self.throughOwnerKey value:whereKey];

    for (OREntity *entity in _ref) {
        [entity save];

        ORTable *table = [self.throughClass table];
        NSString *ownerKey = [table foreignKeyFrom:self.throughOwnerKey];
        NSString *usingKey = [table foreignKeyFrom:self.throughUsingKey];

        NSDictionary *values = @{self.throughOwnerKey: self.entity[ownerKey],
                                 self.throughUsingKey: entity[usingKey]};

        OREntity *temp = [[self.throughClass alloc] initWithValues:values];
        [temp save];
    }
    _dirty = NO;
    return YES;
}

- (BOOL)delete
{
    if (self.entity.exists) {
        ORTable *join = [self.throughClass table];
        
        NSString *whereKey = self.entity[[join foreignKeyFrom:self.throughOwnerKey]];
        [self.throughClass deleteBy:self.throughOwnerKey value:whereKey];
    }
    return YES;
}

@end
