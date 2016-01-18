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
 
#import "SyncManager.h"
#import "CoreDataSyncHelper.h"
#import "SyncAccount.h"
#import "SyncNodeInfo.h"
#import "SyncError.h"
#import "SyncHelper.h"
#import "DownloadManager.h"
#import "AccountManager.h"
#import "UserAccount.h"
#import "SyncOperation.h"
#import "ConnectivityManager.h"
#import "PreferenceManager.h"
#import "AccountSyncProgress.h"
#import "AlfrescoFileManager+Extensions.h"

static NSUInteger const kSyncMaxConcurrentOperations = 2;

static NSUInteger const kSyncOperationCancelledErrorCode = 1800;

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsRemovedFromSyncOnServerWithLocalChanges = @"removedFromSyncOnServerWithLocalChanges";
NSString * const kDocumentsDeletedOnServerWithLocalChanges = @"deletedOnServerWithLocalChanges";
static NSString * const kDocumentsToBeDeletedLocallyAfterUpload = @"toBeDeletedLocallyAfterUpload";

@interface SyncManager ()
@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) NSMutableDictionary *syncNodesInfo;
@property (nonatomic, strong) NSMutableDictionary *syncNodesStatus;
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (atomic, assign) NSInteger nodeChildrenRequestsCount;
@property (nonatomic, strong) NSMutableDictionary *syncQueues;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;
@property (nonatomic, strong) NSMutableDictionary *permissions;
@property (nonatomic, strong) CoreDataSyncHelper *syncCoreDataHelper;
@property (nonatomic, strong) SyncHelper *syncHelper;
@property (nonatomic, strong) NSMutableDictionary *accountsSyncProgress;
@property (nonatomic, strong) NSOperationQueue *currentQueue;
@property (nonatomic, strong) NSString *selectedAccountIdentifier;
@property (nonatomic, assign) BOOL isProcessingSyncNodes;

@property (nonatomic) BOOL lastConnectivityFlag;
@end

@implementation SyncManager

#pragma mark - Public Interface

+ (SyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        _fileManager = [AlfrescoFileManager sharedManager];
        
        // syncNodesInfo will hold mutable dictionaries for each account
        _syncNodesInfo = [NSMutableDictionary dictionary];
        
        _syncQueues = [NSMutableDictionary dictionary];
        _syncOperations = [NSMutableDictionary dictionary];
        _accountsSyncProgress = [NSMutableDictionary dictionary];
        
        _syncObstacles = @{kDocumentsRemovedFromSyncOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        _syncCoreDataHelper = [[CoreDataSyncHelper alloc] init];
        _syncHelper = [SyncHelper sharedHelper];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusChanged:)
                                                     name:kSyncStatusChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kAlfrescoConnectivityChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountInfoUpdated:)
                                                     name:kAlfrescoAccountUpdatedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountRemoved:)
                                                     name:kAlfrescoAccountRemovedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nodeAdded:)
                                                     name:kAlfrescoNodeAddedOnServerNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSMutableArray *syncedNodes))completionBlock
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    self.selectedAccountIdentifier = [self accountIdentifierForAccount:selectedAccount];
    NSOperationQueue *syncQueue = self.syncQueues[self.selectedAccountIdentifier];
    
    if (!syncQueue)
    {
        syncQueue = [[NSOperationQueue alloc] init];
        syncQueue.name = self.selectedAccountIdentifier;
        syncQueue.maxConcurrentOperationCount = kSyncMaxConcurrentOperations;
        
        self.syncQueues[self.selectedAccountIdentifier] = syncQueue;
        self.syncOperations[self.selectedAccountIdentifier] = [NSMutableDictionary dictionary];
        
        AccountSyncProgress *syncProgress = [[AccountSyncProgress alloc] initWithObserver:self];
        self.accountsSyncProgress[self.selectedAccountIdentifier] = syncProgress;
    }
    
    if (![self.currentQueue isEqual:syncQueue])
    {
        self.currentQueue.suspended = YES;
    }
    
    syncQueue.suspended = NO;
    self.currentQueue = syncQueue;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    
    if (syncQueue.operationCount == 0 && !self.isProcessingSyncNodes)
    {
        self.alfrescoSession = alfrescoSession;
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:alfrescoSession];
        self.syncNodesStatus = [NSMutableDictionary dictionary];
        
        if (self.documentFolderService)
        {
            [self.documentFolderService clear];
            self.isProcessingSyncNodes = YES;
            
            [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
                if (array)
                {
                    [self rearrangeNodesAndSync:array];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kFavoritesListUpdatedNotification object:nil];
                    if(completionBlock)
                    {
                        completionBlock([self topLevelSyncNodesOrNodesInFolder:nil]);
                    }
                }
                else
                {
                    self.isProcessingSyncNodes = NO;
                }
            }];
        }
        else
        {
            [self updateFolderSizes:YES andCheckIfAnyFileModifiedLocally:YES];
        }
    }
    return [self topLevelSyncNodesOrNodesInFolder:nil];
}

