//
//  CoreDataSyncHelper.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "CoreDataSyncHelper.h"

static NSManagedObjectContext *syncManagedObjectContext;
static NSManagedObjectModel *syncManagedObjectModel;
static NSPersistentStoreCoordinator *syncPersistenceStoreCoordinator;

static NSString * const kAlfrescoAppDataStore = @".AlfrescoSync.sqlite";
static NSString * const kAlfrescoAppDataModel = @"AlfrescoSync";

NSString * const kSyncAccountManagedObject = @"SyncAccount";
NSString * const kSyncNodeInfoManagedObject = @"SyncNodeInfo";
NSString * const kSyncErrorManagedObject = @"SyncError";

@interface CoreDataSyncHelper ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation CoreDataSyncHelper

@dynamic managedObjectContext;

- (id)init
{
    self = [super init];
    if (self)
    {
        self.managedObjectContext = [self syncManagedObjectContext];
    }
    return self;
}

#pragma mark - Create ManagedObject Methods

- (SyncAccount *)createSyncAccountMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncAccount *syncAccount = (SyncAccount *)[NSEntityDescription insertNewObjectForEntityForName:kSyncAccountManagedObject inManagedObjectContext:managedContext];
    return syncAccount;
}

- (SyncNodeInfo *)createSyncNodeInfoMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncNodeInfo *syncNodeInfo = (SyncNodeInfo *)[NSEntityDescription insertNewObjectForEntityForName:kSyncNodeInfoManagedObject inManagedObjectContext:managedContext];
    return syncNodeInfo;
}

- (SyncError *)createSyncErrorMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncError *syncError = (SyncError *)[NSEntityDescription insertNewObjectForEntityForName:kSyncErrorManagedObject inManagedObjectContext:managedContext];
    return syncError;
}

#pragma mark - Retrieve ManagedObjects

- (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && syncNodeInfoId == %@", accountId, nodeId];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

- (SyncAccount *)accountObjectForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSArray *nodes = [self retrieveRecordsForTable:kSyncAccountManagedObject withPredicate:[NSPredicate predicateWithFormat:@"accountId == %@", accountId] inManagedObjectContext:managedContext];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

- (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId inAccountWithId:(NSString *)accountId ifNotExistsCreateNew:(BOOL)createNew inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    SyncError *syncError = nil;
    
    if (nodeId)
    {
        SyncNodeInfo *nodeInfo = [self nodeInfoForObjectWithNodeId:nodeId inAccountWithId:accountId inManagedObjectContext:managedContext];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [self createSyncErrorMangedObjectInManagedObjectContext:managedContext];
            syncError.errorId = nodeId;
        }
    }
    return syncError;
}

- (NSArray *)topLevelSyncNodesInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && isTopLevelSyncNode == YES", accountId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor] inManagedObjectContext:managedContext];
    return nodes;
}

- (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && parentNode.syncNodeInfoId == %@", accountId, folderId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor] inManagedObjectContext:managedContext];
    return nodes;
}

- (BOOL)isTopLevelSyncNode:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && syncNodeInfoId == %@ && isTopLevelSyncNode == YES", accountId, nodeId];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    return nodes.count > 0;
}

- (AlfrescoDocument *)retrieveSyncedAlfrescoDocumentForIdentifier:(NSString *)documentIdentifier managedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"syncNodeInfoId == %@", documentIdentifier];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    
    AlfrescoDocument *syncedDocument = nil;
    
    if (nodes.count > 0)
    {
        NSData *syncedDocumentData = [(SyncNodeInfo *)nodes.firstObject node];
        syncedDocument = [NSKeyedUnarchiver unarchiveObjectWithData:syncedDocumentData];
    }
    
    return syncedDocument;
}

#pragma mark - Debugging Dump Methods

- (void)logAllDataInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSArray *syncAccounts = [self retrieveRecordsForTable:kSyncAccountManagedObject inManagedObjectContext:managedContext];
    for (SyncAccount *account in syncAccounts)
    {
        AlfrescoLogDebug(@"Sync Account : %@", account.accountId);
    }
    
    NSArray *nodesInfo = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject inManagedObjectContext:managedContext];
    
    for (SyncNodeInfo *nodeInfo in nodesInfo)
    {
        AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
        AlfrescoLogDebug(@"Node Info : %@ ---  total count: %d ------- id: %@", node.name, nodesInfo.count, nodeInfo.syncNodeInfoId);
    }
}


// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)syncManagedObjectContext
{
    if (syncManagedObjectContext != nil)
    {
        return syncManagedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self syncPersistenceStoreCoordinator];
    if (coordinator != nil)
    {
        syncManagedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSMainQueueConcurrencyType];
        [syncManagedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return syncManagedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)syncManagedObjectModel
{
    if (syncManagedObjectModel != nil)
    {
        return syncManagedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAlfrescoAppDataModel withExtension:@"momd"];
    syncManagedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return syncManagedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)syncPersistenceStoreCoordinator
{
    if (syncPersistenceStoreCoordinator != nil)
    {
        return syncPersistenceStoreCoordinator;
    }
    
    NSString *storeURLString = [[[AlfrescoFileManager sharedManager] documentsDirectory] stringByAppendingPathComponent:kAlfrescoAppDataStore];
    NSURL *storeURL = [NSURL fileURLWithPath:storeURLString];
    
    NSError *error = nil;
    syncPersistenceStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self syncManagedObjectModel]];
    if (![syncPersistenceStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error])
    {
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
    
    return syncPersistenceStoreCoordinator;
}

@end
