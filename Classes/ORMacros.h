//
//  ORMacros.h
//  ORMapper
//
//  Created by 林 達也 on 2014/02/08.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#define OR_BLOCK_CALL(block, ...) ({if (block) { block(__VA_ARGS__); }})

//#define OR_SEMAPHORE_WAIT()

#define OR_CONCAT2(x, y) x##y
#define OR_CONCAT(x, y) OR_CONCAT2(x, y)
