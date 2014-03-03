//
//  UserHasBooks.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/11.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "OREntity.h"

@class ORRelationBelongs;
@interface UserHasBooks : OREntity

@property (nonatomic, strong) ORRelationBelongs *user;
@property (nonatomic, strong) ORRelationBelongs *book;

@end
