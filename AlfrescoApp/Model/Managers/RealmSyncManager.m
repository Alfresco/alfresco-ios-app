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
#import "AppConfigurationManager.h"
#import "DownloadManager.h"
#import "PreferenceManager.h"
#import "RealmSyncManager+Internal.h"
#import "AlfrescoNode+Networking.h"
#import "UserAccount+FileHandling.h"
#import "MainMenuItemsVisibilityUtils.h"
#import "UniversalDevice.h"

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
        
        _syncQueues = [NSMutableDictionary dictionary];
        
        _syncObstacles = @{kDocumentsRemovedFromSyncOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        
        _realmManager = [RealmManager sharedManager];
        
        _unsyncCompletionBlocks = [NSMutableDictionary new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(statusChanged:) name:kSyncStatusChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedProfileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionRefreshedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainMenuConfigurationChanged:) name:kAlfrescoConfigFileDidUpdateNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kAlfrescoConnectivityChangedNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    
    [self.realmManager deleteRealmWithName:account.accountIdentifier];
    [self.syncDisabledDelegate syncFeatureStatusChanged:NO];
}

- (void)determineSyncFeatureStatus:(UserAccount *)changedAccount selectedProfile:(AlfrescoProfileConfig *)selectedProfile
{
    [MainMenuItemsVisibilityUtils isViewOfType:kAlfrescoConfigViewTypeSync presentInProfile:selectedProfile forAccount:changedAccount completionBlock:^(BOOL isViewPresent, NSError *error) {
        if(!error && (isViewPresent != changedAccount.isSyncOn))
        {
            if(isViewPresent)
            {
                [self realmForAccount:changedAccount.accountIdentifier];

                void (^setSyncOnAndSaveAccount)() = ^void()
                {
                    changedAccount.isSyncOn = YES;
                    [[AccountManager sharedManager] saveAccountsToKeychain];
                };
                
                NSArray *visibleItems = [MainMenuItemsVisibilityUtils visibleItemIdentifiersForAccount:changedAccount];

                if (visibleItems)
                {
                    [visibleItems enumerateObjectsUsingBlock:^(NSString *visibleItemIdentifier, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([visibleItemIdentifier isEqualToString:kSyncViewIdentifier])
                        {
                            setSyncOnAndSaveAccount();
                            *stop = YES;
                        }
                    }];
                }
                else
                {
                    setSyncOnAndSaveAccount();
                }
                
                if([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
                {
                    [[RealmManager sharedManager] changeDefaultConfigurationForAccount:changedAccount completionBlock:nil];
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
    if (self.disableSyncInProgress == NO)
    {
        self.disableSyncInProgress = YES;
        [self cleanUpAccount:account cancelOperationsType:CancelDownloadOperations];
    }
}

- (void)cleanUpAccount:(UserAccount *)account cancelOperationsType:(CancelOperationsType)cancelType
{
    SyncOperationQueue *syncOpQ = self.syncQueues[account.accountIdentifier];
    if (cancelType != CancelOperationsNone)
    {
        [syncOpQ cancelOperationsType:cancelType];
    }
    
    // Determinte and save conflicted files
    [self cleanDataBaseOfUnwantedNodesWithCompletionBlock:^{
        NSArray *syncObstacles = [[self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges] mutableCopy];
        for (AlfrescoDocument *document in syncObstacles)
        {
            [[RealmSyncManager sharedManager] saveDeletedFileBeforeRemovingFromSync:document];
        }
        [syncOpQ resetSyncNodeStatusInformation];
        
        [self deleteRealmForAccount:account];
        [account deleteSpecificSyncFolder];
        
        account.isSyncOn = NO;
        [[AccountManager sharedManager] saveAccountsToKeychain];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
        
        self.disableSyncInProgress = NO;
    }];
}

- (void)enableSyncForAccount:(UserAccount *)account
{
    account.isSyncOn = YES;
    [[AccountManager sharedManager] saveAccountsToKeychain];
    [self realmForAccount:account.accountIdentifier];
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [[RealmManager sharedManager] changeDefaultConfigurationForAccount:account completionBlock:^{
            [self.syncDisabledDelegate syncFeatureStatusChanged:YES];
        }];
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
            RLMRealm *backgroundRealm = [[RealmManager sharedManager] realmForCurrentThread];
            NSMutableArray *arrayOfNodesToDelete = [NSMutableArray new];
            NSMutableArray *arrayOfNodesToSaveLocally = [NSMutableArray new];
            NSMutableArray *arrayOfPathsForFilesToBeDeleted = [NSMutableArray new];
            
            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:backgroundRealm];
            
            BOOL hasSavedLocally = NO;
            if(!syncNodeInfo.isInvalidated)
            {
                if(node.isDocument)
                {
                    [weakSelf handleDocumentForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm deleteRule:deleteRule];
                }
                else if(node.isFolder)
                {
                    [weakSelf handleFolderForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm deleteRule:deleteRule];
                }
                
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
                            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                            
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
                
                for(RealmSyncNodeInfo *node in arrayOfNodesToDelete)
                {
                    if(!node.isInvalidated)
                    {
                        [self.currentOperationQueue removeSyncNodeStatusForNodeWithId:node.syncNodeInfoId];
                    }
                }
                // Delete RealmSyncNodeInfo objects
                [[RealmManager sharedManager] deleteRealmObjects:arrayOfNodesToDelete inRealm:backgroundRealm];
                
                // Delete files from the disk
                for(NSString *path in arrayOfPathsForFilesToBeDeleted)
                {
                    // No error handling here as we don't want to end up with Sync orphans
                    [weakSelf.fileManager removeItemAtPath:path error:nil];
                }
            }
            
            if(completionBlock)
            {
                completionBlock(hasSavedLocally);
            }
        });
    }
}

- (void)handleDocumentForDelete:(AlfrescoNode *)document arrayOfNodesToDelete:(NSMutableArray *)arrayToDelete arrayOfNodesToSaveLocally:(NSMutableArray *)arrayToSave arrayOfPaths:(NSMutableArray *)arrayOfPaths inRealm:(RLMRealm *)realm deleteRule:(DeleteRule)deleteRule
{
    SyncOperationQueue *syncOpQ = [self currentOperationQueue];
    SyncNodeStatus *syncNodeStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:[document syncIdentifier]];
    syncNodeStatus.totalSize = 0;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:realm];
    
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
            if (nodeInfo.isTopLevelSyncNode && nodeInfo.parentNode)
            {
                RLMRealm *backgroundRealm = [[RealmManager sharedManager] realmForCurrentThread];
                [backgroundRealm beginWriteTransaction];
                nodeInfo.isTopLevelSyncNode = NO;
                [backgroundRealm commitWriteTransaction];
                return;
            }
            
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
    RealmSyncNodeInfo *folderInfo = [[RealmManager sharedManager] syncNodeInfoForObject:folder ifNotExistsCreateNew:NO inRealm:realm];
    
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
        if (folderInfo.isTopLevelSyncNode && folderInfo.parentNode)
        {
            RLMRealm *backgroundRealm = [[RealmManager sharedManager] realmForCurrentThread];
            [backgroundRealm beginWriteTransaction];
            folderInfo.isTopLevelSyncNode = NO;
            [backgroundRealm commitWriteTransaction];
            return;
        }
        
        [arrayToDelete addObject:folderInfo];
    }
    RLMLinkingObjects *subNodes = folderInfo.nodes;
    for(RealmSyncNodeInfo *subNodeInfo in subNodes)
    {
        if(!subNodeInfo.isInvalidated)
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
    
    if (contentPath)
    {
        [self.fileManager copyItemAtPath:contentPath toPath:temporaryPath error:nil];
    }
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:temporaryPath completionBlock:^(NSString *filePath) {
        if (contentPath)
        {
            [self.fileManager removeItemAtPath:contentPath error:nil];
        }
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
        [[RealmManager sharedManager] resolvedObstacleForDocument:document inRealm:realm];
        
        RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:realm];
        
        if (syncNodeInfo)
        {
            [[RealmManager sharedManager] deleteRealmObject:syncNodeInfo inRealm:realm];
        }
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
    for (SyncOperationQueue *syncOpQ in self.syncQueues.allValues)
    {
        [syncOpQ cancelOperationsType:CancelAllOperations];
    }
}

- (void)cancelAllDownloadOperationsForAccountWithId:(NSString *)accountId
{
    SyncOperationQueue *syncOpQ = self.syncQueues[accountId];
    [syncOpQ cancelOperationsType:CancelDownloadOperations];
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier completionBlock:(void (^)(void))completionBlock
{
    SyncOperationQueue *syncOpQ = [self currentOperationQueue];
    [syncOpQ cancelSyncForDocumentWithIdentifier:documentIdentifier completionBlock:completionBlock];
}

- (BOOL)isCurrentlySyncing
{
    __block BOOL isSyncing = NO;
    
    [self.syncQueues enumerateKeysAndObjectsUsingBlock:^(id key, SyncOperationQueue *queue, BOOL *stop) {
        
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
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection] && self.alfrescoSession)
    {
        SyncOperationQueue *syncOpQ = [self currentOperationQueue];
        
        if (nodeStatus.activityType == SyncActivityTypeDownload)
        {
            [syncOpQ downloadDocument:document withCompletionBlock:^(BOOL completed) {
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
        else
        {
            [syncOpQ uploadDocument:document withCompletionBlock:^(BOOL completed) {
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
    }
    else
    {
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[document syncIdentifier]];
        nodeStatus.status = SyncStatusOffline;
        
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncOperationQueue *syncOpQ = [self currentOperationQueue];
    [syncOpQ uploadDocument:document withCompletionBlock:^(BOOL completed) {
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
            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:node ifNotExistsCreateNew:YES inRealm:realm];
            RealmSyncNodeInfo *parentSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:folder ifNotExistsCreateNew:NO inRealm:realm];
            
            [realm beginWriteTransaction];
            syncNodeInfo.parentNode = parentSyncNodeInfo;
            syncNodeInfo.isTopLevelSyncNode = NO;
            [realm commitWriteTransaction];
            
            SyncOperationQueue *syncOpQ = [self currentOperationQueue];
            SyncNodeStatus *nodeStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:[node syncIdentifier]];
            
            if(node.isDocument)
            {
                NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
                NSString *syncContentPath = [[self syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
                
                NSError *movingFileError = nil;
                [[AlfrescoFileManager sharedManager] copyItemAtPath:tempPath toPath:syncContentPath error:&movingFileError];
                
                if(movingFileError)
                {
                    nodeStatus.status = SyncStatusFailed;
                    
                    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNode:node ifNotExistsCreateNew:YES inRealm:realm];
                    [realm beginWriteTransaction];
                    syncError.errorCode = movingFileError.code;
                    syncError.errorDescription = [movingFileError localizedDescription];
                    
                    syncNodeInfo.syncError = syncError;
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
                else
                {
                    [[RealmManager sharedManager] updateSyncNodeInfoForNode:node lastDownloadedDate:[NSDate date] syncContentPath:syncNameForNode inRealm:realm];
                    nodeStatus.status = SyncStatusSuccessful;
                    nodeStatus.activityType = SyncActivityTypeIdle;
                    [realm beginWriteTransaction];
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
            }
            else if (node.isFolder)
            {
                [[RealmManager sharedManager] updateSyncNodeInfoForNode:node lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
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
                RealmSyncNodeInfo *documentInfo = [[RealmManager sharedManager] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
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
        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
        [node saveNodeInRealm:realm isTopLevelNode:YES];
        SyncOperationQueue *syncOpQ = [self currentOperationQueue];
        if (node.isFolder == NO)
        {
            [syncOpQ setNodeForSyncingAsTopLevel:node];
            [self checkNode:[NSArray arrayWithObject:node] forSizeAndDisplayAlertIfNeededWithProceedBlock:^(BOOL shouldProceed){
                if (shouldProceed)
                {
                    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                        [self trackSyncRunWithNodesToDownload:@[node] nodesToUpload:nil];
                        [syncOpQ addDocumentToSync:(AlfrescoDocument *)node isTopLevelNode:YES withCompletionBlock:^(BOOL completed) {
                            completionBlock(completed);
                        }];
                    });
                }
            }];
        }
        else
        {
            self.syncNodesInfo = [NSMutableDictionary new];
            [syncOpQ setNodeForSyncingAsTopLevel:node];
            if(completionBlock)
            {
                completionBlock(YES);
            }
            
            __block SyncProgressType syncProgressType = [syncOpQ syncProgressTypeForNode:node];
            if(syncProgressType == SyncProgressTypeInProcessing)
            {
                [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                    if(self.nodeChildrenRequestsCount == 0)
                    {
                        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
                        [self saveChildrenNodesForParent:node inRealm:realm];
                        NSArray *documents = [[RealmManager sharedManager] allNodesWithType:NodesTypeDocuments inFolder:(AlfrescoFolder *)node recursive:YES includeTopLevelNodes:YES inRealm:realm];
                        [self checkNode:documents forSizeAndDisplayAlertIfNeededWithProceedBlock:^(BOOL shouldProceed){
                            if (shouldProceed)
                            {
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    syncProgressType = [syncOpQ syncProgressTypeForNode:node];
                                    if(syncProgressType == SyncProgressTypeInProcessing)
                                    {
                                        syncOpQ.syncNodesInfo = self.syncNodesInfo;
                                        [syncOpQ syncFolder:(AlfrescoFolder *)node isTopLevelNode:YES];
                                    }
                                    else if(syncProgressType == SyncProgressTypeUnsyncRequested)
                                    {
                                        [self cleanRealmOfNode:node];
                                    }
                                });
                            }
                        }];
                        
                        NSArray *allNodes = [[RealmManager sharedManager] allNodesWithType:NodesTypeDocumentsAndFolders inFolder:(AlfrescoFolder *)node recursive:YES includeTopLevelNodes:YES inRealm:realm];
                        [self trackSyncRunWithNodesToDownload:allNodes nodesToUpload:nil];
                    }
                }];
            }
            else
            {
                [syncOpQ resetSyncProgressInformationForNode:node];
            }
        }
    }
}

- (void)saveChildrenNodesForParent:(AlfrescoNode *)parentNode inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *parentNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:parentNode ifNotExistsCreateNew:NO inRealm:realm];
    NSArray *children = self.syncNodesInfo[[parentNode syncIdentifier]];
    for(AlfrescoNode *child in children)
    {
        RealmSyncNodeInfo *subNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:child ifNotExistsCreateNew:YES inRealm:realm];
        [realm beginWriteTransaction];
        subNodeInfo.parentNode = parentNodeInfo;
        [realm commitWriteTransaction];
        if(child.isFolder)
        {
            [self saveChildrenNodesForParent:child inRealm:realm];
        }
    }
}

- (void)cleanRealmOfNode:(AlfrescoNode *)node
{
    SyncOperationQueue *syncOpQ = self.currentOperationQueue;
    syncOpQ.nodesInProcessingForDeletion[[node syncIdentifier]] = @YES;
    [self removeNode:node withCompletionBlock:^(BOOL completed) {
        void (^completionBlock)(BOOL);
        completionBlock = self.unsyncCompletionBlocks[[node syncIdentifier]];
        if(completionBlock)
        {
            completionBlock(YES);
        }
    }];
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
                for (AlfrescoNode *subNode in array)
                {
                    SyncNodeStatus *syncNodeStatus = [self.currentOperationQueue syncNodeStatusObjectForNodeWithId:[node syncIdentifier]];
                    syncNodeStatus.status = SyncStatusLoading;
                    
                    if(subNode.isFolder)
                    {
                        if([self.currentOperationQueue syncProgressTypeForNode:node] == SyncProgressTypeInProcessing)
                        {
                            // recursive call to retrieve nodes hierarchies
                            [self retrieveNodeHierarchyForNode:subNode withCompletionBlock:^(BOOL completed) {
                                
                                if (completionBlock != NULL)
                                {
                                    completionBlock(YES);
                                }
                            }];
                        }
                    }
                }
            }
            else if(error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
            {
                [self removeTopLevelNodeFlagFomNodeWithIdentifier:[node syncIdentifier]];
            }
            
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
}

- (void)unsyncNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL))completionBlock
{
    SyncOperationQueue *syncOpQ = self.currentOperationQueue;
    if([syncOpQ isCurrentlySyncingNode:node])
    {
        [syncOpQ setNodeForRemoval:node];
        if(completionBlock)
        {
            self.unsyncCompletionBlocks[[node syncIdentifier]] = completionBlock;
        }
        [syncOpQ cancelSyncForNode:node completionBlock:^{
            [self cleanRealmOfNode:node];
            [syncOpQ removeSyncNodeStatusForNodeWithId:[node syncIdentifier]];
            [syncOpQ resetSyncProgressInformationForNode:node];
        }];
    }
    else
    {
        SyncProgressType syncProgressType = [syncOpQ syncProgressTypeForNode:node];
        if(syncProgressType == SyncProgressTypeNotInProcessing)
        {
            [self removeNode:node withCompletionBlock:^(BOOL completed) {
                [syncOpQ removeSyncNodeStatusForNodeWithId:[node syncIdentifier]];
                completionBlock(completed);
            }];
        }
    }
}

- (void)removeNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL))completionBlock
{
    SyncOperationQueue *syncOpQ = self.currentOperationQueue;
    void (^deleteNode)() = ^void(){
        DeleteRule rule = (node.isFolder) ? DeleteRuleRootByForceAndKeepTopLevelChildren : DeleteRuleAllNodes;
        [self deleteNodeFromSync:node deleteRule:rule withCompletionBlock:^(BOOL savedLocally){
            if(completionBlock)
            {
                completionBlock(YES);
            }
        }];
    };
    
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inRealm:realm];
    if(node.isDocument && isModifiedLocally)
    {
        RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
        if(!syncNodeInfo.isRemovedFromSyncHasLocalChanges)
        {
            [realm beginWriteTransaction];
            syncNodeInfo.isRemovedFromSyncHasLocalChanges = YES;
            [realm commitWriteTransaction];
        }
        
        if(![syncOpQ isCurrentlySyncingNode:node])
        {
            [syncOpQ pauseSyncing:NO];
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed){
                deleteNode();
            }];
        }
        else if (completionBlock)
        {
            completionBlock(YES);
        }
    }
    else
    {
        deleteNode();
    }
}

