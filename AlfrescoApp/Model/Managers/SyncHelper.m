/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "SyncHelper.h"
#import "SyncNodeInfo.h"
#import "SyncAccount.h"
#import "CoreDataSyncHelper.h"
#import "SyncNodeStatus.h"

NSString * const kLastDownloadedDateKey = @"lastDownloadedDate";
NSString * const kSyncNodeKey = @"node";
NSString * const kSyncContentPathKey = @"contentPath";
NSString * const kSyncReloadContentKey = @"reloadContent";

static NSString * const kAlfrescoNodeVersionSeriesIdKey = @"cmis:versionSeriesId";

@interface SyncHelper ()
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) CoreDataSyncHelper *syncCoreDataHelper;
@end

@implementation SyncHelper

+ (SyncHelper *)sharedHelper
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (void)updateLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo
                         forAccountWithId:(NSString *)accountId
                             preserveInfo:(NSDictionary *)info
                              permissions:(NSDictionary *)permissions
                 refreshExistingSyncNodes:(BOOL)refreshExisting
                   inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    @autoreleasepool
    {
        if (refreshExisting)
        {
            // refresh data in Database for account
            [self deleteStoredInfoForAccountWithId:accountId inManagedObjectContext:managedContext];
        }
        
        SyncAccount *syncAccount = [self.syncCoreDataHelper accountObjectForAccountWithId:accountId inManagedObjectContext:managedContext];
        if (!syncAccount)
        {
            syncAccount = [self.syncCoreDataHelper createSyncAccountMangedObjectInManagedObjectContext:managedContext];
            syncAccount.accountId = accountId;
        }
        NSMutableArray *syncNodesInfoKeys = [[syncNodesInfo allKeys] mutableCopy];
        
        NSArray *topLevelSyncItems = [syncNodesInfo objectForKey:accountId];
        
        [self populateNodes:topLevelSyncItems inParentFolder:syncAccount.accountId forAccountWithId:accountId preserveInfo:info permissions:permissions inManagedObjectContext:managedContext];
        [syncNodesInfoKeys removeObject:accountId];
        
        for (NSString *syncFolderInfoKey in syncNodesInfoKeys)
        {
            NSArray *nodesInFolder = [syncNodesInfo objectForKey:syncFolderInfoKey];
            
            if (nodesInFolder.count > 0)
            {
                [self populateNodes:nodesInFolder inParentFolder:syncFolderInfoKey forAccountWithId:accountId preserveInfo:info permissions:permissions inManagedObjectContext:managedContext];
            }
        }
        [self.syncCoreDataHelper saveContextForManagedObjectContext:managedContext];
        [managedContext reset];
    }
}

- (void)deleteStoredInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@", accountId];
    NSArray *allNodeInfos = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    for (SyncNodeInfo *nodeInfo in allNodeInfos)
    {
        // delete all sync node info records for current account so we get everything refreshed (except if file is changed locally but has changes - will be deleted after its uploaded)
        BOOL isRemovedFromSyncHasLocalChanges = [nodeInfo.isRemovedFromSyncHasLocalChanges intValue];
        if (!isRemovedFromSyncHasLocalChanges)
        {
            [self.syncCoreDataHelper deleteRecordForManagedObject:nodeInfo inManagedObjectContext:managedContext];
        }
        [self.syncCoreDataHelper deleteRecordForManagedObject:nodeInfo.syncError inManagedObjectContext:managedContext];
    }
}

