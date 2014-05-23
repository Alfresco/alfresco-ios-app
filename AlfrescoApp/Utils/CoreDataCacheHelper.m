//
//  CoreDataCacheHelper.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "CoreDataCacheHelper.h"

static NSManagedObjectContext *sCacheManagedObjectContext;
static NSManagedObjectModel *sCacheManagedObjectModel;
static NSPersistentStoreCoordinator *sCachePersistenceStoreCoordinator;

static NSString * const kAlfrescoAppDataStore = @".AlfrescoCache.sqlite";
static NSString * const kAlfrescoAppDataModel = @"AlfrescoCache";

@interface CoreDataCacheHelper ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CoreDataCacheHelper

@dynamic managedObjectContext;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.managedObjectContext = [self cacheManagedObjectContext];
    }
    return self;
}

#pragma mark - Creation Convenience Functions

- (AvatarImageCache *)createAvatarObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    return (AvatarImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AvatarImageCache class]) inManagedObjectContext:managedContext];
}

- (DocLibImageCache *)createDocLibObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    return (DocLibImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DocLibImageCache class]) inManagedObjectContext:managedContext];
}

- (DocumentPreviewImageCache *)createDocumentPreviewObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    return (DocumentPreviewImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DocumentPreviewImageCache class]) inManagedObjectContext:managedContext];
}

#pragma mark - Retrieval Functions

- (AvatarImageCache *)retrieveAvatarForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedContext;
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([AvatarImageCache class]) withPredicate:predicate inManagedObjectContext:managedContext];
    AvatarImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}


- (DocLibImageCache *)retrieveDocLibForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocLibImageCache class]) withPredicate:predicate inManagedObjectContext:managedContext];
    DocLibImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
        
        // if more than one is returned, get the latest
        for (DocLibImageCache *docLibCacheObject in nodes)
        {
            if ([docLibCacheObject.dateModified compare:returnedImageCacheObject.dateModified] == NSOrderedDescending)
            {
                returnedImageCacheObject = docLibCacheObject;
            }
        }
    }
    return returnedImageCacheObject;
}

- (DocLibImageCache *)retrieveDocLibForDocument:(AlfrescoDocument *)document inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND dateModified == %@", document.identifier, document.modifiedAt];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocLibImageCache class]) withPredicate:predicate inManagedObjectContext:managedContext];
    DocLibImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}

- (DocumentPreviewImageCache *)retrieveDocumentPreviewForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocumentPreviewImageCache class]) withPredicate:predicate inManagedObjectContext:managedContext];
    DocumentPreviewImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
        
        // if more than one is returned, get the latest
        for (DocumentPreviewImageCache *previewImageCacheObject in nodes)
        {
            if ([previewImageCacheObject.dateModified compare:returnedImageCacheObject.dateModified] == NSOrderedDescending)
            {
                returnedImageCacheObject = previewImageCacheObject;
            }
        }
    }
    return returnedImageCacheObject;
}

- (DocumentPreviewImageCache *)retrieveDocumentPreviewForDocument:(AlfrescoDocument *)document inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@ AND dateModified == %@", document.identifier, document.modifiedAt];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocumentPreviewImageCache class]) withPredicate:predicate inManagedObjectContext:managedContext];
    DocumentPreviewImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}

- (void)removeAllCachedDataOlderThanNumberOfDays:(NSNumber *)numberOfDays
{
    NSCalendar *calender = [NSCalendar currentCalendar];
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = -numberOfDays.integerValue;
    
    
    NSDate *cutOffDate = [calender dateByAddingComponents:dateComponents toDate:[NSDate date] options:0];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"dateAdded < %@", cutOffDate];
    
    [self deleteRecordsWithPredicate:predicate inTable:NSStringFromClass([AvatarImageCache class]) inManagedObjectContext:self.managedObjectContext];
    [self deleteRecordsWithPredicate:predicate inTable:NSStringFromClass([DocLibImageCache class]) inManagedObjectContext:self.managedObjectContext];
    [self deleteRecordsWithPredicate:predicate inTable:NSStringFromClass([DocumentPreviewImageCache class]) inManagedObjectContext:self.managedObjectContext];
}

#pragma mark - Custom Getters and Setters

- (NSManagedObjectContext *)cacheManagedObjectContext
{
    if (sCacheManagedObjectContext != nil)
    {
        return sCacheManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self cachePersistenceStoreCoordinator];
    if (coordinator != nil)
    {
        sCacheManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [sCacheManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return sCacheManagedObjectContext;
}

- (NSManagedObjectModel *)cacheManagedObjectModel
{
    if (sCacheManagedObjectModel != nil)
    {
        return sCacheManagedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAlfrescoAppDataModel withExtension:@"momd"];
    sCacheManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return sCacheManagedObjectModel;
}

- (NSPersistentStoreCoordinator *)cachePersistenceStoreCoordinator
{
    static BOOL reentrancyFlag = NO;
    
    if (sCachePersistenceStoreCoordinator != nil)
    {
        return sCachePersistenceStoreCoordinator;
    }
    
    NSString *storeURLString = [[[AlfrescoFileManager sharedManager] documentsDirectory] stringByAppendingPathComponent:kAlfrescoAppDataStore];
    NSURL *storeURL = [NSURL fileURLWithPath:storeURLString];
    
    NSError *error = nil;
    sCachePersistenceStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self cacheManagedObjectModel]];
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES};
    if (![sCachePersistenceStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        /**
         * Unable to automatically migrate the store using lightweight migration.
         *
         * We should do some manual migration here, should it be needed. However, since the cache model is fairly simple, and there is no
         * current requirement to carry out manual migration, we will simply delete the existing cache database and create a new one.
         */
        NSError *removalError = nil;
        [[AlfrescoFileManager sharedManager] removeItemAtURL:storeURL error:&error];
        
        if (removalError)
        {
            AlfrescoLogError(@"Unable to remove cache store at path: %@ due to error: %@", storeURL, error.localizedDescription);
#if DEBUG
            // If in debug, and we were unable to remove the old cache model, call abort() in order to create a crash log
            abort();
#endif
        }
        
        if (!reentrancyFlag)
        {
            // Try and recreate the managed object context, which should propagate down into this call again.
            reentrancyFlag = YES;
            self.managedObjectContext = [self cacheManagedObjectContext];
            reentrancyFlag = NO;
        }
        else
        {
            // If we're reentrant and still have no MOC, then the situation is not recoverable
            if (!self.managedObjectContext)
            {
                @throw ([NSException exceptionWithName:@"CoreData Cache Helper"
                                                reason:[NSString stringWithFormat:@"Unable to recreate Managed Object Context %@ %@", [self class], NSStringFromSelector(_cmd)]
                                              userInfo:nil]);

            }
        }
    }
    
    return sCachePersistenceStoreCoordinator;
}

@end
