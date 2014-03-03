//
//  Book.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/11.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "Book.h"
#import "User.h"

@implementation Book

+ (NSString *)tableName
{
    return @"Book";
}

- (void)awake
{
    _auther = [[ORRelation relationWithEntity:self forKey:@"auther_id"] belongs:[User class]];
}

@end
