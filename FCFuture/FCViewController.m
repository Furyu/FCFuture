//
//  FCViewController.m
//  FCFuture
//
//  Created by 九岡 佑介 on 01/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "FCViewController.h"
#import "FCFuture.h"

@implementation FCViewController

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.

    FCPromise *promise1 = [[[FCPromise alloc] init] autorelease];
    FCPromise *promise2 = [[[FCPromise alloc] init] autorelease];
    FCPromise *promise3 = [[[FCPromise alloc] init] autorelease];

    [promise3 redeem:@"promise3 value"];

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        usleep(1000 * 1000 * 1);
        NSLog(@"Redeeming promise1");
        [promise1 redeem:@"1 sec"];
    });

    NSLog(@"Setting callback for promise1");
    [promise1 onRedeem:^(id value) {
        NSLog(@"promise1 redeemed: value = %@", value);
        usleep(1000 * 1000 * 1);
        [promise2 redeem:@"chained promise"];
    }];

    NSLog(@"Setting callback for promise2");
    [promise2 onRedeem:^(id value) {
        NSLog(@"promise2 redeemed: value = %@", value);
    }];

    NSLog(@"Setting callback for promise3");
    [promise3 onRedeem:^(id value) {
        NSLog(@"promise3 redeemed: value = %@", value);
    }] ;
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated
{
	[super viewWillDisappear:animated];
}

- (void)viewDidDisappear:(BOOL)animated
{
	[super viewDidDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return (interfaceOrientation != UIInterfaceOrientationPortraitUpsideDown);
    } else {
        return YES;
    }
}

@end