- (NSMutableArray *)topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)folder
{
    NSMutableDictionary *syncNodesInfoForSelectedAccount = self.syncNodesInfo[self.selectedAccountIdentifier];
    NSString *folderKey = folder ? [self.syncHelper syncIdentifierForNode:folder] : self.selectedAccountIdentifier;
    NSMutableArray *syncNodes = [syncNodesInfoForSelectedAccount[folderKey] mutableCopy];
    
    if (!syncNodes)
    {
        syncNodes = [NSMutableArray array];
        NSArray *nodesInfo = nil;
        if (folder)
        {
            nodesInfo = [self.syncCoreDataHelper syncNodesInfoForFolderWithId:[self.syncHelper syncIdentifierForNode:folder] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
        }
        else
        {
            SyncAccount *syncAccount = [self.syncCoreDataHelper accountObjectForAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
            if (syncAccount)
            {
                nodesInfo = [self.syncCoreDataHelper topLevelSyncNodesInfoForAccountWithId:syncAccount.accountId inManagedObjectContext:nil];
            }
        }
        
        for (SyncNodeInfo *nodeInfo in nodesInfo)
        {
            AlfrescoNode *alfrescoNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            if (alfrescoNode)
            {
                [syncNodes addObject:alfrescoNode];
            }
        }
    }
    
    return syncNodes;
}

- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = [self.permissions objectForKey:[self.syncHelper syncIdentifierForNode:node]];
    
    if (!permissions)
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:node] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
        
        if (nodeInfo.permissions)
        {
            permissions = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.permissions];
        }
    }
    return permissions;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:document] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
    
    //since this path was stored as a full path and not relative to the Documents folder, the following is necessary to get to the correct path for the node
    NSString *newNodePath = nil;
    if(nodeInfo)
    {
        NSString *storedPath = nodeInfo.syncContentPath;
        NSString *relativePath = [self getRelativeSyncPath:storedPath];
        NSString *syncDirectory = [[AlfrescoFileManager sharedManager] syncFolderPath];
        newNodePath = [syncDirectory stringByAppendingPathComponent:relativePath];
    }
    
    return newNodePath;
}

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:syncNodeId inSyncNodesStatus:self.syncNodesStatus];
    return nodeStatus;
}

- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node
{
    SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inAccountWithId:self.selectedAccountIdentifier ifNotExistsCreateNew:NO inManagedObjectContext:nil];
    return syncError.errorDescription;
}

- (AlfrescoNode *)alfrescoNodeForIdentifier:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:syncNodeId inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
    
    AlfrescoNode *node = nil;
    if (nodeInfo.node)
    {
        node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
    }
    return node;
}

#pragma mark - Private Methods

// this parses a path to get the relative path to the Sync folder
- (NSString *) getRelativeSyncPath:(NSString *)oldPath
{
    NSString *newPath = nil;
    NSArray *array = [oldPath componentsSeparatedByString:[NSString stringWithFormat:@"%@/",kSyncFolder]];
    if(array.count >= 2)
    {
        newPath = array[1];
    }
    
    return newPath;
}

- (void)rearrangeNodesAndSync:(NSArray *)nodes
{
    // top level sync nodes are held in self.syncNodesInfo with key account Identifier
    if (nodes)
    {
        NSMutableDictionary *nodesInfoForSelectedAccount = [NSMutableDictionary dictionary];
        self.syncNodesInfo[self.selectedAccountIdentifier] = nodesInfoForSelectedAccount;
        nodesInfoForSelectedAccount[self.selectedAccountIdentifier] = [nodes mutableCopy];
    }
    
    BOOL (^hasFolder)(NSArray *) = ^ BOOL (NSArray *nodesArray)
    {
        for (AlfrescoNode *alfrescoNode in nodesArray)
        {
            if (alfrescoNode.isFolder)
            {
                return YES;
            }
        }
        return NO;
    };
    
    [self showSyncAlertWithCompletionBlock:^(BOOL completed) {
        
        if ([self isSyncPreferenceOn])
        {
            [self retrievePermissionsForNodes:nodes withCompletionBlock:^{
                
                if (!hasFolder(nodes))
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
                    });
                }
                else
                {
                    // retrieve nodes for top level sync nodes
                    for (AlfrescoNode *node in nodes)
                    {
                        if (node.isFolder)
                        {
                            [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                                
                                if (self.nodeChildrenRequestsCount == 0)
                                {
                                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                        [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
                                    });
                                }
                            }];
                        }
                    }
                }
            }];
        }
        else
        {
            self.isProcessingSyncNodes = NO;
        }
    }];
}

- (void)retrieveNodeHierarchyForNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo[self.selectedAccountIdentifier];
    
    if (node.isFolder && ([nodesInfoForSelectedAccount objectForKey:[self.syncHelper syncIdentifierForNode:node]] == nil))
    {
        self.nodeChildrenRequestsCount++;
        [self.documentFolderService retrieveChildrenInFolder:(AlfrescoFolder *)node completionBlock:^(NSArray *array, NSError *error) {
            
            self.nodeChildrenRequestsCount--;
            if (array)
            {
                // nodes for each folder are held in with keys folder identifiers
                nodesInfoForSelectedAccount[[self.syncHelper syncIdentifierForNode:node]] = array;
                [self retrievePermissionsForNodes:array withCompletionBlock:^{
                    
                    for (AlfrescoNode *node in array)
                    {
                        // recursive call to retrieve nodes hierarchies
                        [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                            
                            if (completionBlock != NULL)
                            {
                                completionBlock(YES);
                            }
                        }];
                    }
                }];
            }
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
}

/*
 returns documents in folder hierarchies
 */
- (NSArray *)allRemoteSyncDocuments
{
    NSArray * (^documentsInNodes)(NSArray *) = ^ NSArray * (NSArray *nodes)
    {
        NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"SELF.isDocument == YES"];
        NSMutableArray *documents = [[nodes filteredArrayUsingPredicate:documentsPredicate] mutableCopy];
        return documents;
    };
    
    BOOL (^nodesContainsDocument)(NSArray *, AlfrescoDocument *) = ^ BOOL (NSArray *array, AlfrescoDocument *document)
    {
        BOOL documentExists = NO;
        for (AlfrescoNode *node in array)
        {
            if ([[self.syncHelper syncIdentifierForNode:node] isEqualToString:[self.syncHelper syncIdentifierForNode:document]])
            {
                documentExists = YES;
            }
        }
        return documentExists;
    };
    
    NSMutableArray *allDocuments = [NSMutableArray array];
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo[self.selectedAccountIdentifier];
    NSMutableArray *syncNodesInfoKeys = [[nodesInfoForSelectedAccount allKeys] mutableCopy];
    [syncNodesInfoKeys removeObject:self.selectedAccountIdentifier];
    
    NSArray *topLevelDocuments = documentsInNodes(nodesInfoForSelectedAccount[self.selectedAccountIdentifier]);
    [allDocuments addObjectsFromArray:topLevelDocuments];
    
    for (NSString *syncFolderInfoKey in syncNodesInfoKeys)
    {
        NSArray *folderDocuments = documentsInNodes(nodesInfoForSelectedAccount[syncFolderInfoKey]);
        
        for (AlfrescoDocument *document in folderDocuments)
        {
            if (!nodesContainsDocument(topLevelDocuments, document))
            {
                [allDocuments addObject:document];
            }
        }
    }
    return allDocuments;
}

