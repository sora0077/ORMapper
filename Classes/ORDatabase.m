//
//  ORDatabase.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/07.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORDatabase.h"
#import "ORDatabase+private.h"
#import "ORCursor+private.h"
#import <FMDB/FMDatabase.h>
#import <FMDB/FMDatabaseQueue.h>

#import "ORMacros.h"


dispatch_queue_t ormapper_queue()
{
    static dispatch_queue_t queue;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        queue = dispatch_queue_create("jp.sora0077.ormapper.queue", NULL);
    });
    return queue;
}

static id _g_DB;
static id _g_DB_normal;

@implementation ORDatabase
{
    FMDatabaseQueue *_dbQueue;
}

+ (instancetype)sharedDatabase
{
    static id instance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[self alloc] init];
    });
    return instance;
}

+ (void)setG_DB:(id)g_DB
{
    @synchronized(self) {
        _g_DB = g_DB;
    }
}

+ (id)g_DB
{
    @synchronized(self) {
        return _g_DB;
    }
}

+ (void)setDB:(id)db
{
    @synchronized(self) {
        _g_DB_normal = db;
    }
}

+ (id)db
{
    @synchronized(self) {
        return _g_DB_normal;
    }
}

+ (BOOL)connect:(NSURL *)fileURL
{
    ORDatabase *database = [ORDatabase sharedDatabase];
    database->_dbQueue = [FMDatabaseQueue databaseQueueWithPath:fileURL.path];
    return YES;
}

+ (void)inTransaction:(void (^)())block
{
    [self inTransaction:block exception:NULL];
}

+ (void)inTransaction:(void (^)())block exception:(NSException *__autoreleasing *)pexception
{
    @synchronized(self) {
        if ([self g_DB]) {
            OR_BLOCK_CALL(block);
        } else {
            ORDatabase *database = [ORDatabase sharedDatabase];
            [database->_dbQueue inTransaction:^(FMDatabase *db, BOOL *rollback) {
                @try {
                    [self setG_DB:db];
                    OR_BLOCK_CALL(block);
                }
                @catch (NSException *exception) {
                    if (pexception) {
                        *pexception = exception;
                    }

                    *rollback = YES;
                }
                @finally {
                    [self setG_DB:nil];
                }
            }];
        }
    }
}


+ (id)findSQL:(NSString *)sql args:(NSDictionary *)args process:(id (^)(ORCursor *))process
{
    __block id ret = nil;
    ORDatabase *database = [ORDatabase sharedDatabase];

    void (^block)(FMDatabase *) = ^(FMDatabase *db) {
        ORCursor *cursor = ({
            FMResultSet *resultSet = [db executeQuery:sql withParameterDictionary:args];

            [[ORCursor alloc] initWithResultSet:resultSet];
        });
        ret = process(cursor);
    };

//    NSLog(@"%@", sql);
    if ([self db] || [self g_DB]) {
        FMDatabase *db = [self g_DB] ?: [self db];
        block(db);
    } else {
        [database->_dbQueue inDatabase:^(FMDatabase *db) {
            @synchronized(self) {
                [self setDB:db];
                block(db);
                [self setDB:nil];
            }
        }];
    }
    return ret;
}

+ (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args
{
//    NSLog(@"%@", sql);
    __block BOOL result = NO;
    void (^block)(FMDatabase *db) = ^(FMDatabase *db) {
        result = [db executeUpdate:sql withParameterDictionary:args];
    };
    if ([self g_DB]) {
        block([self g_DB]);
    } else {
        ORDatabase *database = [ORDatabase sharedDatabase];
        [database->_dbQueue inDatabase:block];
    }

    return result;
}


@end