- (NSMutableArray *)documentsToUpload
{
    NSMutableArray *documentsToUpload = [[NSMutableArray alloc] init];
    
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RLMResults *allDocuments = [[RealmManager sharedManager] allDocumentsInRealm:realm];
    for(RealmSyncNodeInfo *document in allDocuments)
    {
        AlfrescoNode *alfrescoDocument = document.alfrescoNode;
        if([self isNodeModifiedSinceLastDownload:alfrescoDocument inRealm:realm])
        {
            [documentsToUpload addObject:alfrescoDocument];
        }
    }
    
    return documentsToUpload;
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
        NSString *pathToSyncedFile = [node contentPath];
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    BOOL isModifiedLocally = ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
    
    if (isModifiedLocally)
    {
        SyncOperationQueue *syncOpQ = [self currentOperationQueue];
        SyncNodeStatus *nodeStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:[node syncIdentifier]];
        
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

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncOperationQueue *syncOpQanager = [self currentOperationQueue];
    SyncNodeStatus *nodeStatus = [syncOpQanager syncNodeStatusObjectForNodeWithId:syncNodeId];
    return nodeStatus;
}

- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = [self.permissions objectForKey:[node syncIdentifier]];
    
    if (!permissions)
    {
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
        
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
    [[RealmManager sharedManager] changeDefaultConfigurationForAccount:changedAccount completionBlock:^{
        AlfrescoProfileConfig *selectedProfileForAccount = [[AppConfigurationManager sharedManager] selectedProfileForAccount:changedAccount];
        [self determineSyncFeatureStatus:changedAccount selectedProfile:selectedProfileForAccount];
        
        id<AlfrescoSession> session = notification.object;
        self.alfrescoSession = session;
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        
        self.selectedAccountSyncIdentifier = changedAccount.accountIdentifier;
        SyncOperationQueue *syncOperationQueueManager = self.syncQueues[self.selectedAccountSyncIdentifier];
        
        if (!syncOperationQueueManager)
        {
            syncOperationQueueManager = [[SyncOperationQueue alloc] initWithAccount:changedAccount session:session syncProgressDelegate:nil];
            self.syncQueues[self.selectedAccountSyncIdentifier] = syncOperationQueueManager;
        }
        else
        {
            [syncOperationQueueManager updateSession:session];
        }
        
        BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
        if(hasInternetConnection)
        {
            [self refreshWithCompletionBlock:nil];
        }
    }];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    
    if(hasInternetConnection != self.lastConnectivityFlag)
    {
        self.lastConnectivityFlag = hasInternetConnection;
        if(hasInternetConnection)
        {
            //Necessary for the SDK to receive and handle the reachability notification as well
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                self.nodesToUpload = [self documentsToUpload];
                [self startNetworkOperations];
            });
        }
    }
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
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
    
    SyncNodeStatus *nodeStatus = notification.object;
    NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForId:nodeStatus.nodeId inRealm:realm];
    RealmSyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
    SyncOperationQueue *syncOpQ = self.syncQueues[selectedAccount.accountIdentifier];
    // update total size for parent folder
    if ([propertyChanged isEqualToString:kSyncTotalSize])
    {
        if (parentNodeInfo)
        {
            AlfrescoNode *parentNode = [NSKeyedUnarchiver unarchiveObjectWithData:parentNodeInfo.node];
            SyncNodeStatus *parentNodeStatus = [self syncStatusForNodeWithId:[parentNode syncIdentifier]];
            
            NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
            unsigned long long changeSize = [[change valueForKey:NSKeyValueChangeOldKey] unsignedLongLongValue];
            
            if (nodeStatus.totalSize >= changeSize)
            {
                parentNodeStatus.totalSize += nodeStatus.totalSize - changeSize;
            }
        }
        else
        {
            // if parent folder is nil - update total size for account
            SyncNodeStatus *accountSyncStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:selectedAccount.accountIdentifier];
            if (nodeStatus != accountSyncStatus)
            {
                NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
                unsigned long long changeSize = [[change valueForKey:NSKeyValueChangeOldKey] unsignedLongLongValue];
                
                if (nodeStatus.totalSize >= changeSize)
                {
                    accountSyncStatus.totalSize += nodeStatus.totalSize - changeSize;
                }
            }
        }
    }
    // update sync status for folder depending on its child nodes statuses
    else if ([propertyChanged isEqualToString:kSyncStatus])
    {
        if (parentNodeInfo)
        {
            NSString *parentNodeId = parentNodeInfo.syncNodeInfoId;
            SyncNodeStatus *parentNodeStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:parentNodeId];
            RLMLinkingObjects *subNodes = parentNodeInfo.nodes;
            
            SyncStatus syncStatus = SyncStatusSuccessful;
            for (RealmSyncNodeInfo *subNodeInfo in subNodes)
            {
                SyncNodeStatus *subNodeStatus = [syncOpQ syncNodeStatusObjectForNodeWithId:subNodeInfo.syncNodeInfoId];
                
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
        else if((nodeInfo.isTopLevelSyncNode) && (nodeInfo.isFolder) && (nodeStatus.status == SyncStatusSuccessful))
        {
            [syncOpQ resetSyncProgressInformationForNode:nodeInfo.alfrescoNode];
        }
    }
}

