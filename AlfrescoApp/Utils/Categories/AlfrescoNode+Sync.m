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

#import "AlfrescoNode+Sync.h"
#import "SyncConstants.h"
#import "RealmManager.h"
#import "AccountManager.h"
#import "RealmSyncManager+Internal.h"
#import "AlfrescoNode+Networking.h"

@implementation AlfrescoNode (Sync)

- (NSString *)syncIdentifier
{
    NSString *syncIdentifier = [(AlfrescoProperty *)[self.properties objectForKey:kAlfrescoNodeVersionSeriesIdKey] value];
    if (!syncIdentifier)
    {
        syncIdentifier = [Utility nodeRefWithoutVersionID:self.identifier];
    }
    return syncIdentifier;
}

- (NSString *)syncNameInRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    
    if (nodeInfo.syncContentPath.length == 0)
    {
        NSString *newName = @"";
        NSString *nodeExtension = [self.name pathExtension];
        
        if (nodeExtension.length == 0)
        {
            newName = [[self syncIdentifier] lastPathComponent];
        }
        else
        {
            newName = [NSString stringWithFormat:@"%@.%@", [[self syncIdentifier] lastPathComponent], nodeExtension];
        }
        return newName;
    }
    return [nodeInfo.syncContentPath lastPathComponent];
}

- (NSDate *)lastDownloadedDateInRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    return nodeInfo.lastDownloadedDate;
}

- (NSString *)contentPath
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
    
    NSString *newNodePath = nil;
    if(nodeInfo && (nodeInfo.isFolder == NO) && nodeInfo.syncContentPath)
    {
        NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
        newNodePath = [[[RealmSyncManager sharedManager] syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:nodeInfo.syncContentPath];
    }
    
    return newNodePath;
}

- (BOOL)isTopLevelSyncNode
{
    BOOL isTopLevelSyncNode = NO;
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode)
        {
            isTopLevelSyncNode = YES;
        }
    }
    
    return isTopLevelSyncNode;
}

- (BOOL)isNodeInSyncList
{
    return [self isNodeInSyncListInRealm:[[RealmManager sharedManager] realmForCurrentThread]];
}

- (BOOL)isNodeInSyncListInRealm:(RLMRealm *)realm
{
    BOOL isInSyncList = NO;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (void)saveNodeInRealm:(RLMRealm *)realm isTopLevelNode:(BOOL)isTopLevel
{
    RealmSyncNodeInfo *nodeSyncInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:YES inRealm:realm];
    if(!nodeSyncInfo.alfrescoNode)
    {
        [[RealmManager sharedManager] updateSyncNodeInfoForNode:self lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
    }
    [realm beginWriteTransaction];
    if(!nodeSyncInfo.isTopLevelSyncNode)
    {
        nodeSyncInfo.isTopLevelSyncNode = isTopLevel;
    }
    nodeSyncInfo.isFolder = self.isFolder;
    [realm commitWriteTransaction];
}

- (NSString *)syncErrorDescription
{
    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNode:self ifNotExistsCreateNew:NO inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
    return syncError.errorDescription;
}

- (RealmSyncNodeInfo *)topLevelSyncParentNodeInRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *topLevelSyncParent = nil;
    RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    if(syncNodeInfo)
    {
        if(syncNodeInfo.isTopLevelSyncNode)
        {
            topLevelSyncParent = syncNodeInfo;
        }
        else
        {
            RealmSyncNodeInfo *currentSyncNode = syncNodeInfo;
            while (currentSyncNode.parentNode)
            {
                if(currentSyncNode.parentNode.isTopLevelSyncNode)
                {
                    topLevelSyncParent = currentSyncNode.parentNode;
                    break;
                }
                else
                {
                    currentSyncNode = currentSyncNode.parentNode;
                }
            }
        }
    }
    
    return topLevelSyncParent;
}

- (SyncActivityType)determineSyncActivityTypeInRealm:(RLMRealm *)realm
{
    SyncActivityType typeToReturn = SyncActivityTypeIdle;
    if(!self.isFolder)
    {
        RealmSyncNodeInfo *syncNode = [[RealmManager sharedManager] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
        if(syncNode)
        {
            if(syncNode.isRemovedFromSyncHasLocalChanges)
            {
                typeToReturn = SyncActivityTypeUpload;
            }
            else
            {
                if(syncNode.reloadContent)
                {
                    typeToReturn = SyncActivityTypeDownload;
                }
                else
                {
                    AlfrescoNode *localNode = syncNode.alfrescoNode;
                    NSComparisonResult compareResult = [localNode.modifiedAt compare:self.modifiedAt];
                    if(compareResult == NSOrderedAscending)
                    {
                        typeToReturn = SyncActivityTypeDownload;
                    }
                    else if(compareResult == NSOrderedDescending)
                    {
                        typeToReturn = SyncActivityTypeUpload;
                    }
                    else
                    {
                        //both modifiedAt dates have the same value - checking for last downloaded date
                        if(syncNode.lastDownloadedDate)
                        {
                            NSComparisonResult downloadCompareResult = [syncNode.lastDownloadedDate compare:self.modifiedAt];
                            if(downloadCompareResult == NSOrderedAscending)
                            {
                                typeToReturn = SyncActivityTypeDownload;
                            }
                        }
                        else
                        {
                            typeToReturn = SyncActivityTypeDownload;
                        }
                    }
                }
            }
        }
        else
        {
            typeToReturn = SyncActivityTypeDownload;
        }
    }
    
    return typeToReturn;
}

+ (NSArray *)syncIdentifiersForNodes:(NSArray *)nodes
{
    NSMutableArray *syncIdentifiers = [NSMutableArray array];
    
    for (AlfrescoNode *node in nodes)
    {
        NSString *syncIdentifier = [node syncIdentifier];
        if(syncIdentifier)
        {
            [syncIdentifiers addObject:syncIdentifier];
        }
    }
    return syncIdentifiers;
}

+ (AlfrescoNode *)alfrescoNodeForIdentifier:(NSString *)nodeId inRealm:(RLMRealm *)realm
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForId:syncNodeId inRealm:realm];
    
    return nodeInfo.alfrescoNode;
}

@end
