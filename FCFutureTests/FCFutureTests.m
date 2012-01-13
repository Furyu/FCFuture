//
//  FCFutureTests.m
//  FCFutureTests
//
//  Created by KUOKA Yusuke on 01/12/12.
//  Copyright (c) 2012 Furyu. All rights reserved.
//

#import "FCFutureTests.h"
#import "FCFuture.h"

@interface VerySlowCalculator : NSObject

- (FCFuture *)add:(int)a and:(int)b;

@end

@implementation VerySlowCalculator

// You should not return a promise, but return a future, as promises are write-side of the future values and futures are
// read-side of them.
// Concretely speaking, FCFuture does not have the selector `redeem:`, but FCPromise does.
- (FCFuture *)add:(int)a and:(int)b
{
    FCPromise *promise = [[[FCPromise alloc] init] autorelease];
    // Although the computation takes a long time, invoking this method does not block the current thread.
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        // This is a very long computation
        usleep(1000 * 100);
        // Redeem the  promise
        [promise redeem:[NSNumber numberWithInt:a + b]];
    });
    // And the invoker can obtain the result through a promise.
    return promise;
}

@end

@implementation FCFutureTests

- (void)setUp
{
    [super setUp];

    // Set-up code here.
}

- (void)tearDown
{
    // Tear-down code here.
    
    [super tearDown];
}

// The callback-block should be called immediately after -[FTPromise onRedeem:] if the promise has been already redeemed.
- (void)testFutureRedeemFirst
{
    NSCondition *condition = [[[NSCondition alloc] init] autorelease];
    FCPromise *promise = [[[FCPromise alloc] init] autorelease];

    [promise redeem:@"value1"];
    
    [promise onRedeem:^(id value) {
        STAssertEqualObjects(value, @"value1", @"It should be called back with the redeemed value. value = %@", value);
    }];
}

// The callback-block should be called immediately after -[FTPromise redeem:] if the block has been already set.
- (void)testFutureSetCallbackFirst
{
    FCPromise *promise = [[[FCPromise alloc] init] autorelease];

    [promise onRedeem:^(id value) {
        STAssertEqualObjects(value, @"value2", @"It should be called back with the redeemed value. value = %@", value);
    }];

    [promise redeem:@"value2"];
}

// Multiple promises can be composed by redeeming a promise from another promise.
- (void)testChainingFutures
{
    FCPromise *promise1 = [[[FCPromise alloc] init] autorelease];
    FCPromise *promise2 = [[[FCPromise alloc] init] autorelease];
    __block int count = 0;

    [promise1 onRedeem:^(id value) {
        STAssertEqualObjects(@"value1", value, @"value of promise1 = %@", value);
        count ++;
        [promise2 redeem:@"value2"];
    }];

    [promise2 onRedeem:^(id value) {
        STAssertEqualObjects(@"value2", value, @"value of promise2 = %@", value);
        count ++;
    }];

    [promise1 redeem:@"value1"];
    STAssertEquals(2, count, @"redeem count = %d", count);
}

// A typical use case is that redeeming a promise asynchronously by using Grand Central Dispatch.
- (void)testRedeemFromDispatchGlobalQueue
{
    FCPromise *promise1 = [[[FCPromise alloc] init] autorelease];
    __block int count = 0;
    
    [promise1 onRedeem:^(id value) {
        STAssertEqualObjects(value, @"value1", @"value of promise1 = %@", value);
        count ++;
    }];

    dispatch_sync(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [promise1 redeem:@"value1"];
    });

    STAssertEquals(count, 1, @"redeemed count");
}

- (void)testFuture
{
    FCFuture *future = [[[[VerySlowCalculator alloc] init] autorelease] add:1 and:2];
    NSCondition *condition = [[[NSCondition alloc] init] autorelease];
    __block int count = 0;
    [future onRedeem:^(NSNumber *value) {
        int result = [value intValue];
        STAssertEquals(3, result, @"1 + 2 = 3");
        [condition lock];
        count ++;
        [condition signal];
        [condition unlock];
    }];

    [condition lock];
    [condition wait];
    [condition unlock];
    
    STAssertEquals(1, count, "redeem count = %d", count);
}

@end