#pragma mark - Realm notifications
- (RLMNotificationToken *)notificationTokenForAlfrescoNode:(AlfrescoNode *)node notificationBlock:(void (^)(RLMResults<RealmSyncNodeInfo *> *results, RLMCollectionChange *change, NSError *error))block
{
    RLMNotificationToken *token = nil;
    
    if(node)
    {
        token = [[[RealmSyncNodeInfo objectsInRealm:[[RealmManager sharedManager] realmForCurrentThread] where:@"syncNodeInfoId == %@", [node syncIdentifier]] sortedResultsUsingProperty:@"title" ascending:YES] addNotificationBlock:block];
    }
    else
    {
        token = [[[RealmSyncNodeInfo objectsInRealm:[[RealmManager sharedManager] realmForCurrentThread] where:@"isTopLevelSyncNode = %@", @YES] sortedResultsUsingProperty:@"title" ascending:YES] addNotificationBlock:block];
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
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
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
    SyncOperationQueue *syncOpQ = [self currentOperationQueue];
    syncOpQ.progressDelegate = self.progressDelegate;
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

- (void)checkNode:(NSArray *)nodes forSizeAndDisplayAlertIfNeededWithProceedBlock:(void (^)(BOOL))proceedBlock
{
    unsigned long long totalDownloadSize = [self totalSizeForDocuments:nodes];
    if(totalDownloadSize > kDefaultMaximumAllowedDownloadSize)
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"sync.downloadsize.prompt.title", @"sync download size exceeded max alert title")
                                                                                 message:[NSString stringWithFormat:NSLocalizedString(@"sync.downloadsize.prompt.message", @"Sync download size"), stringForLongFileSize(totalDownloadSize)]
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"sync.downloadsize.prompt.cancel", @"Don't Sync")
                                                               style:UIAlertActionStyleCancel
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 proceedBlock(NO);
                                                             }];
        [alertController addAction:cancelAction];
        UIAlertAction *syncAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"sync.downloadsize.prompt.confirm", @"Sync Now")
                                                             style:UIAlertActionStyleDefault
                                                           handler:^(UIAlertAction * _Nonnull action) {
                                                               proceedBlock(YES);
                                                           }];
        [alertController addAction:syncAction];
        [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
    }
    else
    {
        proceedBlock(YES);
    }
}

