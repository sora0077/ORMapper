//
//  User.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/11.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "User.h"
#import "Book.h"
#import "UserHasBooks.h"

@implementation User
@dynamic name;

+ (NSString *)tableName
{
    return @"User";
}

- (void)awake
{
    [super awake];

    _books = [[ORRelation relationWithEntity:self forKey:@"User_id"] hasMany:[Book class] forKey:@"Book_id" through:[UserHasBooks class]];
}

@end
