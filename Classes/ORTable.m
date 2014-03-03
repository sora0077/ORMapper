//
//  ORTable.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORTable.h"
#import "ORTable+private.h"
#import "OREntity.h"
#import "ORDatabase.h"
#import "ORDatabase+private.h"
#import "ORCursor.h"
#import "ORCache.h"

#import "ORMacros.h"

@implementation ORTable
{
    NSString *_name, *_primarykey;
    NSDictionary *_fields, *_foreignKeys;
    NSMutableArray *_reversedTables;
}

- (id)initWithName:(NSString *)name
{
    self = [super init];
    if (self) {
        _name = name;



        NSString *sql = [NSString stringWithFormat:@"PRAGMA table_info(%@)", name];

        _fields = [ORDatabase findSQL:sql args:nil process:^id(ORCursor *cursor) {
            NSMutableDictionary *fields = @{}.mutableCopy;
            while (cursor.next) {
                NSDictionary *result = cursor.result;
                if (_primarykey == nil && [result[@"pk"] boolValue]) {
                    _primarykey = result[@"name"];
                }
                [fields setObject:result forKey:result[@"name"]];
            }
            return fields;
        }];

        sql = [NSString stringWithFormat:@"PRAGMA foreign_key_list(%@)", name];
        _foreignKeys = [ORDatabase findSQL:sql args:nil process:^id(ORCursor *cursor) {
            NSMutableDictionary *foreignKeys = @{}.mutableCopy;
            while (cursor.next) {
                NSDictionary *result = cursor.result;
                [foreignKeys setObject:result forKey:result[@"from"]];
            }
            return foreignKeys;
        }];
    }
    return self;
}

- (BOOL)isEqual:(id)object
{
    BOOL ret = [super isEqual:object];
    if (ret) {
        return ret;
    }
    if ([self isKindOfClass:[object class]]
        && [self.name isEqualToString:[object name]]) {
        return YES;
    }
    return NO;
}

- (void)setup
{
    for (NSDictionary *foreignInfo in _foreignKeys.allValues) {
        ORTable *foreignTable = [ORCache tableWithName:foreignInfo[@"table"]];
    }
}

- (NSArray *)columns
{
    return _fields.allKeys;
}

- (BOOL)hasColumn:(NSString *)name
{
    return _fields[name] != nil;
}

- (NSString *)foreignKeyFrom:(NSString *)from
{
    return _foreignKeys[from][@"to"];
}

- (id)findSQL:(NSString *)sql args:(NSDictionary *)args process:(id (^)(ORCursor *))process
{
    sql = [sql stringByReplacingOccurrencesOfString:@"<table>" withString:_name];
    if (_primarykey) {
        sql = [sql stringByReplacingOccurrencesOfString:@"<primarykey>" withString:_primarykey];
    }

    return [ORDatabase findSQL:sql args:args process:process];
}

- (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args
{
    sql = [sql stringByReplacingOccurrencesOfString:@"<table>" withString:_name];
    if (_primarykey) {
        sql = [sql stringByReplacingOccurrencesOfString:@"<primarykey>" withString:_primarykey];
    }

    return [ORDatabase executeSQL:sql args:args];
}

- (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args process:(void (^)(int64_t))process
{
    sql = [sql stringByReplacingOccurrencesOfString:@"<table>" withString:_name];
    if (_primarykey) {
        sql = [sql stringByReplacingOccurrencesOfString:@"<primarykey>" withString:_primarykey];
    }

    return [ORDatabase executeSQL:sql args:args processWithLastInsertRowId:process];
}


@end
