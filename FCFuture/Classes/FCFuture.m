//
//  Created by Kuoka Yusuke on 12/01/12.
//  Copyright (c) 2011 FuRyu. All rights reserved.
//

#import "FCFuture.h"

@interface FCFuture ()

- (void)callback:(id)value;

@end

@implementation FCFuture {
@private
    FCFutureCallback _callback;
    BOOL _called;
@protected
    BOOL _redeemed;
    id _value;
}

- (id)initWithCallback:(FCFutureCallback)callback
{
    self = [super init];
    if (self) {
        _callback = [callback copy];
    }

    return self;
}

- (void)dealloc
{
    [_callback release];
    [super dealloc];
}

- (FCFuture *)onRedeem:(FCFutureCallback)callback
{
    @synchronized (self) {
        NSAssert(_callback == nil, @"Limitation: You can set only 1 callback. callback = %p", _callback);

        _callback = [callback copy];

        if (_redeemed) {
            [self callback:_value];
        }
    }

    return self;
}

- (void)callback:(id)value
{
    if (!_callback || _called) {
        return;
    }
    _called = YES;
    _callback(value);
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
        [self callback:value];
    }
    return self;
}

@end
