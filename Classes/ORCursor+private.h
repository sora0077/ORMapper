//
//  ORCursor+private.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/08.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORCursor.h"
#import <FMDB/FMResultSet.h>

@interface ORCursor (private)

- (id)initWithResultSet:(FMResultSet *)resultSet;
- (id)initWithResultSet:(FMResultSet *)resultSet open:(BOOL)open;

@end