#pragma mark - Internal methods
- (SyncOperationQueue *)currentOperationQueue
{
    SyncOperationQueue *syncOpQ = self.syncQueues[[AccountManager sharedManager].selectedAccount.accountIdentifier];
    return syncOpQ;
}

#pragma mark - Sync Obstacles

- (void)presentSyncObstaclesIfNeeded
{
    if ([self didEncounterObstaclesDuringSync])
    {
        NSDictionary *syncObstacles = @{kSyncObstaclesKey : [self syncObstacles]};
        [[NSNotificationCenter defaultCenter] postNotificationName:kSyncObstaclesNotification object:nil userInfo:syncObstacles];
    }
}

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

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inRealm:realm];
    
    NSMutableArray *documentsDeletedOnServerWithLocalChanges = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *documentsToBeDeletedLocallyAfterUpload = [self.syncObstacles objectForKey:kDocumentsToBeDeletedLocallyAfterUpload];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:[node syncIdentifier] completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (error)
            {
                [documentsDeletedOnServerWithLocalChanges addObject:node];
            }
            else
            {
                [documentsToBeDeletedLocallyAfterUpload addObject:node];
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

#pragma mark - Refresh

- (void)refreshWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncOperationQueue *syncOpQ = [self currentOperationQueue];
    [syncOpQ cancelOperationsType:CancelAllOperations];
    
    // STEP 1 - Mark all top level nodes as pending sync status.
    [self markTopLevelNodesAsPending];
    
    // STEP 2 - Invalidate the parent/child hierarchy in the database.
    [self invalidateParentChildHierarchy];
    
    // STEP 3 - Recursively request child folders from the server and update the database structure to match.
    [self rebuildDataBaseWithCompletionBlock:^(BOOL completed){
        
         // STEP 4 - Remove any synced content that is no longer within a sync set.
         [self cleanDataBaseOfUnwantedNodesWithCompletionBlock:^() {
             NSMutableArray *allNodesWithPendingOperations = [NSMutableArray arrayWithArray:self.nodesToDownload];
             [allNodesWithPendingOperations addObjectsFromArray:self.nodesToUpload];
             [self checkNode:allNodesWithPendingOperations forSizeAndDisplayAlertIfNeededWithProceedBlock:^(BOOL shouldProceed){
                 if (shouldProceed)
                 {
                     // STEP 5 - Start downloading any new content that appears inside the sync set.
                     [self startNetworkOperations];
                     
                     [self presentSyncObstaclesIfNeeded];
                 }
                 
                 if (completionBlock)
                 {
                     completionBlock(YES);
                 }
             }];
         }];
     }];
}

