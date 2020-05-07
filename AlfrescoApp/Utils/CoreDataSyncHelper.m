/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
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

- (NSArray *)retrieveSyncFileNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && isFolder == NO", accountId];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    
    return nodes;
}

- (NSArray *)retrieveSyncFolderNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (!managedContext)
    {
        managedContext = self.managedObjectContext;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && isFolder == YES", accountId];
    NSArray *nodes = [self retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    
    return nodes;
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
    
    NSDictionary *options = @{NSMigratePersistentStoresAutomaticallyOption : @YES, NSInferMappingModelAutomaticallyOption : @YES};
    if (![syncPersistenceStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:options error:&error])
    {
        /*
         * Unable to automatically migrate the store using lightweight migration.
         *
         * We should do some manual migration here, should it be needed. However, we currently don't have any versioned sync models
         * so a manual migration is not required. We no not want to delete the existing data store as this will lead to loss of data.
         * Instead, just log the error (for now).
         *
         * There are no other requirements on how the app should react if synced content is corrupted or is not accessible.
         */
        AlfrescoLogError(@"Unresolved error %@, %@", error, [error userInfo]);
        
        #if DEBUG
            abort();
        #endif
    }
    
    return syncPersistenceStoreCoordinator;
}

@end
