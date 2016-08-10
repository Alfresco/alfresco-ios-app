/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "UserAccount.h"
#import "AccountSyncProgress.h"
#import "SyncOperation.h"
#import "AlfrescoFileManager+Extensions.h"
#import "ConnectivityManager.h"
#import "AppConfigurationManager.h"
#import "DownloadManager.h"
#import "PreferenceManager.h"
#import "RealmSyncManager+Internal.h"

@implementation RealmSyncManager

#pragma mark - Singleton
+ (RealmSyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _fileManager = [AlfrescoFileManager sharedManager];
        _syncNodesInfo = [NSMutableDictionary dictionary];
        _syncNodesStatus = [NSMutableDictionary dictionary];
        
        _syncQueues = [NSMutableDictionary dictionary];
        
        _syncObstacles = @{kDocumentsRemovedFromSyncOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        
        _realmManager = [RealmManager sharedManager];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:kSyncStatusChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedProfileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainMenuConfigurationChanged:) name:kAlfrescoConfigFileDidUpdateNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (RLMRealm *)mainThreadRealm
{
    _mainThreadRealm = [self realmForAccount:[AccountManager sharedManager].selectedAccount.accountIdentifier];
    
    return _mainThreadRealm;
}

#pragma mark - Sync Feature
- (RLMRealm *)realmForAccount:(NSString *)accountId
{
    return [self.realmManager createRealmWithName:accountId];
}

- (void)deleteRealmForAccount:(UserAccount *)account
{
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [[RealmManager sharedManager] resetDefaultRealmConfiguration];
    }
    
    _mainThreadRealm = nil;
    [self.realmManager deleteRealmWithName:account.accountIdentifier];
    [self.syncDisabledDelegate syncFeatureStatusChanged:NO];
}

- (void)determineSyncFeatureStatus:(UserAccount *)changedAccount selectedProfile:(AlfrescoProfileConfig *)selectedProfile
{
    [[AppConfigurationManager sharedManager] isViewOfType:kAlfrescoConfigViewTypeSync presentInProfile:selectedProfile forAccount:changedAccount completionBlock:^(BOOL isViewPresent, NSError *error) {
        if(!error && (isViewPresent != changedAccount.isSyncOn))
        {
            if(isViewPresent)
            {
                [self realmForAccount:changedAccount.accountIdentifier];
                changedAccount.isSyncOn = YES;
                [[AccountManager sharedManager] saveAccountsToKeychain];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:changedAccount];
                if([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
                {
                    [[RealmManager sharedManager] changeDefaultConfigurationForAccount:changedAccount];
                }
            }
            else
            {
                [self disableSyncForAccountFromConfig:changedAccount];
            }
        }
    }];
}

- (void)disableSyncForAccount:(UserAccount*)account fromViewController:(UIViewController *)presentingViewController cancelBlock:(void (^)(void))cancelBlock completionBlock:(void (^)(void))completionBlock
{
    if([self isCurrentlySyncing])
    {
        UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.pendingoperations.title", @"Pending sync operations") message:NSLocalizedString(@"action.pendingoperations.message", @"Stop pending operations") preferredStyle:UIAlertControllerStyleAlert];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            cancelBlock();
        }]];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.confirm", @"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cleanUpAccount:account cancelOperationsType:CancelAllOperations];
            completionBlock();
        }]];
        
        [presentingViewController presentViewController:confirmAlert animated:YES completion:nil];
    }
    else
    {
        [self cleanUpAccount:account cancelOperationsType:CancelOperationsNone];
        completionBlock();
    }
}

- (void)disableSyncForAccountFromConfig:(UserAccount *)account
{
    [self cleanUpAccount:account cancelOperationsType:CancelDownloadOperations];
}

- (void)cleanUpAccount:(UserAccount *)account cancelOperationsType:(CancelOperationsType)cancelType
{
    if (cancelType != CancelOperationsNone)
    {
        SyncOperationQueueManager *syncOpQM = self.syncQueues[account.accountIdentifier];
        [syncOpQM cancelOperationsType:cancelType];
    }
    
    //Clean sync statuses in FileFolderCollectionViewCells and AlfrescoNodeCells.
    NSArray *alfrescoNodes = [[RealmManager sharedManager] alfrescoNodesForSyncNodesInRealm:[RLMRealm defaultRealm]];
    if (alfrescoNodes.count)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kTopLevelSyncDidRemoveNodeNotification object:alfrescoNodes];
    }
    
    //Empty syncNodesStatus dictionary.
    self.syncNodesStatus = [NSMutableDictionary dictionary];
    
    [self deleteRealmForAccount:account];
    account.isSyncOn = NO;
    [[AccountManager sharedManager] saveAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
}

