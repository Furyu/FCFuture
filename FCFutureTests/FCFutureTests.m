//
//  FCFutureTests.m
//  FCFutureTests
//
//  Created by KUOKA Yusuke on 01/12/12.
//  Copyright (c) 2012 Furyu. All rights reserved.
//

#import "FCFutureTests.h"
#import "FCFuture.h"

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

@end
