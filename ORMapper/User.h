//
//  User.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/11.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "OREntity.h"

@class ORRelationHasMany;
@interface User : OREntity

@property (nonatomic) NSString *name;
@property (nonatomic, strong) ORRelationHasMany *books;

@end
