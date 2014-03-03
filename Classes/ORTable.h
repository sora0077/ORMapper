//
//  ORTable.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>

@class OREntity, ORCursor, ORDatabase, ORDeferredQuery;
@interface ORTable : NSObject

- (id)initWithName:(NSString *)name;

@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) BOOL exists;

@property (nonatomic, readonly) NSString *primarykey;
@property (nonatomic, readonly) NSArray *columns;
@property (nonatomic, readonly) NSDictionary *foreignKeys;

- (BOOL)hasColumn:(NSString *)name;
- (NSString *)foreignKeyFrom:(NSString *)from;

- (id)findSQL:(NSString *)sql args:(NSDictionary *)args process:(id (^)(ORCursor *cursor))process;
- (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args;

@end
