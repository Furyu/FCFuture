//
//  FCAppDelegate.h
//  FCFuture
//
//  Created by 九岡 佑介 on 01/12/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class FCViewController;

@interface FCAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property (strong, nonatomic) FCViewController *viewController;

@end