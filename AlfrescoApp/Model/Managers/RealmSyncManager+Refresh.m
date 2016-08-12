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

#import "RealmSyncManager+Refresh.h"
#import "RealmSyncManager+Internal.h"

@implementation RealmSyncManager (Refresh)

#pragma mark - Public Methods

- (void)refreshWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
    [syncOpQM cancelOperationsType:CancelAllOperations];
    
    // STEP 1 - Mark all top level nodes as pending sync status.
    [self markTopLevelNodesAsPending];
    
    // STEP 2 - Invalidate the parent/child hierarchy in the database.
    [self invalidateParentChildHierarchy];
    
    NSMutableArray *arrayOfDocumentsToDownload = [NSMutableArray new];
    NSMutableArray *arrayOfDocumentsToUpload = [NSMutableArray new];
    // STEP 3 - Recursively request child folders from the server and update the database structure to match.
    [self rebuildDataBaseWithArrayOfFilesToDownload:arrayOfDocumentsToDownload arrayOfFilesToUpload:arrayOfDocumentsToUpload withCompletionBlock:^(BOOL completed)
    {
        // STEP 4 - Remove any synced content that is no longer within a sync set.
        [self cleanDataBaseOfUnwantedNodes];
        
        // STEP 5 - Start downloading any new content that appears inside the sync set.
        [self startNetworkOperationsForDownloadArray:arrayOfDocumentsToDownload andForUploadArray:arrayOfDocumentsToUpload];
        
        if (completionBlock)
        {
            completionBlock(YES);
        }
    }];
}

#pragma mark - Private Methods

- (void)markTopLevelNodesAsPending
{
    RLMRealm *realm = self.mainThreadRealm;
    // Get all top level nodes.
    RLMResults *allTopLevelNodes = [[RealmManager sharedManager] topLevelSyncNodesInRealm:realm];
    
    // Mark all top level nodes as "pending sync" status.
    for (RealmSyncNodeInfo *node in allTopLevelNodes)
    {
        SyncNodeStatus *nodeStatus = [[RealmSyncManager sharedManager] syncStatusForNodeWithId:node.syncNodeInfoId];
        nodeStatus.status = SyncStatusWaiting;
    }
}

- (void)invalidateParentChildHierarchy
{
    RLMRealm *realm = [RLMRealm defaultRealm];
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

- (void)rebuildDataBaseWithArrayOfFilesToDownload:(NSMutableArray *)arrayToDownload arrayOfFilesToUpload:(NSMutableArray *)arrayToUpload withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    RLMRealm *realm = self.mainThreadRealm;
    RLMResults *topLevelFolders = [[RealmManager sharedManager] topLevelSyncNodesInRealm:realm];
    
    self.nodeChildrenRequestsCount = 0;
    
    if (topLevelFolders.count == 0 && completionBlock)
    {
        completionBlock(YES);
        return;
    }
    
    for (RealmSyncNodeInfo *node in topLevelFolders)
    {
        if(node.isFolder)
        {
            AlfrescoFolder *folder = (AlfrescoFolder *)node.alfrescoNode;
            
            [self retrieveNodeHierarchyForFolder:folder withArrayOfFilesToDownload:arrayToDownload arrayOfFilesToUpload:arrayToUpload withCompletionBlock:^(BOOL completed) {
                if(self.nodeChildrenRequestsCount == 0)
                {
                    if(completionBlock)
                    {
                        completionBlock(completed);
                    }
                }
            }];
        }
        else
        {
            [self handleNodeSyncActionAndStatus:node.alfrescoNode parentNode:nil shouldDownloadArray:arrayToDownload shouldUploadArray:arrayToUpload];
        }
    }
}