- (void)syncNodes:(NSArray *)nodes includeExistingSyncNodes:(BOOL)includeExistingSyncNodes
{
    if ([self isSyncEnabled])
    {
        NSMutableArray *nodesToUpload = [[NSMutableArray alloc] init];
        NSMutableArray *nodesToDownload = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *infoToBePreservedInNewNodes = [NSMutableDictionary dictionary];
        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:remoteNode] inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.status = SyncStatusSuccessful;
            
            // getting last modification date for remote sync node
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for local node
            NSMutableDictionary *localNodeInfoToBePreserved = [NSMutableDictionary dictionary];
            SyncNodeInfo *localNodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:remoteNode] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:privateManagedObjectContext];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:localNodeInfo.node];
            if (localNode)
            {
                // preserve node info until they are successfully downloaded or uploaded
                if (localNodeInfo.lastDownloadedDate)
                {
                    localNodeInfoToBePreserved[kLastDownloadedDateKey] = localNodeInfo.lastDownloadedDate;
                }
                if (localNodeInfo.syncContentPath)
                {
                    localNodeInfoToBePreserved[kSyncContentPathKey] = localNodeInfo.syncContentPath;
                }
            }
            infoToBePreservedInNewNodes[[self.syncHelper syncIdentifierForNode:remoteNode]] = localNodeInfoToBePreserved;
            
            NSDate *lastModifiedDateForLocal = localNode.modifiedAt;
            
            if (remoteNode.name.length > 0)
            {
                if ([self isNodeModifiedSinceLastDownload:remoteNode inManagedObjectContext:privateManagedObjectContext])
                {
                    [nodesToUpload addObject:remoteNode];
                    nodeStatus.status = SyncStatusWaiting;
                    nodeStatus.activityType = SyncActivityTypeUpload;
                }
                else
                {
                    if (lastModifiedDateForLocal != nil && lastModifiedDateForRemote != nil)
                    {
                        // Check if document is updated on server
                        BOOL reloadContent = [localNodeInfo.reloadContent intValue];
                        if (reloadContent || ([lastModifiedDateForLocal compare:lastModifiedDateForRemote] == NSOrderedAscending))
                        {
                            nodeStatus.status = SyncStatusWaiting;
                            nodeStatus.activityType = SyncActivityTypeDownload;
                            [nodesToDownload addObject:remoteNode];
                            localNodeInfoToBePreserved[kSyncReloadContentKey] = [NSNumber numberWithBool:YES];
                        }
                    }
                    else
                    {
                        nodeStatus.status = SyncStatusWaiting;
                        nodeStatus.activityType = SyncActivityTypeDownload;
                        [nodesToDownload addObject:remoteNode];
                        localNodeInfoToBePreserved[kSyncReloadContentKey] = [NSNumber numberWithBool:YES];
                    }
                }
            }
        }
        
        // block to syncs info and content for qualified nodes
        void (^syncInfoandContent)(void) = ^ void (void)
        {
            [self.syncHelper updateLocalSyncInfoWithRemoteInfo:self.syncNodesInfo[self.selectedAccountIdentifier]
                                              forAccountWithId:self.selectedAccountIdentifier
                                                  preserveInfo:infoToBePreservedInNewNodes
                                                   permissions:self.permissions
                                      refreshExistingSyncNodes:includeExistingSyncNodes
                                        inManagedObjectContext:privateManagedObjectContext];
            [self.syncNodesInfo removeObjectForKey:self.selectedAccountIdentifier];
            self.permissions = nil;
            self.isProcessingSyncNodes = NO;
            
            [self updateFolderSizes:YES andCheckIfAnyFileModifiedLocally:NO];
            unsigned long long totalDownloadSize = [self totalSizeForDocuments:nodesToDownload];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                AccountSyncProgress *syncProgress = self.accountsSyncProgress[self.selectedAccountIdentifier];
                syncProgress.totalSyncSize = 0;
                syncProgress.syncProgressSize = 0;
                
                if (totalDownloadSize > kDefaultMaximumAllowedDownloadSize)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.downloadsize.prompt.title", @"sync download size exceeded max alert title")
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"sync.downloadsize.prompt.message", @"Sync download size"), stringForLongFileSize(totalDownloadSize)]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"sync.downloadsize.prompt.cancel", @"Don't Sync")
                                                          otherButtonTitles:NSLocalizedString(@"sync.downloadsize.prompt.confirm", @"Sync Now"), nil];
                    
                    [alert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                        if (!isCancelButton)
                        {
                            syncProgress.totalSyncSize += totalDownloadSize;
                            [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                        }
                    }];
                }
                else
                {
                    syncProgress.totalSyncSize += totalDownloadSize;
                    [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                }
                
                syncProgress.totalSyncSize += [self totalSizeForDocuments:nodesToUpload];
                [self uploadContentsForNodes:nodesToUpload withCompletionBlock:nil];
                
                if ([self didEncounterObstaclesDuringSync])
                {
                    NSDictionary *syncObstacles = @{kSyncObstaclesKey : [self syncObstacles]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSyncObstaclesNotification object:nil userInfo:syncObstacles];
                }
            });
        };
        
        if (includeExistingSyncNodes)
        {
            [self deleteUnWantedSyncedNodes:nodes inManagedObjectContext:privateManagedObjectContext completionBlock:^(BOOL completed) {
                [self.syncCoreDataHelper saveContextForManagedObjectContext:privateManagedObjectContext];
                [privateManagedObjectContext reset];
                syncInfoandContent();
            }];
        }
        else
        {
            syncInfoandContent();
        }
    }
    else
    {
        [self.syncHelper removeSyncContentAndInfoInManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSDate *downloadedDate = nil;
    NSDate *localModificationDate = nil;
    if (node.isDocument)
    {
        // getting last downloaded date for node from local info
        downloadedDate = [self.syncHelper lastDownloadedDateForNode:node inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:managedContext];
        
        // getting downloaded file locally updated Date
        NSError *dateError = nil;
        
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:node] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:managedContext];
        NSString *pathToSyncedFile = nodeInfo.syncContentPath;
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    BOOL isModifiedLocally = ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
    
    if (isModifiedLocally)
    {
        SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
        
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [self contentPathForNode:(AlfrescoDocument *)node];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        if (!dateError)
        {
            nodeStatus.localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
        }
    }
    return isModifiedLocally;
}

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes inManagedObjectContext:(NSManagedObjectContext *)managedContext completionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableArray *identifiersForNodesToBeSynced = [self.syncHelper syncIdentifiersForNodes:nodes];
    NSMutableArray *missingSyncDocumentsInRemote = [NSMutableArray array];
    
    // retrieve stored nodes info for current selected account
    NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"isFolder == NO && account.accountId == %@", self.selectedAccountIdentifier];
    NSArray *localNodes = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:documentsPredicate inManagedObjectContext:managedContext];
    for (SyncNodeInfo *nodeInfo in localNodes)
    {
        // check if remote list dosnt have nodeInfo (indicates the node is removed from sync on server or deleted)
        
        if (![identifiersForNodesToBeSynced containsObject:nodeInfo.syncNodeInfoId])
        {
            [missingSyncDocumentsInRemote addObject:nodeInfo.syncNodeInfoId];
        }
    }
    
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleRemovedFromSync = [_syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    [syncObstableDeleted removeAllObjects];
    [syncObstacleRemovedFromSync removeAllObjects];
    
    __block NSInteger totalChecksForObstacles = missingSyncDocumentsInRemote.count;
    if (totalChecksForObstacles > 0)
    {
        for (NSString *nodeId in missingSyncDocumentsInRemote)
        {
            SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeId inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:managedContext];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            // check if there is any problem with removing the node from local sync
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [self checkForObstaclesInRemovingDownloadForNode:localNode inManagedObjectContext:managedContext completionBlock:^(BOOL encounteredObstacle) {
                    
                    totalChecksForObstacles--;
                    
                    if (encounteredObstacle == NO)
                    {
                        // if no problem with removing the node from local sync then delete the node from local sync nodes
                        [self.syncHelper deleteNodeFromSync:localNode inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:managedContext];
                    }
                    else
                    {
                        // if any problem encountered then set isRemovedFromSyncHasLocalChanges flag to YES so its not on deleted until its changes are synced to server
                        nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:YES];
                        nodeInfo.parentNode = nil;
                    }
                    
                    if (totalChecksForObstacles == 0)
                    {
                        if (completionBlock != NULL)
                        {
                            completionBlock(YES);
                        }
                    }
                }];
            });
        }
    }
    else
    {
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }
}