- (void)markTopLevelNodesAsPending
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    // Get all top level nodes.
    RLMResults *allTopLevelNodes = [[RealmManager sharedManager] topLevelSyncNodesInRealm:realm];
    
    // Mark all top level nodes as "pending sync" status.
    for (RealmSyncNodeInfo *node in allTopLevelNodes)
    {
        SyncNodeStatus *nodeStatus = [[RealmSyncManager sharedManager] syncStatusForNodeWithId:node.syncNodeInfoId];
        nodeStatus.status = SyncStatusWaiting;
        
        [self.currentOperationQueue setNodeForSyncingAsTopLevel:node.alfrescoNode];
    }
}

- (void)invalidateParentChildHierarchy
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RLMResults *allNodes = [[RealmManager sharedManager] allSyncNodesInRealm:realm];
    
    [realm beginWriteTransaction];
    for (RealmSyncNodeInfo *node in allNodes)
    {
        if (node.parentNode)
        {
            node.parentNode = nil;
        }
    }
    [realm commitWriteTransaction];
}

- (void)rebuildDataBaseWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RLMResults *topLevelNodes = [[RealmManager sharedManager] topLevelSyncNodesInRealm:realm];
    
    self.nodeChildrenRequestsCount = 0;
    
    self.nodesToDownload = [NSMutableArray new];
    self.nodesToUpload = [NSMutableArray new];
    
    if (topLevelNodes.count == 0 && completionBlock)
    {
        completionBlock(YES);
        return;
    }
    
    self.syncNodesInfo = [NSMutableDictionary new];
    for(RealmSyncNodeInfo *node in topLevelNodes)
    {
        if(node.isFolder)
        {
            [self retrieveNodeHierarchyForNode:node.alfrescoNode withCompletionBlock:^(BOOL completed) {
                if(self.nodeChildrenRequestsCount == 0)
                {
                    [self determineSyncActionAndStatusForRefresh];
                    
                    if(completionBlock)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
        else
        {
            [self handleNodeSyncActionAndStatus:node.alfrescoNode parentNode:nil];
        }
    }
    
    RLMResults *topLevelFolders = [[RealmManager sharedManager] topLevelFoldersInRealm:realm];
    if((topLevelFolders.count == 0) && (completionBlock))
    {
        completionBlock(YES);
    }
}

- (void)determineSyncActionAndStatusForRefresh
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RLMResults *topLevelNodes = [[RealmManager sharedManager] topLevelSyncNodesInRealm:realm];
    for(RealmSyncNodeInfo *node in topLevelNodes)
    {
        if(node.isFolder)
        {
            [self categorizeChildrenOfFolder:(AlfrescoFolder *)node.alfrescoNode];
        }
        else
        {
            [self handleNodeSyncActionAndStatus:node.alfrescoNode parentNode:nil];
        }
    }
}

- (void)categorizeChildrenOfFolder:(AlfrescoFolder *)folder
{
    NSArray *childrenArray = self.syncNodesInfo[[folder syncIdentifier]];
    if(childrenArray.count == 0)
    {
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[folder syncIdentifier]];
        nodeStatus.status = SyncStatusSuccessful;
    }
    else
    {
        for(AlfrescoNode *childNode in childrenArray)
        {
            [self handleNodeSyncActionAndStatus:childNode parentNode:folder];
            if(childNode.isFolder)
            {
                [self categorizeChildrenOfFolder:(AlfrescoFolder *)childNode];
            }
        }
    }
}

- (BOOL)determineFileActionForNode:(AlfrescoNode *)node
{
    BOOL shouldUpdateStatus = NO;
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    SyncActivityType activityTypeForNode = [node determineSyncActivityTypeInRealm:realm];
    switch (activityTypeForNode) {
        case SyncActivityTypeIdle:
        {
            shouldUpdateStatus = YES;
            break;
        }
        case SyncActivityTypeUpload:
        {
            [self.nodesToUpload addObject:node];
            break;
        }
        case SyncActivityTypeDownload:
        {
            [self.nodesToDownload addObject:node];
            break;
        }
    }
    
    return shouldUpdateStatus;
}

- (void)handleNodeSyncActionAndStatus:(AlfrescoNode *)node parentNode:(AlfrescoNode *)parentNode
{
    BOOL shouldUpdateStatus = [self determineFileActionForNode:node];
    [self updateDataBaseForChildNode:node withParent:parentNode updateStatus:shouldUpdateStatus];
}

- (void)updateDataBaseForChildNode:(AlfrescoNode *)childNode withParent:(AlfrescoNode *)parentNode updateStatus:(BOOL)shouldUpdateStatus
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RealmSyncNodeInfo *childSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:childNode ifNotExistsCreateNew:YES inRealm:realm];
    
    [realm beginWriteTransaction];
    
    // Setup the node with data from the server.
    if (parentNode)
    {
        RealmSyncNodeInfo *parentSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:parentNode ifNotExistsCreateNew:NO inRealm:realm];
        childSyncNodeInfo.parentNode = parentSyncNodeInfo;
    }
    
    childSyncNodeInfo.isFolder = childNode.isFolder;
    childSyncNodeInfo.title = childNode.name;
    
    [realm commitWriteTransaction];
    
    RealmSyncNodeInfo *topLevelParentNode = [childNode topLevelSyncParentNodeInRealm:realm];
    if(topLevelParentNode)
    {
        SyncOperationQueue *syncOpQ = [self currentOperationQueue];
        syncOpQ.topLevelNodesInSyncProcessing[topLevelParentNode.syncNodeInfoId] = @YES;
    }
    
    if(shouldUpdateStatus)
    {
        [realm beginWriteTransaction];
        childSyncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:childNode];
        [realm commitWriteTransaction];
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[childNode syncIdentifier]];
        nodeStatus.status = SyncStatusSuccessful;
        
        if (childSyncNodeInfo.isFolder == NO)
        {
            nodeStatus.totalSize = [(AlfrescoDocument *)childSyncNodeInfo.alfrescoNode contentLength];
        }
    }
    else
    {
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[childNode syncIdentifier]];
        nodeStatus.status = SyncStatusLoading;
    }
}