- (void)enableSyncForAccount:(UserAccount *)account
{
    account.isSyncOn = YES;
    [[AccountManager sharedManager] saveAccountsToKeychain];
    [self realmForAccount:account.accountIdentifier];
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [self.syncDisabledDelegate syncFeatureStatusChanged:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
}

#pragma mark - Sync operations
- (void)deleteNodeFromSync:(AlfrescoNode *)node deleteRule:(DeleteRule)deleteRule withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock
{
    if(node)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
            NSMutableArray *arrayOfNodesToDelete = [NSMutableArray new];
            NSMutableArray *arrayOfNodesToSaveLocally = [NSMutableArray new];
            NSMutableArray *arrayOfPathsForFilesToBeDeleted = [NSMutableArray new];
            
            if(node.isDocument)
            {
                [weakSelf handleDocumentForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm deleteRule:deleteRule];
            }
            else if(node.isFolder)
            {
                [weakSelf handleFolderForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm deleteRule:deleteRule];
            }
            
            BOOL hasSavedLocally = NO;
            
            if(arrayOfNodesToSaveLocally.count)
            {
                hasSavedLocally = YES;
                for(AlfrescoDocument *document in arrayOfNodesToSaveLocally)
                {
                    if (deleteRule == DeleteRuleAllNodes)
                    {
                        [weakSelf saveDeletedFileBeforeRemovingFromSync:document];
                    }
                    else
                    {
                        RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:document.identifier ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                        
                        [backgroundRealm beginWriteTransaction];
                        syncNodeInfo.isRemovedFromSyncHasLocalChanges = YES;
                        [backgroundRealm commitWriteTransaction];
                        
                        [[RealmSyncManager sharedManager] uploadDocument:document withCompletionBlock:^(BOOL completed)
                         {
                             if (completed)
                             {
                                 [self deleteNodeFromSync:document deleteRule:DeleteRuleRootByForceAndKeepTopLevelChildren withCompletionBlock:nil];
                             }
                         }];
                    }
                }
            }
            
            [[RealmManager sharedManager] deleteRealmObjects:arrayOfNodesToDelete inRealm:backgroundRealm];
            for(NSString *path in arrayOfPathsForFilesToBeDeleted)
            {
                // No error handling here as we don't want to end up with Sync orphans
                [weakSelf.fileManager removeItemAtPath:path error:nil];
            }
            
            completionBlock(hasSavedLocally);
        });
    }
}

- (void)handleDocumentForDelete:(AlfrescoNode *)document arrayOfNodesToDelete:(NSMutableArray *)arrayToDelete arrayOfNodesToSaveLocally:(NSMutableArray *)arrayToSave arrayOfPaths:(NSMutableArray *)arrayOfPaths inRealm:(RLMRealm *)realm deleteRule:(DeleteRule)deleteRule
{
    SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
    SyncNodeStatus *syncNodeStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:[document syncIdentifier]];
    syncNodeStatus.totalSize = 0;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[document syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    
    if(nodeInfo && nodeInfo.isTopLevelSyncNode && deleteRule != DeleteRuleAllNodes)
    {
        return;
    }
    
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:document inRealm:realm];
    if(isModifiedLocally)
    {
        [arrayToSave addObject:document];
    }
    else
    {
        if (nodeInfo)
        {
            [arrayToDelete addObject:nodeInfo];
        }
        
        NSString *nodeSyncName = [document syncNameInRealm:realm];
        NSString *syncNodeContentPath = [[self syncContentDirectoryPathForAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier] stringByAppendingPathComponent:nodeSyncName];
        if(syncNodeContentPath && nodeSyncName)
        {
            [arrayOfPaths addObject:syncNodeContentPath];
        }
        
        return;
    }
    
    if (deleteRule == DeleteRuleAllNodes)
    {
        if (nodeInfo)
        {
            [arrayToDelete addObject:nodeInfo];
        }
        
        NSString *nodeSyncName = [document syncNameInRealm:realm];
        NSString *syncNodeContentPath = [[self syncContentDirectoryPathForAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier] stringByAppendingPathComponent:nodeSyncName];
        if(syncNodeContentPath && nodeSyncName)
        {
            [arrayOfPaths addObject:syncNodeContentPath];
        }
    }
}

