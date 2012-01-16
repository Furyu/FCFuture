//
//  Created by 九岡 佑介 on 12/01/13.
//  Copyright (c) 2011 FuRyu. All rights reserved.
//

#import "MOCController.h"
#import "FCFuture.h"
#import <CoreData/CoreData.h>

#ifdef DEBUG
#   define MOCControllerDLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define MOCControllerDLog(...)
#endif

@implementation MOCController {
    NSManagedObjectContext *_mainMoc;
    NSPersistentStoreCoordinator *_persistentStoreCoordinator;
    BOOL _redeemAfterMerge;
}

- (void)my_init
{
    NSManagedObjectModel *managedObjectModel = [NSManagedObjectModel mergedModelFromBundles:[NSArray arrayWithObject:[NSBundle mainBundle]]];
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:managedObjectModel];
    NSString *databaseFileName = @"Database.sqlite";
    NSString *documentDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    NSURL *storeURL = [NSURL fileURLWithPath:[documentDirectoryPath stringByAppendingPathComponent:databaseFileName]];
    NSError *removeError = nil;
    [[NSFileManager defaultManager] removeItemAtURL:storeURL error:&removeError];
    if (removeError) {
        MOCControllerDLog(@"removeError = %@", removeError);
    }
    NSError *error = nil;
    NSDictionary *options = [NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithBool:YES], NSMigratePersistentStoresAutomaticallyOption, nil];
    [_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error];
    if (error) {
        MOCControllerDLog(@"Error while adding a persistent store");
        MOCControllerDLog(@"%@", error);
    }
}

- (id)initWithRedeemAfterMerge:(BOOL)redeemAfterMerge
{
    self = [super init];
    if (self) {
        _redeemAfterMerge = redeemAfterMerge;
        [self my_init];
    }

    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        [self my_init];
    }

    return self;
}

- (NSManagedObjectContext *)mainMoc
{
    @synchronized (self) {
        if (!_mainMoc) {
            _mainMoc = [[NSManagedObjectContext alloc] init];
            [_mainMoc setPersistentStoreCoordinator:_persistentStoreCoordinator];
        }
    }
    return _mainMoc;
}

- (NSManagedObjectContext *)managedObjectContext
{
    if ([[NSThread currentThread] isMainThread]) {
        return [self mainMoc];
    }
    NSManagedObjectContext *moc = [[[NSManagedObjectContext alloc] init] autorelease];

    NSAssert(_persistentStoreCoordinator != nil, @"persistentStoreCoordinator should not be nil.");
    
    [moc setPersistentStoreCoordinator:_persistentStoreCoordinator];
    return moc;
}

- (FCFuture *)save:(NSManagedObjectContext *)moc
{
    FCPromise *promise = [[[[FCPromise alloc] init] autorelease] retain];
    NSManagedObjectContext *mainMoc = [self mainMoc];

    if (_redeemAfterMerge) {
        MOCControllerDLog(@"will redeem after merge");
    }

    if (moc != mainMoc) {
        // I don't want to capture observer's id.
        // The captured id is useless because it's not yet assigned.
        id *observer = malloc(sizeof(id));

        MOCControllerDLog(@"Adding merge observer");
        *observer = [[NSNotificationCenter defaultCenter] addObserverForName:NSManagedObjectContextDidSaveNotification object:moc queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification *notification) {
            MOCControllerDLog(@"Merging backgound thread's moc to main thread's moc.");
            // Delay for testing. Of course, this isn't needed at all in practice.
            usleep(1000 * 100);
            
            [mainMoc mergeChangesFromContextDidSaveNotification:notification];

            dispatch_async(dispatch_get_main_queue(), ^{
                MOCControllerDLog(@"Freeing observer.");
                [[NSNotificationCenter defaultCenter] removeObserver:*observer];
                free(observer);
                MOCControllerDLog(@"Freed observer.");
            });
    
            if (_redeemAfterMerge) {
                [promise redeem:mainMoc];
            }
        }];
    }

    NSError *error = nil;
    if (![moc save:&error]) {
        [promise redeem:error];
    } else if (moc == mainMoc || !_redeemAfterMerge) {
        [promise redeem:mainMoc];
    }
    
    return promise;
}

@end