- (void)populateNodes:(NSArray *)nodes
       inParentFolder:(NSString *)folderId
     forAccountWithId:(NSString *)accountId
         preserveInfo:(NSDictionary *)info
          permissions:(NSDictionary *)permissions inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    BOOL (^updateInfoWithExistingInfoForSyncNode)(SyncNodeInfo *) = ^ BOOL (SyncNodeInfo *nodeInfo)
    {
        NSDictionary *infoTobePreserved = [info objectForKey:nodeInfo.syncNodeInfoId];
        
        if (infoTobePreserved)
        {
            nodeInfo.reloadContent = [infoTobePreserved objectForKey:kSyncReloadContentKey];
            nodeInfo.lastDownloadedDate = [infoTobePreserved objectForKey:kLastDownloadedDateKey];
            nodeInfo.syncContentPath = [infoTobePreserved objectForKey:kSyncContentPathKey];
        }
        return YES;
    };
    
    SyncAccount *syncAccount = [self.syncCoreDataHelper accountObjectForAccountWithId:accountId inManagedObjectContext:managedContext];
    BOOL isTopLevelSyncNode = ([folderId isEqualToString:accountId]);
    
    // retrieve existing or create new parent folder in managed context
    id parentNodeInfo = nil;
    if (isTopLevelSyncNode)
    {
        parentNodeInfo = syncAccount;
    }
    else
    {
        parentNodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:folderId inAccountWithId:accountId inManagedObjectContext:managedContext];
        if (parentNodeInfo == nil)
        {
            parentNodeInfo = [self.syncCoreDataHelper createSyncNodeInfoMangedObjectInManagedObjectContext:managedContext];
            [parentNodeInfo setSyncNodeInfoId:folderId];
            [parentNodeInfo setAccount:syncAccount];
            [parentNodeInfo setIsTopLevelSyncNode:[NSNumber numberWithBool:isTopLevelSyncNode]];
            [parentNodeInfo setIsFolder:[NSNumber numberWithBool:YES]];
        }
    }
    
    // populate parent folder with its children nodes
    for (AlfrescoNode *alfrescoNode in nodes)
    {
        // check if we already have object in managedContext for alfrescoNode
        SyncNodeInfo *syncNodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self syncIdentifierForNode:alfrescoNode] inAccountWithId:accountId inManagedObjectContext:managedContext];
        NSData *archivedNode = [NSKeyedArchiver archivedDataWithRootObject:alfrescoNode];
        NSData *archivedPermissions = nil;
        AlfrescoPermissions *nodePermissions = [permissions objectForKey:[self syncIdentifierForNode:alfrescoNode]];
        if (nodePermissions)
        {
            archivedPermissions = [NSKeyedArchiver archivedDataWithRootObject:nodePermissions];
        }
        
        // create new nodeInfo for node if it does not exist yet
        if (!syncNodeInfo)
        {
            syncNodeInfo = [self.syncCoreDataHelper createSyncNodeInfoMangedObjectInManagedObjectContext:managedContext];
            syncNodeInfo.syncNodeInfoId = [self syncIdentifierForNode:alfrescoNode];
            syncNodeInfo.isFolder = [NSNumber numberWithBool:alfrescoNode.isFolder];
            syncNodeInfo.account = syncAccount;
        }
        syncNodeInfo.title = alfrescoNode.name;
        syncNodeInfo.node = archivedNode;
        
        if (isTopLevelSyncNode)
        {
            syncNodeInfo.isTopLevelSyncNode = [NSNumber numberWithBool:isTopLevelSyncNode];
        }
        if (archivedPermissions)
        {
            syncNodeInfo.permissions = archivedPermissions;
        }
        
        // update node info with existing info for documents (will set their new info once they are successfully downloaded) - for folders update their nodes
        if (!alfrescoNode.isFolder)
        {
            updateInfoWithExistingInfoForSyncNode(syncNodeInfo);
        }
        
        [parentNodeInfo addNodesObject:syncNodeInfo];
    }
}

#pragma mark - Sync Naming and ID Functions

- (NSString *)syncNameForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self syncIdentifierForNode:node] inAccountWithId:accountId inManagedObjectContext:managedContext];
    
    if (nodeInfo.syncContentPath.length == 0)
    {
        NSString *newName = @"";
        NSString *nodeExtension = [node.name pathExtension];
        
        if (nodeExtension.length == 0)
        {
            newName = [[self syncIdentifierForNode:node] lastPathComponent];
        }
        else
        {
            newName = [NSString stringWithFormat:@"%@.%@", [[self syncIdentifierForNode:node] lastPathComponent], nodeExtension];
        }
        return newName;
    }
    return [nodeInfo.syncContentPath lastPathComponent];
}

- (NSString *)syncIdentifierForNode:(AlfrescoNode *)node
{
    NSString *syncIdentifier = [(AlfrescoProperty *)[node.properties objectForKey:kAlfrescoNodeVersionSeriesIdKey] value];
    if (!syncIdentifier)
    {
        syncIdentifier = [Utility nodeRefWithoutVersionID:node.identifier];
    }
    return syncIdentifier;
}

- (NSMutableArray *)syncIdentifiersForNodes:(NSArray *)nodes
{
    NSMutableArray *syncIdentifiers = [NSMutableArray array];
    
    for (AlfrescoNode *node in nodes)
    {
        [syncIdentifiers addObject:[self syncIdentifierForNode:node]];
    }
    return syncIdentifiers;
}

- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountId
{
    NSString *contentDirectory = [self.fileManager syncFolderPath];
    if (accountId)
    {
        contentDirectory = [contentDirectory stringByAppendingPathComponent:accountId];
    }
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:contentDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }

    return contentDirectory;
}

#pragma mark - SyncInfo Utilities

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeId inAccountWithId:accountId inManagedObjectContext:managedContext];
    if (nodeInfo.node)
    {
        return [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
    }
    return nil;
}

- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self syncIdentifierForNode:node] inAccountWithId:accountId inManagedObjectContext:managedContext];
    return nodeInfo.lastDownloadedDate;
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self syncIdentifierForNode:document] inAccountWithId:accountId inManagedObjectContext:managedContext];
    nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
    [self.syncCoreDataHelper saveContextForManagedObjectContext:managedContext];
}

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId inSyncNodesStatus:(NSDictionary *)syncStatuses
{
    SyncNodeStatus *nodeStatus = [syncStatuses objectForKey:nodeId];
    
    if (!nodeStatus && nodeId)
    {
        nodeStatus = [[SyncNodeStatus alloc] initWithNodeId:nodeId];
        [syncStatuses setValue:nodeStatus forKey:nodeId];
    }
    
    return nodeStatus;
}

#pragma mark - Delete Methods

- (void)deleteNodeFromSync:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSString *nodeSyncName = [self syncNameForNode:node inAccountWithId:accountId inManagedObjectContext:managedContext];
    NSString *syncNodeContentPath = [[self syncContentDirectoryPathForAccountWithId:accountId] stringByAppendingPathComponent:nodeSyncName];

    // No error handling here as we don't want to end up with Sync orphans
    [self.fileManager removeItemAtPath:syncNodeContentPath error:nil];

    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self syncIdentifierForNode:node] inAccountWithId:accountId inManagedObjectContext:managedContext];
    [self.syncCoreDataHelper deleteRecordForManagedObject:nodeInfo inManagedObjectContext:managedContext];
}

- (void)deleteNodesFromSync:(NSArray *)array inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    for (AlfrescoNode *node in array)
    {
        [self deleteNodeFromSync:node inAccountWithId:accountId inManagedObjectContext:managedContext];
    }
    [self.syncCoreDataHelper saveContextForManagedObjectContext:managedContext];
}

- (void)removeSyncContentAndInfoForAccountWithId:(NSString *)accountId syncNodeStatuses:(NSDictionary *)nodeStatuses inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSString *accountContentDirectory = [self syncContentDirectoryPathForAccountWithId:accountId];
    NSError *error = nil;
    [self.fileManager removeItemAtPath:accountContentDirectory error:&error];
    
    if (!error)
    {
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@", accountId];
        
        NSArray *nodesToBeRemoved = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
        
        SyncAccount *syncAccount = [nodesToBeRemoved.firstObject account];
        [self.syncCoreDataHelper deleteRecordForManagedObject:syncAccount inManagedObjectContext:managedContext];
        
        for (SyncNodeInfo *nodeInfo in nodesToBeRemoved)
        {
            SyncNodeStatus *nodeStatus = nodeStatuses[nodeInfo.syncNodeInfoId];
            nodeStatus.status = SyncStatusRemoved;
            if (nodeInfo.isFolder)
            {
                nodeStatus.totalSize = 0;
            }
            [self.syncCoreDataHelper deleteRecordForManagedObject:nodeInfo inManagedObjectContext:managedContext];
        }
    }
}

- (void)removeSyncContentAndInfoInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSString *syncContentDirectory = [self syncContentDirectoryPathForAccountWithId:nil];
    NSError *error = nil;
    [self.fileManager removeItemAtPath:syncContentDirectory error:&error];
    
    if (!error)
    {
        [self.syncCoreDataHelper deleteAllRecordsInTable:kSyncAccountManagedObject inManagedObjectContext:managedContext];
        [self.syncCoreDataHelper deleteAllRecordsInTable:kSyncNodeInfoManagedObject inManagedObjectContext:managedContext];
        [self.syncCoreDataHelper saveContextForManagedObjectContext:managedContext];
    }
}

- (AlfrescoDocument *)syncDocumentFromDocumentIdentifier:(NSString *)documentRef
{
    NSString *syncDocumentRef = [Utility nodeRefWithoutVersionID:documentRef];
    return [self.syncCoreDataHelper retrieveSyncedAlfrescoDocumentForIdentifier:syncDocumentRef managedObjectContext:nil];
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
        self.syncCoreDataHelper = [[CoreDataSyncHelper alloc] init];
    }
    return self;
}

@end
