//
//  OREntity.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>




@class ORTable;
@protocol OREntity <NSObject>

+ (NSString *)tableName;
+ (ORTable *)table;

//+ (instancetype)getOrCreate:(id)id defaults:(NSDictionary *)defaults;

+ (NSArray *)findAll;
+ (id<OREntity>)findBy:(NSString *)keyPath value:(id)value;
+ (BOOL)deleteBy:(NSString *)keyPath value:(id)value;

- (id)init;
- (id)initWithValues:(NSDictionary *)values;


@property (nonatomic, readonly) NSString *uuid;
//@property (nonatomic, readonly) NSNumber *id;
@property (nonatomic, readonly) BOOL exists;
@property (nonatomic, readonly) ORTable *table;


//- (BOOL)fetch;

- (BOOL)save;
- (void)save:(void (^)(BOOL result))block;

- (BOOL)delete;
- (void)delete:(void (^)(BOOL result))block;

@optional
- (void)awake;
- (void)didAwakeFromFetch;
- (void)willAwakeFromInsert;

@end

#pragma mark -

@interface OREntity : NSObject <OREntity>
//- (id)initWithTable:(ORTable *)table;
//- (id)initWithTable:(ORTable *)table values:(NSDictionary *)values;



- (id)objectForKey:(id)aKey;
- (void)setObject:(id)anObject forKey:(id<NSCopying>)aKey;
- (void)removeObjectForKey:(id)aKey;
- (id)objectForKeyedSubscript:(id)key;
- (void)setObject:(id)obj forKeyedSubscript:(id<NSCopying>)key;


- (id)relationKey:(NSString *)key;

@end

@interface NSArray (OREntity)

- (BOOL)save;
- (BOOL)delete;

@end