- (void)removeTopLevelNodeFlagFomNodeWithIdentifier:(NSString *)nodeIdentifier
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForId:nodeIdentifier inRealm:realm];
    
    [realm beginWriteTransaction];
    syncNodeInfo.isTopLevelSyncNode = NO;
    [realm commitWriteTransaction];
}

- (void)cleanDataBaseOfUnwantedNodesWithCompletionBlock:(void (^)())completionBlock
{
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RLMResults *allNodes = [[RealmManager sharedManager] allSyncNodesInRealm:realm];
    __block NSInteger totalChecksForObstacles = allNodes.count;
    
    if (totalChecksForObstacles == 0 && completionBlock)
    {
        completionBlock();
        return;
    }
    
    void (^decreaseTotalChecksBlock)() = ^{
        totalChecksForObstacles--;
        
        if (totalChecksForObstacles == 0)
        {
            if (completionBlock)
            {
                completionBlock();
            }
        }
    };
    
    for (RealmSyncNodeInfo *node in allNodes)
    {
        [self checkForObstaclesInRemovingDownloadForNode:node.alfrescoNode inRealm:realm completionBlock:^(BOOL encounteredObstacle) {
            if (encounteredObstacle)
            {
                SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[node.alfrescoNode syncIdentifier]];
                nodeStatus.status = SyncStatusFailed;
                
                if (node.alfrescoNode.isDocument)
                {
                    NSMutableArray *documentsToBeDeletedLocallyAfterUpload = [self.syncObstacles objectForKey:kDocumentsToBeDeletedLocallyAfterUpload];
                    
                    [documentsToBeDeletedLocallyAfterUpload enumerateObjectsUsingBlock:^(AlfrescoDocument *document, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([[document syncIdentifier] isEqualToString:[node.alfrescoNode syncIdentifier]])
                        {
                            [self retrySyncForDocument:(AlfrescoDocument *)node.alfrescoNode completionBlock:^{
                                decreaseTotalChecksBlock();
                            }];
                            *stop = YES;
                        }
                        else
                        {
                            decreaseTotalChecksBlock();
                        }
                    }];
                    
                    NSMutableArray *deletedOnServerWithLocalChanges = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
                    
                    [deletedOnServerWithLocalChanges enumerateObjectsUsingBlock:^(AlfrescoDocument *document, NSUInteger idx, BOOL * _Nonnull stop) {
                        if ([[document syncIdentifier] isEqualToString:[node.alfrescoNode syncIdentifier]])
                        {
                            // Orphan document with new local version => Copy the file into Local Files prior to deletion.
                            [self saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)node.alfrescoNode];
                            decreaseTotalChecksBlock();
                            *stop = YES;
                        }
                        else
                        {
                            decreaseTotalChecksBlock();
                        }
                    }];
                }
                else
                {
                    decreaseTotalChecksBlock();
                }
            }
            else
            {
                decreaseTotalChecksBlock();
            }
        }];
        if (node.parentNode == nil && node.isTopLevelSyncNode == NO)
        {
            if (node.isFolder == NO)
            {
                
                if (node.isRemovedFromSyncHasLocalChanges)
                {
                    // Orphan document with new local version => Copy the file into Local Files prior to deletion.
                    [self saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)node.alfrescoNode];
                }
                else
                {
                    // Remove file.
                    NSString *filePath = [node.alfrescoNode contentPath];
                    NSError *deleteError;
                    [self.fileManager removeItemAtPath:filePath error:&deleteError];
                }
            }
            
            // Remove sync status.
            SyncOperationQueue *syncOpQ = [self currentOperationQueue];
            [syncOpQ removeSyncNodeStatusForNodeWithId:node.syncNodeInfoId];
            
            // Remove RealmSyncError object if exists.
            RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNode:node.alfrescoNode ifNotExistsCreateNew:NO inRealm:realm];
            [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:realm];
            
            // Remove RealmSyncNodeInfo object.
            [[RealmManager sharedManager] deleteRealmObject:node inRealm:realm];
        }
    }
}

