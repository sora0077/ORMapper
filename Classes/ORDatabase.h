//
//  ORDatabase.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/07.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Foundation/Foundation.h>

@class ORCursor;
@interface ORDatabase : NSObject

+ (BOOL)connect:(NSURL *)fileURL;
//+ (BOOL)disconnect;

+ (void)inTransaction:(void (^)())block;
+ (void)inTransaction:(void (^)())block exception:(NSException **)exception;

//+ (ORCursor *)tables;
+ (ORCursor *)schemaForTable:(NSString *)name;
+ (void)schemaForTable:(NSString *)name completion:(void (^)(ORCursor *cursor))block;


//+ (ORCursor *)findSQL:(NSString *)sql args:(NSDictionary *)args;
+ (id)findSQL:(NSString *)sql args:(NSDictionary *)args process:(id (^)(ORCursor *cursor))process;
+ (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args;

//+ (void)findSQL:(NSString *)sql args:(NSDictionary *)args completion:(void (^)(BOOL result, ORCursor *cursor))block;
//+ (void)executeSQL:(NSString *)sql args:(NSDictionary *)args completion:(void (^)(BOOL result))block;


@end

extern dispatch_queue_t ormapper_queue();
