//
//  MOCControllerTests.m
//  FCFuture
//
//  Created by KUOKA Yusuke on 01/13/12.
//  Copyright (c) 2012 Furyu. All rights reserved.
//

#import <CoreData/CoreData.h>
#import "MOCControllerTests.h"
#import "MOCController.h"
#import "FCFuture.h"
#import "BlogPost.h"

@implementation MOCControllerTests

// A test ensures you can wait for the main thread's moc to merge changes in background thread's moc.
// Test results should be exactly same as `testCallbackOnMainThreadWaitMerge`.
//
// This one does not explicitly wait the merge in it's implementation.
// But the merge observer and the callback from FCPromise are both queued in main queue,
// hence the callback is invoked AFTER the merge observer.
- (void)testCallbackOnMainThread
{
    __block int count = 0;

    // Setup
    MOCController *controller = [[MOCController alloc] initWithRedeemAfterMerge:NO];
    NSManagedObjectContext *mocForMainThread = [controller managedObjectContext];
    BlogPost *originalPost = [NSEntityDescription insertNewObjectForEntityForName:@"BlogPost" inManagedObjectContext:mocForMainThread];
    originalPost.body = @"orig body";
    [controller save:mocForMainThread];

    __block NSManagedObjectID *objectID = originalPost.objectID;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAssert(![NSThread isMainThread], @"main thread");
        NSManagedObjectContext *mocForBackgroundThread = [controller managedObjectContext];
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BlogPost"];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"self = %@", objectID]];
        BlogPost *post = [[mocForBackgroundThread executeFetchRequest:fetchRequest error:nil] objectAtIndex:0];
        post.body = @"modified body";
        __block FCPromise *promise = [controller save:mocForBackgroundThread];
        NSLog(@"1. The managed object context is saved.");

        [promise onRedeem:^(id value) {
            NSLog(@"2. The block is invoked with redeemed value.");
            NSAssert([NSThread isMainThread], @"This block is expected to be ran on main thread.");
            STAssertEqualObjects([NSManagedObjectContext class], [value class], @"class of value = %@", [value class]);
            NSManagedObjectContext *moc = value;
            BlogPost *postFromObjectID = [moc objectWithID:objectID];
            STAssertEqualObjects(postFromObjectID.body, @"modified body", @"post.body should be modified.");
            NSArray *postsFetched = [moc executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"BlogPost"] error:nil];
            STAssertEqualObjects([postsFetched count], 1, @"posts count = %d", [postsFetched count]);
            BlogPost *postFetched = [postsFetched objectAtIndex:0];
            STAssertEqualObjects(postFetched.body, @"modified body", @"post.body should be modified.");
            count ++;
            NSLog(@"Done assertions in background.");
        }];
    });

    if (count < 1) {
        NSLog(@"Waiting...");
        NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        while (count < 1 && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            NSLog(@"Waiting...");
            loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
        }
        NSLog(@"Done waiting background assertions.");
    } else {
        NSLog(@"No need to wait.");
    }

    STAssertEquals(count, 1, @"redeem count = %d", count);
}

// A test ensures you can wait for the main thread's moc to merge changes in background thread's moc.
// Test results should be exactly same as `testCallbackOnMainThread`.
//
// This one explicitly wait the merge in it's implementation.
// That is to say, the merge observer is invoked  in -[NSManagedObjectContext save:],
// and then the callback from FCPromise is executed on main thread.
// Hence the callback is invoked AFTER the merge observer. (This result is exactly same as `testCallbackOnMainThread`.
- (void)testCallbackOnMainThreadWaitMerge
{
    __block int count = 0;

    // Setup
    MOCController *controller = [[MOCController alloc] initWithRedeemAfterMerge:YES];
    NSManagedObjectContext *mocForMainThread = [controller managedObjectContext];
    BlogPost *origPost = [NSEntityDescription insertNewObjectForEntityForName:@"BlogPost" inManagedObjectContext:mocForMainThread];
    origPost.body = @"orig body";
    [controller save:mocForMainThread];

    __block NSManagedObjectID *objectID = origPost.objectID;

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSAssert(![NSThread isMainThread], @"This block is expected to be ran in background.");
        NSManagedObjectContext *mocForBackgroundThread = [controller managedObjectContext];
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"BlogPost"];
        [fetchRequest setPredicate:[NSPredicate predicateWithFormat:@"self = %@", objectID]];
        BlogPost *post = [[mocForBackgroundThread executeFetchRequest:fetchRequest error:nil] objectAtIndex:0];
        post.body = @"modified body";
        __block FCPromise *promise = [controller save:mocForBackgroundThread];
        NSLog(@"1. The managed object context is saved.");

        [promise onRedeem:^(id value) {
            NSLog(@"2. The block is invoked with the redeemed value.");
            NSAssert([NSThread isMainThread], @"This block is expected to be ran on main thread.");
            NSAssert([value isKindOfClass:[NSManagedObjectContext class]],
                @"The argument of `onRedeem` callback should be an managed object context, but was %@", [value class]);
            NSManagedObjectContext *moc = value;
            BlogPost *postFromObjectID = [moc objectWithID:objectID];
            STAssertEqualObjects(postFromObjectID.body, @"modified body", @"post.body should be modified");
            NSArray *postsFetched = [moc executeFetchRequest:[NSFetchRequest fetchRequestWithEntityName:@"BlogPost"] error:nil];
            STAssertEqualObjects([postsFetched count], 1, @"posts count = %d", [postsFetched count]);
            BlogPost *postFetched = [postsFetched objectAtIndex:0];
            STAssertEqualObjects(postFetched.body, @"modified body", @"post.body should be modified now.");

            // Suspend the run loop and finishes this test.
            count ++;
        }];
    });

    if (count < 1) {
        NSLog(@"Waiting...");
        NSDate *loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
        NSRunLoop *theRL = [NSRunLoop currentRunLoop];
        while (count < 1 && [theRL runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]]) {
            NSLog(@"Waiting...");
            loopUntil = [NSDate dateWithTimeIntervalSinceNow:0.1];
        }
        NSLog(@"Done waiting.");
    } else {
        NSLog(@"No need to wait.");
    }

    STAssertEquals(count, 1, @"redeem count = %d", count);
}

- (void)testSave
{
    STAssertTrue((1 + 1) == 2, @"Compiler isn't feeling well today :-(");
}

@end
