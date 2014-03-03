//
//  ORTable+private.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/10.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORTable.h"

@interface ORTable (private)

- (void)setup;

- (BOOL)executeSQL:(NSString *)sql args:(NSDictionary *)args process:(void (^)(int64_t lastInsertRowId))process;
- (void)executeSQL:(NSString *)sql args:(NSDictionary *)args completionWithLastInsertRowId:(void (^)(BOOL result, int64_t lastInsertRowId))block;

@end
