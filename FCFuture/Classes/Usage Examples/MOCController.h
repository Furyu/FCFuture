//
//  Created by 九岡 佑介 on 12/01/13.
//  Copyright (c) 2011 FuRyu. All rights reserved.
//

#import <Foundation/Foundation.h>

@class FCFuture;

@interface MOCController : NSObject

- (id)initWithRedeemAfterMerge:(BOOL)redeemAfterMerge;

- (NSManagedObjectContext *)managedObjectContext;

- (FCFuture *)save:(NSManagedObjectContext *)moc;

@end