#pragma mark - Sync Obstacle Methods

- (BOOL)didEncounterObstaclesDuringSync
{
    BOOL obstacles = NO;
    
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleRemovedFromSync = [_syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if(syncObstableDeleted.count > 0 || syncObstacleRemovedFromSync.count > 0)
    {
        obstacles = YES;
    }
    
    return obstacles;
}

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:managedContext];
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleRemovedFromSync = [self.syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:[self.syncHelper syncIdentifierForNode:node] completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (alfrescoNode)
            {
                [syncObstacleRemovedFromSync addObject:node];
            }
            else
            {
                [syncObstableDeleted addObject:node];
            }
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
    else
    {
        if (completionBlock != NULL)
        {
            completionBlock(NO);
        }
    }
}

- (NSDictionary *)nodesWithObstacleDuringSync
{
    return self.syncObstacles;
}

- (void)syncFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer
{
    NSString *contentPath = [self contentPathForNode:document];
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:document.identifier];
    
    NSMutableArray *syncObstaclesRemovedFromSync = [self.syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if (syncToServer)
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            nodeStatus.status = SyncStatusRemoved;
            [self.syncHelper resolvedObstacleForDocument:document inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
    else
    {
        // copying to temporary location in order to rename the file to original name (sync uses node identifier as document name)
        NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:document.name];
        [self.fileManager copyItemAtPath:contentPath toPath:temporaryPath error:nil];
        
        [[DownloadManager sharedManager] saveDocument:document contentPath:temporaryPath completionBlock:^(NSString *filePath) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [self.fileManager removeItemAtPath:temporaryPath error:nil];
            nodeStatus.status = SyncStatusRemoved;
            [self.syncHelper resolvedObstacleForDocument:document inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesRemovedFromSyncNodeIdentifiers = [self.syncHelper syncIdentifiersForNodes:syncObstaclesRemovedFromSync];
    for (int i = 0;  i < syncObstaclesRemovedFromSyncNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesRemovedFromSyncNodeIdentifiers[i] isEqualToString:[self.syncHelper syncIdentifierForNode:document]])
        {
            [syncObstaclesRemovedFromSync removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document
{
    NSString *contentPath = [self contentPathForNode:document];
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    // copying to temporary location in order to rename the file to original name (sync uses node identifier as document name)
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:document.name];
    [self.fileManager copyItemAtPath:contentPath toPath:temporaryPath error:nil];
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:temporaryPath completionBlock:^(NSString *filePath) {
        [self.fileManager removeItemAtPath:contentPath error:nil];
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
        [self.syncHelper resolvedObstacleForDocument:document inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }];
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesDeletedNodeIdentifiers = [self.syncHelper syncIdentifiersForNodes:syncObstableDeleted];
    for (int i = 0;  i < syncObstaclesDeletedNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesDeletedNodeIdentifiers[i] isEqualToString:[self.syncHelper syncIdentifierForNode:document]])
        {
            [syncObstableDeleted removeObjectAtIndex:i];
            break;
        }
    }
}

#pragma mark - Private Utilities

- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount
{
    NSString *accountIdentifier = userAccount.accountIdentifier;
    
    if (userAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, userAccount.selectedNetworkId];
    }
    return accountIdentifier;
}

- (unsigned long long)totalSizeForDocuments:(NSArray *)documents
{
    unsigned long long totalSize = 0;
    
    for (AlfrescoDocument *document in documents)
    {
        totalSize += document.contentLength;
    }
    return totalSize;
}

- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo[self.selectedAccountIdentifier];
    NSMutableArray *topLevelSyncNodes = nodesInfoForSelectedAccount[self.selectedAccountIdentifier];
    BOOL isSyncNodesInfoInMemory = (topLevelSyncNodes != nil);
    
    void (^syncNode)(AlfrescoNode *) = ^ void (AlfrescoNode *nodeToBeSynced)
    {
        // start sync for this node only
        if ([self isSyncPreferenceOn])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:NO];
            });
        }
    };
    
    if (selectedAccount.isSyncOn)
    {
        [self showSyncAlertWithCompletionBlock:^(BOOL completed) {
            [self retrievePermissionsForNodes:@[node] withCompletionBlock:^{
                if (isSyncNodesInfoInMemory)
                {
                    [topLevelSyncNodes addObject:node];
                }
                else
                {
                    NSMutableDictionary *nodesInfoForSelectedAccount = [NSMutableDictionary dictionary];
                    self.syncNodesInfo[self.selectedAccountIdentifier] = nodesInfoForSelectedAccount;
                    nodesInfoForSelectedAccount[self.selectedAccountIdentifier] = [@[node] mutableCopy];
                }
                
                if (node.isFolder)
                {
                    [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                        if (self.nodeChildrenRequestsCount == 0)
                        {
                            syncNode(node);
                            if (completionBlock != NULL)
                            {
                                completionBlock(YES);
                            }
                        }
                    }];
                }
                else
                {
                    syncNode(node);
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }];
    }
    else
    {
        [topLevelSyncNodes addObject:node];
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }
}

- (void)removeNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo[self.selectedAccountIdentifier];
    
    if (nodesInfoForSelectedAccount)
    {
        NSMutableArray *topLevelSyncNodes = nodesInfoForSelectedAccount[self.selectedAccountIdentifier];
        NSMutableArray *topLevelSyncNodeIdentifiers = [self.syncHelper syncIdentifiersForNodes:topLevelSyncNodes];
        NSInteger nodeIndex = [topLevelSyncNodeIdentifiers indexOfObject:[self.syncHelper syncIdentifierForNode:node]];
        if (nodeIndex != NSNotFound)
        {
            [topLevelSyncNodes removeObjectAtIndex:nodeIndex];
        }
    }
    else
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:node] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
        if (nodeInfo)
        {
            nodeInfo.isTopLevelSyncNode = [NSNumber numberWithBool:NO];
            if (!nodeInfo.parentNode)
            {
                nodeStatus.totalSize = 0;
                nodeStatus.status = SyncStatusRemoved;
            }
            else
            {
                // this is to trigger notification so the sync root view updates its total count
                nodeStatus.totalSize = nodeStatus.totalSize;
            }
        }
        [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(YES);
    }
}

- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock
{
    SyncNodeStatus *syncNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
    syncNodeStatus.totalSize = 0;
    
    [self checkForObstaclesInRemovingDownloadForNode:node inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext completionBlock:^(BOOL encounteredObstacle) {
        
        if (node.isDocument && encounteredObstacle)
        {
            [self saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)node];
            completionBlock(YES);
        }
        else
        {
            [self.syncHelper deleteNodeFromSync:node inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
            completionBlock(NO);
        }
    }];
}

- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to download: %@", [nodes valueForKey:@"name"]);
    
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[self.selectedAccountIdentifier];
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self downloadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (syncOperationsForSelectedAccount.count == 0)
                {
                    [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
}

- (void)retrievePermissionsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(void))completionBlock
{
    if (!self.permissions)
    {
        self.permissions = [NSMutableDictionary dictionary];
    }
    
    __block NSInteger totalPermissionRequests = nodes.count;
    
    if (nodes.count == 0)
    {
        completionBlock();
    }
    else
    {
        for (AlfrescoNode *node in nodes)
        {
            [self.documentFolderService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                
                totalPermissionRequests--;
                
                if (permissions)
                {
                    self.permissions[[self.syncHelper syncIdentifierForNode:node]] = permissions;
                }
                
                if (totalPermissionRequests == 0 && completionBlock != NULL)
                {
                    completionBlock();
                }
            }];
        }
    }
}

- (void)downloadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSString *syncNameForNode = [self.syncHelper syncNameForNode:document inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] inSyncNodesStatus:self.syncNodesStatus];
    nodeStatus.status = SyncStatusLoading;
    
    NSString *destinationPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:self.selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    
    NSOperationQueue *syncQueueForSelectedAccount = self.syncQueues[self.selectedAccountIdentifier];
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[self.selectedAccountIdentifier];
    
    SyncOperation *downloadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           downloadDocument:document outputStream:outputStream
                                                                    downloadCompletionBlock:^(BOOL succeeded, NSError *error) {
                                                                        
                                                                        [outputStream close];
                                                                        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
                                                                        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                      inAccountWithId:self.selectedAccountIdentifier
                                                                                                                               inManagedObjectContext:privateManagedObjectContext];
                                                                        if (succeeded)
                                                                        {
                                                                            nodeStatus.status = SyncStatusSuccessful;
                                                                            nodeStatus.activityType = SyncActivityTypeIdle;
                                                                            
                                                                            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
                                                                            nodeInfo.lastDownloadedDate = [NSDate date];
                                                                            nodeInfo.syncContentPath = destinationPath;
                                                                            nodeInfo.reloadContent = [NSNumber numberWithBool:NO];
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                     inAccountWithId:self.selectedAccountIdentifier
                                                                                                                                ifNotExistsCreateNew:NO
                                                                                                                              inManagedObjectContext:privateManagedObjectContext];
                                                                            [self.syncCoreDataHelper deleteRecordForManagedObject:syncError inManagedObjectContext:privateManagedObjectContext];
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            nodeInfo.reloadContent = [NSNumber numberWithBool:YES];
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                     inAccountWithId:self.selectedAccountIdentifier
                                                                                                                                ifNotExistsCreateNew:YES
                                                                                                                              inManagedObjectContext:privateManagedObjectContext];
                                                                            syncError.errorCode = @(error.code);
                                                                            syncError.errorDescription = [error localizedDescription];
                                                                            
                                                                            nodeInfo.syncError = syncError;
                                                                        }
                                                                        [self.syncCoreDataHelper saveContextForManagedObjectContext:privateManagedObjectContext];
                                                                        [syncOperationsForSelectedAccount removeObjectForKey:[self.syncHelper syncIdentifierForNode:document]];
                                                                        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                        completionBlock(YES);
                                                                        
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        AccountSyncProgress *syncProgress = self.accountsSyncProgress[self.selectedAccountIdentifier];
                                                                        syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    syncOperationsForSelectedAccount[[self.syncHelper syncIdentifierForNode:document]] = downloadOperation;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    
    syncQueueForSelectedAccount.suspended = YES;
    [syncQueueForSelectedAccount addOperation:downloadOperation];
    syncQueueForSelectedAccount.suspended = NO;
}

- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload: %@", [nodes valueForKey:@"name"]);
    
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[self.selectedAccountIdentifier];
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (syncOperationsForSelectedAccount.count == 0)
                {
                    [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
}

- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSString *syncNameForNode = [self.syncHelper syncNameForNode:document inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    NSString *nodeExtension = [document.name pathExtension];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] inSyncNodesStatus:self.syncNodesStatus];
    nodeStatus.status = SyncStatusLoading;
    NSString *contentPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:self.selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];

    NSString *mimeType = document.contentMimeType;
    if (!mimeType)
    {
        mimeType = @"application/octet-stream";
        
        if (nodeExtension.length > 0)
        {
            mimeType = [Utility mimeTypeForFileExtension:nodeExtension];
        }
    }

    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:contentPath]];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:contentPath];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    NSOperationQueue *syncQueueForSelectedAccount = self.syncQueues[self.selectedAccountIdentifier];
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[self.selectedAccountIdentifier];
    
    SyncOperation *uploadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           uploadDocument:document
                                                                              inputStream:contentStream
                                                                    uploadCompletionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
                                                                        
                                                                        [readStream close];
                                                                        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
                                                                        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                      inAccountWithId:self.selectedAccountIdentifier
                                                                                                                               inManagedObjectContext:privateManagedObjectContext];
                                                                        if (uploadedDocument)
                                                                        {
                                                                            nodeStatus.status = SyncStatusSuccessful;
                                                                            nodeStatus.activityType = SyncActivityTypeIdle;
                                                                            
                                                                            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                            nodeInfo.lastDownloadedDate = [NSDate date];
                                                                            nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                     inAccountWithId:self.selectedAccountIdentifier
                                                                                                                                ifNotExistsCreateNew:NO
                                                                                                                              inManagedObjectContext:privateManagedObjectContext];
                                                                            [self.syncCoreDataHelper deleteRecordForManagedObject:syncError inManagedObjectContext:privateManagedObjectContext];
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document]
                                                                                                                                     inAccountWithId:self.selectedAccountIdentifier
                                                                                                                                ifNotExistsCreateNew:YES
                                                                                                                              inManagedObjectContext:privateManagedObjectContext];
                                                                            syncError.errorCode = @(error.code);
                                                                            syncError.errorDescription = [error localizedDescription];
                                                                            
                                                                            nodeInfo.syncError = syncError;
                                                                        }
                                                                        [self.syncCoreDataHelper saveContextForManagedObjectContext:privateManagedObjectContext];
                                                                        [syncOperationsForSelectedAccount removeObjectForKey:[self.syncHelper syncIdentifierForNode:document]];
                                                                        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                        if (completionBlock != NULL)
                                                                        {
                                                                            completionBlock(YES);
                                                                        }
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        AccountSyncProgress *syncProgress = self.accountsSyncProgress[self.selectedAccountIdentifier];
                                                                        syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    syncOperationsForSelectedAccount[[self.syncHelper syncIdentifierForNode:document]] = uploadOperation;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    [syncQueueForSelectedAccount addOperation:uploadOperation];
}

#pragma mark - Public Utilities

