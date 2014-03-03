//
//  ORCursor.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/07.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORCursor.h"
#import "ORCursor+private.h"

#import "ORMacros.h"

@implementation ORCursor
{
    FMResultSet *_resultSet;
    NSArray *_results;

    NSUInteger _currentIndex;
}

- (id)initWithResultSet:(FMResultSet *)resultSet
{
    return [self initWithResultSet:resultSet open:NO];
}

- (id)initWithResultSet:(FMResultSet *)resultSet open:(BOOL)open
{
    self = [super init];
    if (self) {
        if (open) {
            NSMutableArray *results = @[].mutableCopy;
            while (resultSet.next) {
                [results addObject:resultSet.resultDictionary];
            }
            _results = results;
        } else {
            _resultSet = resultSet;
        }
    }
    return self;
}

- (void)dealloc
{
    [self close];
}

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)state objects:(__unsafe_unretained id [])buffer count:(NSUInteger)len
{
    if (_resultSet) {
        NSUInteger bufferIndex = 0;

        while (self.next) {
            id result = self.result;
            if (bufferIndex < len) break;
            buffer[bufferIndex++] = result;
        }
        state->itemsPtr = buffer;
        state->mutationsPtr = (unsigned long *)(__bridge void *)self;
        
        return bufferIndex;
    }
    return [_results countByEnumeratingWithState:state objects:buffer count:len];
}

- (BOOL)next
{
    if (_resultSet) {
        return _resultSet.next;
    }
    return _results.count > _currentIndex;
}

- (NSDictionary *)result
{
    if (_resultSet) {
        return _resultSet.resultDictionary;
    }
    return _results[_currentIndex++];
}

- (void)close
{
    [_resultSet close];
}

- (NSArray *)map:(id (^)(NSDictionary *, BOOL *))block
{
    BOOL cancel = NO;
    NSMutableArray *results = @[].mutableCopy;
    while (self.next) {
        id value = block(self.result, &cancel);
        if (cancel) break;
        if (value) {
            [results addObject:value];
        }
    }
    return results;
}

@end
