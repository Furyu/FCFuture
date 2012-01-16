//
//  Created by KUOKA Yusuke on 12/01/12.
//  Copyright (c) 2011 FuRyu. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^FCFutureCallback)(id);

@interface FCFuture : NSObject

- (FCFuture *)onRedeem:(FCFutureCallback)callback;

@end

@interface FCPromise : FCFuture

- (FCPromise *)redeem:(id)value;

@end
