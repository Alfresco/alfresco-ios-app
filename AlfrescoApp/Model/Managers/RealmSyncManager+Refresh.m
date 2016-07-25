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
    [syncOpQM cancelDownloadOperations:YES uploadOperations:YES];
    
    // STEP 1 - Mark all top level nodes as pending sync status.
    [self markTopLevelNodesAsPending];
    
    // STEP 2 - Invalidate the parent/child hierarchy in the database.
    [self invalidateParentChildHierarchy];
    
    // STEP 3 - Recursively request child folders from the server and update the database structure to match.
    [self rebuildDataBaseWithCompletionBlock:^(BOOL completed)
    {
        // STEP 4 - Remove any synced content that is no longer within a sync set.
        [self cleanDataBaseOfUnwantedNodes];
        
        // STEP 5 - Start downloading any new content that appears inside the sync set.
        [self startDownloadingNewContent];
        
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

- (void)rebuildDataBaseWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    RLMRealm *realm = self.mainThreadRealm;
    RLMResults *topLevelFolders = [[RealmManager sharedManager] topLevelFoldersInRealm:realm];
    
    self.nodeChildrenRequestsCount = 0;
    
    for (RealmSyncNodeInfo *node in topLevelFolders)
    {
        AlfrescoFolder *folder = (AlfrescoFolder *)node.alfrescoNode;
        
        [self retrieveNodeHierarchyForFolder:folder withCompletionBlock:^(BOOL completed){
            if(self.nodeChildrenRequestsCount == 0)
            {
                if(completionBlock)
                {
                    completionBlock(completed);
                }
            }
        }];
    }
}

- (void)retrieveNodeHierarchyForFolder:(AlfrescoFolder *)folder withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    self.nodeChildrenRequestsCount++;
    
    [self.documentFolderService retrieveChildrenInFolder:folder completionBlock:^(NSArray *array, NSError *error){
        self.nodeChildrenRequestsCount--;
        
        if (array)
        {
            for (AlfrescoNode *childNode in array)
            {
                [self updateDataBaseForChildNode:childNode withParent:folder];
                
                if (childNode.isFolder)
                {
                    [self retrieveNodeHierarchyForFolder:(AlfrescoFolder *)childNode withCompletionBlock:^(BOOL completed){
                        if (completionBlock != NULL)
                        {
                            completionBlock(YES);
                        }
                    }];
                }
            }
        }
        else
        {
            [self removeTopLevelNodeFlagFomNodeWithIdentifier:folder.identifier];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }];
}

- (void)updateDataBaseForChildNode:(AlfrescoNode *)childNode withParent:(AlfrescoNode *)parentNode
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
    childSyncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:childNode];
    childSyncNodeInfo.title = childNode.name;
    
    [realm commitWriteTransaction];
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

- (void)startDownloadingNewContent
{
    RLMRealm *realm = [RealmSyncManager sharedManager].mainThreadRealm;
    RLMResults *allDocumentNodes = [[RealmManager sharedManager] allDocumentsInRealm:realm];
    
    NSMutableArray *nodesToDownloadArray = [NSMutableArray array];
    NSMutableArray *nodesToUploadArray = [NSMutableArray array];

    for (RealmSyncNodeInfo *document in allDocumentNodes)
    {
        if (document.alfrescoNode)
        {
            if (document.isRemovedFromSyncHasLocalChanges)
            {
                [nodesToUploadArray addObject:document.alfrescoNode];
            }
            else
            {
                [nodesToDownloadArray addObject:document.alfrescoNode];
            }
        }
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        SyncOperationQueueManager *syncOpQM = [self currentOperationQueueManager];
        [syncOpQM downloadContentsForNodes:nodesToDownloadArray withCompletionBlock:nil];
        [syncOpQM uploadContentsForNodes:nodesToUploadArray withCompletionBlock:nil];
    });
}

@end