- (void)updateSessionIfNeeded:(id<AlfrescoSession>)session
{
    if(!self.alfrescoSession)
    {
        self.alfrescoSession = session;
    }
    if(!self.documentFolderService)
    {
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    }
    if(!self.selectedAccountIdentifier)
    {
        UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
        self.selectedAccountIdentifier = [self accountIdentifierForAccount:selectedAccount];
    }
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier
{
    [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:self.selectedAccountIdentifier];
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier inAccountWithId:(NSString *)accountId
{
    NSString *syncDocumentIdentifier = [Utility nodeRefWithoutVersionID:documentIdentifier];
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:syncDocumentIdentifier];
    
    NSMutableDictionary *syncOperationForAccount = self.syncOperations[accountId];
    SyncOperation *syncOperation = [syncOperationForAccount objectForKey:syncDocumentIdentifier];
    [syncOperation cancelOperation];
    [syncOperationForAccount removeObjectForKey:syncDocumentIdentifier];
    nodeStatus.status = SyncStatusFailed;
    
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:syncDocumentIdentifier
                                                                  inAccountWithId:self.selectedAccountIdentifier
                                                           inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:syncDocumentIdentifier
                                                             inAccountWithId:self.selectedAccountIdentifier
                                                        ifNotExistsCreateNew:YES
                                                      inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    syncError.errorCode = @(kSyncOperationCancelledErrorCode);
    nodeInfo.syncError = syncError;
    [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
    syncProgress.totalSyncSize -= nodeStatus.totalSize;
    syncProgress.syncProgressSize -= nodeStatus.bytesTransfered;
    nodeStatus.bytesTransfered = 0;
}

- (void)retrySyncForDocument:(AlfrescoDocument *)document completionBlock:(void (^)(void))completionBlock
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[self.syncHelper syncIdentifierForNode:document]];
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[self.selectedAccountIdentifier];
        syncProgress.totalSyncSize += document.contentLength;
        [self notifyProgressDelegateAboutCurrentProgress];
        
        if (nodeStatus.activityType == SyncActivityTypeDownload)
        {
            [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
                [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
        else
        {
            [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
                [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
    }
    else
    {
        if (nodeStatus.activityType != SyncActivityTypeDownload)
        {
            nodeStatus.status = SyncStatusWaiting;
            nodeStatus.activityType = SyncActivityTypeUpload;
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)cancelAllSyncOperationsForAccountWithId:(NSString *)accountId
{
    NSArray *syncDocumentIdentifiers = [self.syncOperations[accountId] allKeys];
    
    for (NSString *documentIdentifier in syncDocumentIdentifiers)
    {
        [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:accountId];
    }
    
    AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
    syncProgress.totalSyncSize = 0;
    syncProgress.syncProgressSize = 0;
}

- (void)cancelAllSyncOperations
{
    NSArray *syncOperationKeys = [self.syncOperations allKeys];
    
    for (NSString *accountId in syncOperationKeys)
    {
        [self cancelAllSyncOperationsForAccountWithId:accountId];
    }
}

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node
{
    BOOL isInSyncList = NO;
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:node] inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:nil];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode.boolValue || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (BOOL)isCurrentlySyncing
{
    __block BOOL isSyncing = NO;
    
    [self.syncQueues enumerateKeysAndObjectsUsingBlock:^(id key, NSOperationQueue *queue, BOOL *stop) {
        
        isSyncing = queue.operationCount > 0;
        
        if (isSyncing)
        {
            *stop = YES;
        }
    }];
    
    return isSyncing;
}

- (BOOL)isFirstUse
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    return !selectedAccount.didAskToSync;
}

/*
 * shows if sync is enabled based on cellular / wifi preference
 */
- (BOOL)isSyncEnabled
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    BOOL syncPreferenceEnabled = selectedAccount.isSyncOn;
    BOOL syncOnCellularEnabled = [[PreferenceManager sharedManager] shouldSyncOnCellular];
    
    if (syncPreferenceEnabled)
    {
        BOOL isCurrentlyOnCellular = [[ConnectivityManager sharedManager] isOnCellular];
        BOOL isCurrentlyOnWifi = [[ConnectivityManager sharedManager] isOnWifi];
        
        // if the device is on cellular and "sync on cellular" is set OR the device is on wifi, return YES
        if ((isCurrentlyOnCellular && syncOnCellularEnabled) || isCurrentlyOnWifi)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isSyncPreferenceOn
{
    UserAccount *userAccount = [[AccountManager sharedManager] selectedAccount];
    return userAccount.isSyncOn;
}

- (void)showSyncAlertWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AccountManager *accountManager = [AccountManager sharedManager];
    UserAccount *selectedAccount = accountManager.selectedAccount;
    
    if ([self isFirstUse] && !selectedAccount.isSyncOn)
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"sync.enable.message", @"Would you like to automatically keep your favorite documents in sync with this %@?"), [[UIDevice currentDevice] model]];
        [self displayConfirmationAlertWithTitle:NSLocalizedString(@"sync.enable.title", @"Sync Documents")
                                        message:message
                                completionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                                    
                                    selectedAccount.didAskToSync = YES;
                                    selectedAccount.isSyncOn = !isCancelButton;
                                    [accountManager saveAccountsToKeychain];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:selectedAccount];
                                    completionBlock(YES);
                                }];
    }
    else
    {
        completionBlock(YES);
    }
}

- (void)displayConfirmationAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(UIAlertViewDismissBlock)completionBlock
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [alert showWithCompletionBlock:completionBlock];
}

#pragma mark - UIAlertview Methods

- (void)updateFolderSizes:(BOOL)updateFolderSizes andCheckIfAnyFileModifiedLocally:(BOOL)checkIfModified
{
    if (updateFolderSizes)
    {
        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
        NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"account.accountId == %@", self.selectedAccountIdentifier];
        
        NSArray *documentsInfo = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:documentsPredicate inManagedObjectContext:privateManagedObjectContext];
        
        for (SyncNodeInfo *nodeInfo in documentsInfo)
        {
            SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:nodeInfo.syncNodeInfoId inSyncNodesStatus:self.syncNodesStatus];
            if (nodeInfo.isFolder.boolValue)
            {
                if (nodeInfo.nodes.count == 0)
                {
                    nodeStatus.status = SyncStatusSuccessful;
                }
            }
            else
            {
                AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
                SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
                nodeStatus.totalSize = ((AlfrescoDocument *)node).contentLength;
                
                if (checkIfModified && nodeStatus.activityType != SyncActivityTypeUpload)
                {
                    SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node]
                                                                             inAccountWithId:self.selectedAccountIdentifier
                                                                        ifNotExistsCreateNew:NO
                                                                      inManagedObjectContext:nil];
                    if (syncError || (nodeInfo.syncContentPath == nil))
                    {
                        nodeStatus.status = SyncStatusFailed;
                    }
                    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:privateManagedObjectContext];
                    if (isModifiedLocally)
                    {
                        nodeStatus.status = SyncStatusWaiting;
                        nodeStatus.activityType = SyncActivityTypeUpload;
                    }
                }
            }
        }
        [privateManagedObjectContext reset];
        privateManagedObjectContext = nil;
    }
}