- (void)retrieveNodeHierarchyForFolder:(AlfrescoFolder *)folder withArrayOfFilesToDownload:(NSMutableArray *)arrayToDownload arrayOfFilesToUpload:(NSMutableArray *)arrayToUpload withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    self.nodeChildrenRequestsCount++;
    
    [self.documentFolderService retrieveChildrenInFolder:folder completionBlock:^(NSArray *array, NSError *error){
        self.nodeChildrenRequestsCount--;
        
        if (array)
        {
            if(array.count == 0)
            {
                SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[folder syncIdentifier]];
                nodeStatus.status = SyncStatusSuccessful;
            }
            else
            {
                for (AlfrescoNode *childNode in array)
                {
                    [self handleNodeSyncActionAndStatus:childNode parentNode:folder shouldDownloadArray:arrayToDownload shouldUploadArray:arrayToUpload];
                    
                    if (childNode.isFolder)
                    {
                        [self retrieveNodeHierarchyForFolder:(AlfrescoFolder *)childNode withArrayOfFilesToDownload:arrayToDownload arrayOfFilesToUpload:arrayToUpload withCompletionBlock:^(BOOL completed) {
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
            [self removeTopLevelNodeFlagFomNodeWithIdentifier:folder.identifier];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }];
}

- (void)updateDataBaseForChildNode:(AlfrescoNode *)childNode withParent:(AlfrescoNode *)parentNode updateStatus:(BOOL)shouldUpdateStatus
{
    NSString *childNodeIdentifier = [childNode syncIdentifier];
    
    RLMRealm *realm = [RLMRealm defaultRealm];
    RealmSyncNodeInfo *childSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:childNodeIdentifier ifNotExistsCreateNew:YES inRealm:realm];
    
    [realm beginWriteTransaction];
    
    // Setup the node with data from the server.
    if (parentNode)
    {
        NSString *parentNodeIdentifier = [parentNode syncIdentifier];
        RealmSyncNodeInfo *parentSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:parentNodeIdentifier ifNotExistsCreateNew:NO inRealm:realm];
        childSyncNodeInfo.parentNode = parentSyncNodeInfo;
    }
    
    childSyncNodeInfo.isFolder = childNode.isFolder;
    childSyncNodeInfo.title = childNode.name;
    
    [realm commitWriteTransaction];
    
    if(shouldUpdateStatus)
    {
        [realm beginWriteTransaction];
        childSyncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:childNode];
        [realm commitWriteTransaction];
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[childNode syncIdentifier]];
        nodeStatus.status = SyncStatusSuccessful;
    }
}

- (void)removeTopLevelNodeFlagFomNodeWithIdentifier:(NSString *)nodeIdentifier
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:nodeIdentifier ifNotExistsCreateNew:NO inRealm:realm];
    
    [realm beginWriteTransaction];
    syncNodeInfo.isTopLevelSyncNode = NO;
    [realm commitWriteTransaction];
}

- (void)cleanDataBaseOfUnwantedNodes
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RLMResults *allNodes = [[RealmManager sharedManager] allSyncNodesInRealm:realm];
    
    for (RealmSyncNodeInfo *node in allNodes)
    {
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
            SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
            [syncOpQM removeSyncNodeStatusForNodeWithId:node.syncNodeInfoId];
            
            // Remove RealmSyncError object if exists.
            RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:node.syncNodeInfoId ifNotExistsCreateNew:NO inRealm:realm];
            [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:realm];
            
            // Remove RealmSyncNodeInfo object.
            [[RealmManager sharedManager] deleteRealmObject:node inRealm:realm];   
        }
    }
}

- (void)startNetworkOperationsForDownloadArray:(NSMutableArray *)arrayToDownload andForUploadArray:(NSMutableArray *)arrayToUpload
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
        [syncOpQM downloadContentsForNodes:arrayToDownload withCompletionBlock:nil];
        [syncOpQM uploadContentsForNodes:arrayToUpload withCompletionBlock:nil];
    });
}

- (BOOL)determineFileActionForNode:(AlfrescoNode *)node shouldDownloadArray:(NSMutableArray *)shouldDownloadArray shouldUploadArray:(NSMutableArray *)shouldUploadArray
{
    BOOL shouldUpdateStatus = NO;
    RLMRealm *realm = [RLMRealm defaultRealm];
    RealmSyncNodeInfo *childSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[node syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    if(childSyncNodeInfo)
    {
        AlfrescoNode *localNode = childSyncNodeInfo.alfrescoNode;
        if(childSyncNodeInfo.isRemovedFromSyncHasLocalChanges)
        {
            [shouldUploadArray addObject:node];
        }
        else
        {
            NSComparisonResult compareResult = [localNode.modifiedAt compare:node.modifiedAt];
            if(compareResult == NSOrderedAscending)
            {
                [shouldDownloadArray addObject:node];
            }
            else if(compareResult == NSOrderedDescending)
            {
                [shouldUploadArray addObject:localNode];
            }
            else
            {
                shouldUpdateStatus = YES;
            }
        }
    }
    else
    {
        [shouldDownloadArray addObject:node];
    }
    
    return shouldUpdateStatus;
}

- (void)handleNodeSyncActionAndStatus:(AlfrescoNode *)node parentNode:(AlfrescoNode *)parentNode shouldDownloadArray:(NSMutableArray *)arrayToDownload shouldUploadArray:(NSMutableArray *)arrayToUpload
{
    BOOL shouldUpdateStatus = [self determineFileActionForNode:node shouldDownloadArray:arrayToDownload shouldUploadArray:arrayToUpload];
    [self updateDataBaseForChildNode:node withParent:parentNode updateStatus:shouldUpdateStatus];
}

@end