//
//  Created by Kuoka Yusuke on 12/01/12.
//  Copyright (c) 2011 FuRyu. All rights reserved.
//

#import "FCFuture.h"

#ifdef DEBUG
#   define FCFutureDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define FCFutureDLog(...)
#endif

NSString * const FCFutureDidRedeemNotification = @"FCFutureDidRedeemNotification";

NSString * const FCFutureDidRedeemNotificationUserInfoValueKey = @"FCFutureDidRedeemNotificationUserInfoValueKey";

@implementation FCFuture {
@protected
    BOOL _redeemed;
    id _value;
}

- (FCFuture *)onRedeem:(FCFutureCallback)callback
{
    @synchronized (self) {
        if (_redeemed) {
            FCFutureDLog(@"Immediately invoking the callback.");
            if ([NSThread isMainThread]) {
                callback(_value);
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    callback(_value);
                });
            }
        } else {
            FCFutureDLog(@"Delaying the callback.");
            id *observer = malloc(sizeof(id));
            *observer = [[NSNotificationCenter defaultCenter] addObserverForName:FCFutureDidRedeemNotification object:self queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
                FCFutureDLog(@"Observed a notification.");
                callback([[notification userInfo] objectForKey:FCFutureDidRedeemNotificationUserInfoValueKey]);
                dispatch_async(dispatch_get_main_queue(), ^{
                    [[NSNotificationCenter defaultCenter] removeObserver:*observer];
                    free(*observer);
                    FCFutureDLog(@"Disposed an observer.")
                });
            }];
        }
    }

    return self;
}

@end

@implementation FCPromise

- (FCPromise *)redeem:(id)value
{
    @synchronized (self) {
        if (_redeemed) {
            return;
        }
        _redeemed = YES;
        _value = [value retain];

        NSDictionary *userInfo = [NSDictionary dictionaryWithObject:value forKey:FCFutureDidRedeemNotificationUserInfoValueKey];
        [[NSNotificationCenter defaultCenter] postNotificationName:FCFutureDidRedeemNotification object:self userInfo:userInfo];
    }
    return self;
}

@end
