//
//  ORAppDelegate.m
//  ORMapper
//
//  Created by 林 達也 on 2014/02/05.
//  Copyright (c) 2014年 林 達也. All rights reserved.
//

#import "ORAppDelegate.h"
#import "ORMapper.h"


#import "User.h"
#import "Book.h"
#import "UserHasBooks.h"

@implementation ORAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    // Override point for customization after application launch.
    self.window.backgroundColor = [UIColor whiteColor];
    [self.window makeKeyAndVisible];

    NSString *docsPath = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES)[0];
    NSString *dbPath   = [docsPath stringByAppendingPathComponent:@"test.db"];
//    NSString *path = dbPath;

    NSURL *url = [NSURL fileURLWithPath:dbPath];

    [ORDatabase connect:url];

    [ORDatabase findSQL:@"PRAGMA foreign_keys" args:nil process:^id(ORCursor *cursor) {
        if (cursor.next) {
            NSLog(@"%@", cursor.result);
        }
        return nil;
    }];
    [ORDatabase executeSQL:@"PRAGMA foreign_keys = ON;" args:nil];

    [ORDatabase findSQL:@"PRAGMA foreign_keys" args:nil process:^id(ORCursor *cursor) {
        if (cursor.next) {
            NSLog(@"%@", cursor.result);
        }
        return nil;
    }];
    [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS User (uuid TEXT PRIMARY KEY, name TEXT)" args:nil];
    [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS Book (uuid TEXT PRIMARY KEY, name TEXT, auther_id TEXT, FOREIGN KEY(auther_id) REFERENCES User(uuid) ON DELETE SET NULL)" args:nil];
    [ORDatabase executeSQL:@"CREATE TABLE IF NOT EXISTS User_has_Books (User_id TEXT, Book_id TEXT, FOREIGN KEY(User_id) REFERENCES User(uuid) ON DELETE CASCADE, FOREIGN KEY(Book_id) REFERENCES Book(uuid) ON DELETE CASCADE)" args:nil];


//    [ORDatabase executeSQL:@"INSERT INTO User VALUES('aaa', 'name'" args:nil];

//    User *user = [[User alloc] initWithValues:@{@"name": @"test"}];
//    [user save];
//
    User *user = [User findAll][0];
    [user delete];

//    [[[Book alloc] initWithValues:@{@"name": @"name",
//                                    @"auther_id": user.uuid}] save];
//    [ORDatabase executeSQL:@"INSERT INTO Book (uuid,name,auther_id) VALUES('test', 'name', 'aaa'" args:nil];

//    User *user1 = [User findBy:@"name" value:@"user1"];
//    if (user1 == nil) {
//        user1 = [[User alloc] initWithValues:@{@"name": @"user1"}];
//        [user1 save];
//    }
//
//    User *user2 = nil;
//    if (user2 == nil) {
//        user2 = [[User alloc] initWithValues:@{@"name": @"user2"}];
//        [user2 save];
//    }
//
//    Book *book1 = [Book findBy:@"name" value:@"book1"];
//    if (book1 == nil) {
//        book1 = [[Book alloc] initWithValues:@{@"name": @"book1"}];
//        [book1 save];
//    }
//
//    NSLog(@"ref %@", user1.books.ref);
////    [user1.books add:book1];
//    user1.books.ref = @[book1];
//
////    [user1 save];
//
//
//    [user1 delete];

    return YES;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}

@end