#pragma mark - Status Changed Notification Handling

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
    
    SyncNodeStatus *nodeStatus = notification.object;
    NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
    
    // update total size for parent folder
    if ([propertyChanged isEqualToString:kSyncTotalSize])
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeStatus.nodeId inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:privateManagedObjectContext];
        
        SyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
        if (parentNodeInfo)
        {
            AlfrescoNode *parentNode = [NSKeyedUnarchiver unarchiveObjectWithData:parentNodeInfo.node];
            SyncNodeStatus *parentNodeStatus = [self syncStatusForNodeWithId:[self.syncHelper syncIdentifierForNode:parentNode]];
            
            NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
            parentNodeStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
        }
        else
        {
            // if parent folder is nil - update total size for account
            SyncNodeStatus *accountSyncStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:self.selectedAccountIdentifier inSyncNodesStatus:self.syncNodesStatus];
            if (nodeStatus != accountSyncStatus)
            {
                NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
                accountSyncStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
            }
        }
    }
    // update sync status for folder depending on its child nodes statuses
    else if ([propertyChanged isEqualToString:kSyncStatus])
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeStatus.nodeId inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:privateManagedObjectContext];
        SyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
        
        if (parentNodeInfo)
        {
            NSString *parentNodeId = parentNodeInfo.syncNodeInfoId;
            SyncNodeStatus *parentNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:parentNodeId inSyncNodesStatus:self.syncNodesStatus];
            NSSet *subNodes = parentNodeInfo.nodes;
            
            SyncStatus syncStatus = SyncStatusSuccessful;
            for (SyncNodeInfo *subNodeInfo in subNodes)
            {
                SyncNodeStatus *subNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:subNodeInfo.syncNodeInfoId inSyncNodesStatus:self.syncNodesStatus];
                
                if (subNodeStatus.status == SyncStatusLoading)
                {
                    syncStatus = SyncStatusLoading;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusFailed)
                {
                    syncStatus = SyncStatusFailed;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusOffline)
                {
                    syncStatus = SyncStatusOffline;
                    parentNodeStatus.activityType = SyncActivityTypeUpload;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusWaiting)
                {
                    syncStatus = SyncStatusWaiting;
                }
            }
            parentNodeStatus.status = syncStatus;
        }
    }
    
    [privateManagedObjectContext reset];
    privateManagedObjectContext = nil;
}

#pragma mark - Sync Progress Information Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncProgressSizeKey])
    {
        [self notifyProgressDelegateAboutCurrentProgress];
    }
}

- (void)notifyProgressDelegateAboutNumberOfNodesInProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(numberOfSyncOperationsInProgress:)])
    {
        NSMutableDictionary *syncOperations = self.syncOperations[self.selectedAccountIdentifier];
        [self.progressDelegate numberOfSyncOperationsInProgress:syncOperations.count];
    }
}

- (void)notifyProgressDelegateAboutCurrentProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(totalSizeToSync:syncedSize:)])
    {
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[self.selectedAccountIdentifier];
        [self.progressDelegate totalSizeToSync:syncProgress.totalSyncSize syncedSize:syncProgress.syncProgressSize];
    }
}

#pragma mark - Account Notifications

- (void)accountInfoUpdated:(NSNotification *)notification
{
    UserAccount *notificationAccount = notification.object;
    
    if (!notificationAccount.isSyncOn)
    {
        NSString *notificationAccountIdentifier = [self accountIdentifierForAccount:notificationAccount];
        [self cancelAllSyncOperationsForAccountWithId:notificationAccountIdentifier];
        [self.syncHelper removeSyncContentAndInfoForAccountWithId:notificationAccountIdentifier syncNodeStatuses:self.syncNodesStatus inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *notificationAccount = notification.object;
    
    NSString *notificationAccountIdentifier = [self accountIdentifierForAccount:notificationAccount];
    [self cancelAllSyncOperationsForAccountWithId:notificationAccountIdentifier];
    [self.syncHelper removeSyncContentAndInfoForAccountWithId:notificationAccountIdentifier syncNodeStatuses:self.syncNodesStatus inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
}

#pragma mark - Reachibility Changed Notification

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    
    if(hasInternetConnection != self.lastConnectivityFlag)
    {
        self.lastConnectivityFlag = hasInternetConnection;
        if(hasInternetConnection)
        {
            [self syncDocumentsAndFoldersForSession:self.alfrescoSession withCompletionBlock:nil];
        }
    }
}

#pragma mark - Upload Node Notification

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *infoDictionary = notification.object;
    AlfrescoFolder *parentFolder = infoDictionary[kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([self isNodeInSyncList:parentFolder])
    {
        AlfrescoNode *subNode = [infoDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:subNode] inSyncNodesStatus:self.syncNodesStatus];
        
        [self retrievePermissionsForNodes:@[subNode] withCompletionBlock:^{
            
            [self.syncHelper populateNodes:@[subNode]
                            inParentFolder:[self.syncHelper syncIdentifierForNode:parentFolder]
                          forAccountWithId:self.selectedAccountIdentifier
                              preserveInfo:nil
                               permissions:self.permissions
                    inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
            
            if (subNode.isFolder)
            {
                nodeStatus.status = SyncStatusSuccessful;
            }
            else
            {
                NSString *syncNameForNode = [self.syncHelper syncNameForNode:subNode inAccountWithId:self.selectedAccountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:[self.syncHelper syncIdentifierForNode:subNode]
                                                                              inAccountWithId:self.selectedAccountIdentifier
                                                                       inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                
                NSURL *contentLocation = infoDictionary[kAlfrescoNodeAddedOnServerContentLocationLocally];
                NSString *destinationPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:self.selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
                NSURL *destinationURL = [NSURL fileURLWithPath:destinationPath];
                
                NSError *error = nil;
                [[AlfrescoFileManager sharedManager] copyItemAtURL:contentLocation toURL:destinationURL error:&error];
                
                nodeStatus.totalSize = [(AlfrescoDocument *)subNode contentLength];
                if (error)
                {
                    nodeStatus.status = SyncStatusFailed;
                }
                else
                {
                    nodeStatus.status = SyncStatusSuccessful;
                    nodeStatus.activityType = SyncActivityTypeIdle;
                    
                    nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:subNode];
                    nodeInfo.lastDownloadedDate = [NSDate date];
                    nodeInfo.syncContentPath = destinationPath;
                    nodeInfo.reloadContent = [NSNumber numberWithBool:NO];
                }
            }
            [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
}

@end