- (void)handleFolderForDelete:(AlfrescoNode *)folder arrayOfNodesToDelete:(NSMutableArray *)arrayToDelete arrayOfNodesToSaveLocally:(NSMutableArray *)arrayToSave arrayOfPaths:(NSMutableArray *)arrayOfPaths inRealm:(RLMRealm *)realm deleteRule:(DeleteRule)deleteRule
{
    RealmSyncNodeInfo *folderInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[folder syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    
    if (folderInfo && folderInfo.isTopLevelSyncNode && deleteRule == DeleteRuleRootAndAndKeepTopLevelChildren)
    {
        return;
    }
    
    if (deleteRule == DeleteRuleRootByForceAndKeepTopLevelChildren)
    {
        deleteRule = DeleteRuleRootAndAndKeepTopLevelChildren;
    }
    
    if(folderInfo)
    {
        [arrayToDelete addObject:folderInfo];
    }
    RLMLinkingObjects *subNodes = folderInfo.nodes;
    for(RealmSyncNodeInfo *subNodeInfo in subNodes)
    {
        AlfrescoNode *subNode = subNodeInfo.alfrescoNode;
        if(subNode.isDocument)
        {
            [self handleDocumentForDelete:subNode arrayOfNodesToDelete:arrayToDelete arrayOfNodesToSaveLocally:arrayToSave arrayOfPaths:arrayOfPaths inRealm:realm deleteRule:deleteRule];
        }
        else if(subNode.isFolder)
        {
            [self handleFolderForDelete:subNode arrayOfNodesToDelete:arrayToDelete arrayOfNodesToSaveLocally:arrayToSave arrayOfPaths:arrayOfPaths inRealm:realm deleteRule:deleteRule];
        }
    }
}

- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document
{
    NSString *contentPath = [document contentPath];
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    // copying to temporary location in order to rename the file to original name (sync uses node identifier as document name)
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:document.name];
    if([self.fileManager fileExistsAtPath:temporaryPath])
    {
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
    }
    [self.fileManager copyItemAtPath:contentPath toPath:temporaryPath error:nil];
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:temporaryPath completionBlock:^(NSString *filePath) {
        [self.fileManager removeItemAtPath:contentPath error:nil];
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [[RealmManager sharedManager] resolvedObstacleForDocument:document inRealm:realm];
    }];
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesDeletedNodeIdentifiers = [AlfrescoNode syncIdentifiersForNodes:syncObstableDeleted];
    for (int i = 0;  i < syncObstaclesDeletedNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesDeletedNodeIdentifiers[i] isEqualToString:[document syncIdentifier]])
        {
            [syncObstableDeleted removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)cancelAllSyncOperations
{
    for (SyncOperationQueueManager *syncOpQM in self.syncQueues.allValues)
    {
        [syncOpQM cancelOperationsType:CancelAllOperations];
    }
}

- (void)cancelAllDownloadOperationsForAccountWithId:(NSString *)accountId
{
    SyncOperationQueueManager *syncOpQM = self.syncQueues[accountId];
    [syncOpQM cancelOperationsType:CancelDownloadOperations];
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier
{
    SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
    [syncOpQM cancelSyncForDocumentWithIdentifier:documentIdentifier];
}

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inRealm:realm];
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:[node syncIdentifier] completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (error)
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

- (BOOL)isCurrentlySyncing
{
    __block BOOL isSyncing = NO;
    
    [self.syncQueues enumerateKeysAndObjectsUsingBlock:^(id key, SyncOperationQueueManager *queue, BOOL *stop) {
        
        isSyncing = [queue isCurrentlySyncing];
        
        if (isSyncing)
        {
            *stop = YES;
        }
    }];
    
    return isSyncing;
}

- (void)retrySyncForDocument:(AlfrescoDocument *)document completionBlock:(void (^)(void))completionBlock
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[document syncIdentifier]];
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
        
        if (nodeStatus.activityType == SyncActivityTypeDownload)
        {
            [syncOpQM downloadDocument:document withCompletionBlock:^(BOOL completed) {
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
        else
        {
            [syncOpQM uploadDocument:document withCompletionBlock:^(BOOL completed) {
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

- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
    [syncOpQM uploadDocument:document withCompletionBlock:^(BOOL completed) {
        if (completionBlock)
        {
            completionBlock(completed);
        }
    }];
}

- (void)didUploadNode:(AlfrescoNode *)node fromPath:(NSString *)tempPath toFolder:(AlfrescoFolder *)folder
{
    if([AccountManager sharedManager].selectedAccount.isSyncOn)
    {
        RLMRealm *realm = [[RealmManager sharedManager] createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
        if([folder isNodeInSyncListInRealm:realm])
        {
            NSString *syncNameForNode = [node syncNameInRealm:realm];
            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[node syncIdentifier] ifNotExistsCreateNew:YES inRealm:realm];
            RealmSyncNodeInfo *parentSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[folder syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
            
            [realm beginWriteTransaction];
            syncNodeInfo.parentNode = parentSyncNodeInfo;
            syncNodeInfo.isTopLevelSyncNode = NO;
            [realm commitWriteTransaction];
            
            SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
            SyncNodeStatus *nodeStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:[node syncIdentifier]];
            
            if(node.isDocument)
            {
                NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
                NSString *syncContentPath = [[self syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
                
                NSError *movingFileError = nil;
                [[AlfrescoFileManager sharedManager] copyItemAtPath:tempPath toPath:syncContentPath error:&movingFileError];
                
                if(movingFileError)
                {
                    nodeStatus.status = SyncStatusFailed;
                    
                    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[node syncIdentifier] ifNotExistsCreateNew:YES inRealm:realm];
                    [realm beginWriteTransaction];
                    syncError.errorCode = movingFileError.code;
                    syncError.errorDescription = [movingFileError localizedDescription];
                    
                    syncNodeInfo.syncError = syncError;
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
                else
                {
                    [[RealmManager sharedManager] updateSyncNodeInfoWithId:[node syncIdentifier] withNode:node lastDownloadedDate:[NSDate date] syncContentPath:syncNameForNode inRealm:realm];
                    nodeStatus.status = SyncStatusSuccessful;
                    nodeStatus.activityType = SyncActivityTypeIdle;
                    [realm beginWriteTransaction];
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
            }
            else if (node.isFolder)
            {
                [[RealmManager sharedManager] updateSyncNodeInfoWithId:[node syncIdentifier] withNode:node lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
                nodeStatus.status = SyncStatusSuccessful;
                nodeStatus.activityType = SyncActivityTypeIdle;
            }
        }
    }
}

- (void)didUploadNewVersionForDocument:(AlfrescoDocument *)document updatedDocument:(AlfrescoDocument *)updatedDocument fromPath:(NSString *)path
{
    if([AccountManager sharedManager].selectedAccount.isSyncOn)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RLMRealm *backgroundRealm = [[RealmManager sharedManager] createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if([document isNodeInSyncListInRealm:backgroundRealm])
            {
                RealmSyncNodeInfo *documentInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[document syncIdentifier] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                [backgroundRealm beginWriteTransaction];
                documentInfo.node = [NSKeyedArchiver archivedDataWithRootObject:updatedDocument];
                documentInfo.lastDownloadedDate = [NSDate date];
                [backgroundRealm commitWriteTransaction];
                
                [self.fileManager removeItemAtPath:[document contentPath] error:nil];
                [self.fileManager moveItemAtPath:path toPath:[document contentPath] error:nil];
            }
        });
    }
}

- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    if (selectedAccount.isSyncOn)
    {
        [self retrievePermissionsForNodes:@[node] withCompletionBlock:^{
            
            SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
            if (node.isFolder == NO)
            {
                [syncOpQM addDocumentToSync:(AlfrescoDocument *)node isTopLevelNode:YES withCompletionBlock:completionBlock];
            }
            else
            {
                self.syncNodesInfo = [NSMutableDictionary new];
                [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                    if(self.nodeChildrenRequestsCount == 0)
                    {
                        syncOpQM.syncNodesInfo = self.syncNodesInfo;
                        [syncOpQM addFolderToSync:(AlfrescoFolder *)node isTopLevelNode:YES];
                        if(completionBlock)
                        {
                            completionBlock(completed);
                        }
                    }
                }];
            }
        }];
    }
}

- (void)retrieveNodeHierarchyForNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo;
    
    if ([nodesInfoForSelectedAccount objectForKey:[node syncIdentifier]] == nil)
    {
        self.nodeChildrenRequestsCount++;
        [self.documentFolderService retrieveChildrenInFolder:(AlfrescoFolder *)node completionBlock:^(NSArray *array, NSError *error) {
            
            self.nodeChildrenRequestsCount--;
            if (array)
            {
                // nodes for each folder are held in with keys folder identifiers
                nodesInfoForSelectedAccount[[node syncIdentifier]] = array;
                [self retrievePermissionsForNodes:array withCompletionBlock:^{
                    
                    for (AlfrescoNode *node in array)
                    {
                        if(node.isFolder)
                        {
                            // recursive call to retrieve nodes hierarchies
                            [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                                
                                if (completionBlock != NULL)
                                {
                                    completionBlock(YES);
                                }
                            }];
                        }
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

#pragma mark - Sync node information
- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    NSDate *downloadedDate = nil;
    NSDate *localModificationDate = nil;
    if (node.isDocument)
    {
        // getting last downloaded date for node from local info
        downloadedDate = [node lastDownloadedDateInRealm:realm];
        
        // getting downloaded file locally updated Date
        NSError *dateError = nil;
        
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[node syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
        NSString *pathToSyncedFile = nodeInfo.syncContentPath;
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    BOOL isModifiedLocally = ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
    
    if (isModifiedLocally)
    {
        SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
        SyncNodeStatus *nodeStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:[node syncIdentifier]];
        
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [node contentPath];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        if (!dateError)
        {
            nodeStatus.localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
        }
    }
    return isModifiedLocally;
}

- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node
{
    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[node syncIdentifier] ifNotExistsCreateNew:NO inRealm:self.mainThreadRealm];
    return syncError.errorDescription;
}

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncOperationQueueManager *syncOpQManager = [self currentOperationQueueManager];
    SyncNodeStatus *nodeStatus = [syncOpQManager syncNodeStatusObjectForNodeWithId:syncNodeId];
    return nodeStatus;
}

- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = [self.permissions objectForKey:[node syncIdentifier]];
    
    if (!permissions)
    {
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[node syncIdentifier] ifNotExistsCreateNew:NO inRealm:[RLMRealm defaultRealm]];
        
        if (nodeInfo.permissions)
        {
            permissions = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.permissions];
        }
    }
    return permissions;
}

#pragma mark - NSNotifications
- (void)selectedProfileDidChange:(NSNotification *)notification
{
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    AlfrescoProfileConfig *selectedProfile = notification.object;
    [self determineSyncFeatureStatus:changedAccount selectedProfile:selectedProfile];
}

- (void)sessionReceived:(NSNotification *)notification
{
    UserAccount *changedAccount = [AccountManager sharedManager].selectedAccount;
    [[RealmManager sharedManager] changeDefaultConfigurationForAccount:changedAccount];
    AlfrescoProfileConfig *selectedProfileForAccount = [AppConfigurationManager sharedManager].selectedProfile;
    [self determineSyncFeatureStatus:changedAccount selectedProfile:selectedProfileForAccount];
    
    id<AlfrescoSession> session = notification.object;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    
    self.selectedAccountSyncIdentifier = changedAccount.accountIdentifier;
    SyncOperationQueueManager *syncOperationQueueManager = self.syncQueues[self.selectedAccountSyncIdentifier];
    
    if (!syncOperationQueueManager)
    {
        syncOperationQueueManager = [[SyncOperationQueueManager alloc] initWithAccount:changedAccount session:session syncProgressDelegate:nil];
        self.syncQueues[self.selectedAccountSyncIdentifier] = syncOperationQueueManager;
    }
    
//    syncQueue.suspended = NO;
//    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
}

- (void)mainMenuConfigurationChanged:(NSNotification *)notification
{
    // if no object is passed with the notification then we have no accounts in the app
    if(notification.object)
    {
        if([notification.object respondsToSelector:@selector(account)])
        {
            UserAccount *changedAccount = [notification.object performSelector:@selector(account)];
            AlfrescoConfigService *configServiceForAccount = [[AppConfigurationManager sharedManager] configurationServiceForAccount:changedAccount];
            [configServiceForAccount retrieveProfileWithIdentifier:changedAccount.selectedProfileIdentifier completionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                if(config)
                {
                    [self determineSyncFeatureStatus:changedAccount selectedProfile:config];
                }
            }];
        }
    }
}

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    RLMRealm *realm = [RLMRealm defaultRealm];
    UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
    
    SyncNodeStatus *nodeStatus = notification.object;
    NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:nodeStatus.nodeId ifNotExistsCreateNew:NO inRealm:realm];
    RealmSyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
    SyncOperationQueueManager *syncOpQM = self.syncQueues[selectedAccount.accountIdentifier];
    // update total size for parent folder
    if ([propertyChanged isEqualToString:kSyncTotalSize])
    {
        if (parentNodeInfo)
        {
            AlfrescoNode *parentNode = [NSKeyedUnarchiver unarchiveObjectWithData:parentNodeInfo.node];
            SyncNodeStatus *parentNodeStatus = [self syncStatusForNodeWithId:[parentNode syncIdentifier]];
            
            NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
            parentNodeStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
        }
        else
        {
            // if parent folder is nil - update total size for account
            SyncNodeStatus *accountSyncStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:selectedAccount.accountIdentifier];
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
        if (parentNodeInfo)
        {
            NSString *parentNodeId = parentNodeInfo.syncNodeInfoId;
            SyncNodeStatus *parentNodeStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:parentNodeId];
            RLMLinkingObjects *subNodes = parentNodeInfo.nodes;
            
            SyncStatus syncStatus = SyncStatusSuccessful;
            for (RealmSyncNodeInfo *subNodeInfo in subNodes)
            {
                SyncNodeStatus *subNodeStatus = [syncOpQM syncNodeStatusObjectForNodeWithId:subNodeInfo.syncNodeInfoId];
                
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
}

#pragma mark - Realm notifications
- (RLMNotificationToken *)notificationTokenForAlfrescoNode:(AlfrescoNode *)node notificationBlock:(void (^)(RLMResults<RealmSyncNodeInfo *> *results, RLMCollectionChange *change, NSError *error))block
{
    RLMNotificationToken *token = nil;
    
    if(node)
    {
        token = [[RealmSyncNodeInfo objectsInRealm:[self mainThreadRealm] where:@"syncNodeInfoId == %@", [node syncIdentifier]] addNotificationBlock:block];
    }
    else
    {
        token = [[RealmSyncNodeInfo objectsInRealm:[self mainThreadRealm] where:@"isTopLevelSyncNode = %@", @YES] addNotificationBlock:block];
    }
    
    return token;
}

#pragma mark - Private methods

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
                    self.permissions[[node syncIdentifier]] = permissions;
                }
                
                if (totalPermissionRequests == 0 && completionBlock != NULL)
                {
                    completionBlock();
                }
            }];
        }
    }
}

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    NSString *nodeSyncName = [node syncNameInRealm:realm];
    NSString *syncNodeContentPath = [[self syncContentDirectoryPathForAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier] stringByAppendingPathComponent:nodeSyncName];
    
    // No error handling here as we don't want to end up with Sync orphans
    [self.fileManager removeItemAtPath:syncNodeContentPath error:nil];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[node syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    [[RealmManager sharedManager] deleteRealmObject:nodeInfo inRealm:realm];
}

- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountId
{
    NSString *contentDirectory = [self.fileManager syncFolderPath];
    if (accountId)
    {
        contentDirectory = [contentDirectory stringByAppendingPathComponent:accountId];
    }
    
    BOOL dirExists = [self.fileManager fileExistsAtPath:contentDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return contentDirectory;
}

- (void)setProgressDelegate:(id<RealmSyncManagerProgressDelegate>)progressDelegate
{
    _progressDelegate = progressDelegate;
    SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
    syncOpQM.progressDelegate = self.progressDelegate;
}

#pragma mark - Internal methods
- (SyncOperationQueueManager *)currentOperationQueueManager
{
    SyncOperationQueueManager *syncOpQM = self.syncQueues[[AccountManager sharedManager].selectedAccount.accountIdentifier];
    return syncOpQM;
}

@end
