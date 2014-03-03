//
//  ORRelation.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>


typedef NS_ENUM(NSUInteger, ORRelationType)
{
    ORRelationTypeBelongsTo = 1,
    ORRelationTypeHasMany,
};

typedef NS_ENUM(NSUInteger, ORRelationDependent)
{
    ORRelationDependentNothing,
    ORRelationDependentDelete,
    ORRelationDependentNullify,
};

@protocol OREntity;
@class OREntity;

@class ORRelationBelongs, ORRelationHasMany;
@interface ORRelation : NSObject
+ (instancetype)relationWithEntity:(OREntity *)entity forKey:(NSString *)inKey;

@property (nonatomic, assign) ORRelationDependent dependent;
@property (nonatomic, readonly) ORRelationType type;
@property (nonatomic, readonly) OREntity *entity;

- (ORRelationBelongs *)belongs:(Class)entityClass;
- (ORRelationHasMany *)hasMany:(Class)entityClass;
- (ORRelationHasMany *)hasMany:(Class)entityClass forKey:(NSString *)usingKey through:(Class)throughClass;

- (BOOL)fetch;
- (BOOL)sync;
- (BOOL)delete;
//SELECT * FROM Book LEFT JOIN UserHasBooks ON(Book.uuid=UserHasBooks.Book_id) WHERE UserHasBooks.User_id=self

//SELECT * FROM User WHERE uuid=:auther_id
@end

@interface ORRelationBelongs : ORRelation
@property (nonatomic) id<OREntity> ref;

//- (void)ref:(void (^)(id<OREntity> item))block;

@end

@interface ORRelationHasMany : ORRelation
@property (nonatomic) NSArray *ref;

//- (void)ref:(void (^)(NSArray *items))block;

- (NSUInteger)count;

- (void)add:(OREntity *)entity;
- (void)remove:(OREntity *)entity;
@end