- (void)startNetworkOperations
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SyncOperationQueue *syncOpQ = [self currentOperationQueue];
        [syncOpQ downloadContentsForNodes:self.nodesToDownload withCompletionBlock:nil];
        [syncOpQ uploadContentsForNodes:self.nodesToUpload withCompletionBlock:nil];
        
        [self trackSyncRunWithNodesToDownload:self.nodesToDownload nodesToUpload:self.nodesToUpload];
    });
}

#pragma mark - Analytics

- (void)trackSyncRunWithNodesToDownload:(NSArray *)nodesToDownload nodesToUpload:(NSArray *)nodesToUpload
{
    __block NSUInteger numberOfFiles = 0;
    __block NSUInteger numberOfFolders = 0;
    __block unsigned long long totalFileSize = 0;
    
    void (^processNodesArray)(NSArray *) = ^(NSArray *nodesArray){
        [nodesArray enumerateObjectsUsingBlock:^(AlfrescoNode *node, NSUInteger idx, BOOL * stop){
            if (node.isDocument)
            {
                numberOfFiles++;
                totalFileSize += ((AlfrescoDocument *)node).contentLength;
            }
            else
            {
                numberOfFolders++;
            }
        }];
    };
    
    processNodesArray(nodesToDownload);
    processNodesArray(nodesToUpload);
    
    if (numberOfFiles)
    {
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySync
                                                          action:kAnalyticsEventActionRun
                                                           label:kAnalyticsEventLabelSyncedFiles
                                                           value:@(numberOfFiles)
                                                    customMetric:AnalyticsMetricFileSize
                                                     metricValue:@(totalFileSize)];
    }
    
    if (numberOfFolders)
    {
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySync
                                                          action:kAnalyticsEventActionRun
                                                           label:kAnalyticsEventLabelSyncedFolders
                                                           value:@(numberOfFolders)];
    }
}

@end
