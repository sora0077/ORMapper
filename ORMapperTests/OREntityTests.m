//
//  OREntityTests.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/22.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import <Kiwi/Kiwi.h>

#import "ORMapper.h"
#import "User.h"
#import "Book.h"

SPEC_BEGIN(OREntityTests)

describe(@"OREntity operation", ^{

    beforeAll(^{
        NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
        NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"test_db.db"];
        NSURL *url = [NSURL fileURLWithPath:dbPath];
        [ORDatabase connect:url];

        [ORDatabase executeSQL:@"PRAGMA foreign_keys = ON;" args:nil];

    });

    beforeEach(^{

        [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS User (uuid TEXT PRIMARY KEY, name TEXT)" args:nil];
        [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS Book (uuid TEXT PRIMARY KEY, name TEXT, auther_id TEXT, FOREIGN KEY(auther_id) REFERENCES User(uuid) ON DELETE SET NULL)" args:nil];
        [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS User_has_Books (User_id TEXT, Book_id TEXT, FOREIGN KEY(User_id) REFERENCES User(uuid) ON DELETE CASCADE, FOREIGN KEY(Book_id) REFERENCES Book(uuid) ON DELETE CASCADE)" args:nil];
    });

    context(@"when entity save and delete", ^{
        it(@"entity uuid is nil before save, and non nil after save", ^{
            User *user = [[User alloc] initWithValues:nil];
            [[user.uuid should] beNil];

            [user save];

            [[user.uuid should] beNonNil];

            [user delete];

            [[user.uuid should] beNil];
        });
    });

    context(@"when get entity from db", ^{
        __block User *user1;
        beforeEach(^{
            user1 = [[User alloc] init];
            user1.name = @"test_user";
            [user1 save];
        });

        it(@"should equals found user", ^{
            User *user = [User findBy:@"name" value:@"test_user"];

            [[user.uuid should] equal:user1.uuid];
        });

        it(@"should have 1 user", ^{
            NSArray *users = [User findAll];

            [[theValue(users.count) should] equal:theValue(1)];
        });
        afterEach(^{
            [user1 delete];
        });
    });

    context(@"when error occurred in transaction", ^{
        it(@"should no catch exception in transaction", ^{

            [[theBlock(^{
                User *user = [[User alloc] init];
                user.name = @"ttest";
                [ORDatabase inTransaction:^{
                    [user save];
                    @throw [NSException exceptionWithName:nil reason:nil userInfo:nil];
                }];
            }) shouldNot] raise];
        });

        it(@"should be empty", ^{

            NSArray *users = [User findAll];

            [[theValue(users.count) should] equal:theValue(0)];
        });
    });

    context(@"when success in transaction", ^{
        it(@"should have 1 entity", ^{
            [ORDatabase inTransaction:^{
                User *user = [[User alloc] init];
                user.name = @"ttest";
                [user save];
            }];

            NSArray *users = [User findAll];

            [[theValue(users.count) should] equal:theValue(1)];

        });
    });

    context(@"when save entity and other entity raise error", ^{
        it(@"should be only 1 entity", ^{
            User *user = [[User alloc] init];
            [user save];
            [[theBlock(^{
                User *user = [[User alloc] init];
                user.name = @"ttest";
                [ORDatabase inTransaction:^{
                    [user save];
                    @throw [NSException exceptionWithName:nil reason:nil userInfo:nil];
                }];
            }) shouldNot] raise];

            NSArray *users = [User findAll];

            [[theValue(users.count) should] equal:theValue(1)];
        });
    });

    context(@"when object relation", ^{
        context(@"simple state", ^{
            it(@"should be save related entity", ^{
                User *user = [[User alloc] init];
                Book *book = [[Book alloc] init];


                user.books.ref = @[book];
                [[book.uuid should] beNil];

                [user save];
                
                [[book.uuid should] beNonNil];
            });

            it(@"many many entities", ^{
                NSMutableArray *entities = @[].mutableCopy;
                for (int i = 0; i < 10000; i++) {
                    [entities addObject:[[User alloc] init]];
                }

                [[theValue(entities.count) should] equal:theValue(10000)];
                [entities save];

                [[[entities.lastObject uuid] should] beNonNil];
            });
        });

        context(@"", ^{
            it(@"should be save related entity", ^{
                User *user = [[User alloc] init];

                user.books.ref = @[[[Book alloc] init],
                                   [[Book alloc] init],
                                   [[Book alloc] init]];
                for (Book *book in user.books.ref) {
                    [[book.uuid should] beNil];
                }

                [user save];

                NSArray *books = [Book findAll];
                [[theValue(books.count) should] equal:theValue(3)];

                for (Book *book in user.books.ref) {
                    [[book.uuid should] beNonNil];
                }
            });

        });

        context(@"when delete related table entity", ^{
            beforeAll(^{
                User *user = [[User alloc] init];
                [user save];

                Book *book = [[Book alloc] init];
                book.auther.ref = user;

                [book save];
            });
            it(@"user entity should be nil", ^{
                Book *book = [Book findAll][0];
                [book.auther fetch];
                User *userRef = book.auther.ref;
                [[userRef should] beNonNil];

                User *user = [User findAll][0];
                [user delete];

                userRef = book.auther.ref;
                [[userRef should] beNil];
                
                [book.auther fetch];
                userRef = book.auther.ref;
                [[userRef should] beNil];
            });
        });

        context(@"when delete related table entity", ^{
            beforeAll(^{
                User *user = [[User alloc] init];
                user.books.ref = @[[[Book alloc] init],
                                   [[Book alloc] init],
                                   [[Book alloc] init]];

                [user save];
            });

            it(@"", ^{
                User *user = [User findAll][0];
                [user.books fetch];
                [[theValue(user.books.count) should] equal:theValue(3)];

                NSArray *books = [Book findAll];
                [books delete];

                [user.books fetch];
                [[theValue(user.books.count) should] equal:theValue(0)];
            });
        });
    });


    afterEach(^{

        [ORDatabase executeSQL:@"DROP TABLE User_has_Books" args:nil];
        [ORDatabase executeSQL:@"DROP TABLE User" args:nil];
        [ORDatabase executeSQL:@"DROP TABLE Book" args:nil];
    });
});


SPEC_END
