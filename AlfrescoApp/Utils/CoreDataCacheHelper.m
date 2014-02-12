//
//  CoreDataCacheHelper.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 11/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "CoreDataCacheHelper.h"

static NSManagedObjectContext *cacheManagedObjectContext;
static NSManagedObjectModel *cacheManagedObjectModel;
static NSPersistentStoreCoordinator *cachePersistenceStoreCoordinator;

static NSString * const kAlfrescoAppDataStore = @".AlfrescoCache.sqlite";
static NSString * const kAlfrescoAppDataModel = @"AlfrescoCache";

@interface CoreDataCacheHelper ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation CoreDataCacheHelper

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

- (AvatarImageCache *)createAvatarObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return (AvatarImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([AvatarImageCache class]) inManagedObjectContext:managedObjectContext];
}

- (DocLibImageCache *)createDocLibObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return (DocLibImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DocLibImageCache class]) inManagedObjectContext:managedObjectContext];
}

- (DocumentPreviewImageCache *)createDocumentPreviewObjectInManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    return (DocumentPreviewImageCache *)[NSEntityDescription insertNewObjectForEntityForName:NSStringFromClass([DocumentPreviewImageCache class]) inManagedObjectContext:managedObjectContext];
}

#pragma mark - Retrieval Functions

- (AvatarImageCache *)retrieveAvatarForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext;
{
    if (!managedObjectContext)
    {
        managedObjectContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([AvatarImageCache class]) withPredicate:predicate inManagedObjectContext:managedObjectContext];
    AvatarImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}


- (DocLibImageCache *)retrieveDocLibForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext)
    {
        managedObjectContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocLibImageCache class]) withPredicate:predicate inManagedObjectContext:managedObjectContext];
    DocLibImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}

- (DocumentPreviewImageCache *)retrieveDocumentPreviewForIdentifier:(NSString *)identifier inManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext)
    {
        managedObjectContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    NSArray *nodes = [self retrieveRecordsForTable:NSStringFromClass([DocumentPreviewImageCache class]) withPredicate:predicate inManagedObjectContext:managedObjectContext];
    DocumentPreviewImageCache *returnedImageCacheObject = nil;
    if (nodes.count > 0)
    {
        returnedImageCacheObject = nodes[0];
    }
    return returnedImageCacheObject;
}

#pragma mark - Custom Getters and Setters

- (NSManagedObjectContext *)cacheManagedObjectContext
{
    if (cacheManagedObjectContext != nil) {
        return cacheManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self cachePersistenceStoreCoordinator];
    if (coordinator != nil) {
        cacheManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [cacheManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return cacheManagedObjectContext;
}

- (NSManagedObjectModel *)cacheManagedObjectModel
{
    if (cacheManagedObjectModel != nil) {
        return cacheManagedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAlfrescoAppDataModel withExtension:@"momd"];
    cacheManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return cacheManagedObjectModel;
}

- (NSPersistentStoreCoordinator *)cachePersistenceStoreCoordinator
{
    if (cachePersistenceStoreCoordinator != nil) {
        return cachePersistenceStoreCoordinator;
    }
    
    NSString *storeURLString = [[[AlfrescoFileManager sharedManager] documentsDirectory] stringByAppendingPathComponent:kAlfrescoAppDataStore];
    NSURL *storeURL = [NSURL fileURLWithPath:storeURLString];
    
    NSError *error = nil;
    cachePersistenceStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self cacheManagedObjectModel]];
    if (![cachePersistenceStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        AlfrescoLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return cachePersistenceStoreCoordinator;
}

@end
