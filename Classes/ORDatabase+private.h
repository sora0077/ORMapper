//
//  ORDatabase+private.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/08.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORDatabase.h"

@interface ORDatabase (private)

+ (id)g_DB;
+ (void)setG_DB:(id)g_DB;

+ (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args processWithLastInsertRowId:(void (^)(int64_t lastInsertRowId))process;

//+ (void)executeSQL:(NSString *)sql args:(NSDictionary *)args completionWithLastInsertRowId:(void (^)(BOOL result, int64_t lastInsertRowId))block;
@end
