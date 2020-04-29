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

#import "AlfrescoNode+Sync.h"
#import "SyncConstants.h"
#import "RealmManager.h"
#import "AccountManager.h"
#import "RealmSyncManager+Internal.h"
#import "AlfrescoNode+Networking.h"
#import "AlfrescoNode+Utilities.h"

@implementation AlfrescoNode (Sync)

- (NSDate *)lastDownloadedDateInRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
    return nodeInfo.lastDownloadedDate;
}

- (BOOL)isTopLevelSyncNode
{
    BOOL isTopLevelSyncNode = NO;
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
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
    return [[RealmSyncCore sharedSyncCore] isNode:self inSyncListInRealm:[[RealmManager sharedManager] realmForCurrentThread]];
}

- (void)saveNodeInRealm:(RLMRealm *)realm isTopLevelNode:(BOOL)isTopLevel
{
    RealmSyncNodeInfo *nodeSyncInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:self ifNotExistsCreateNew:YES inRealm:realm];
    if(!nodeSyncInfo.alfrescoNode)
    {
        [[RealmSyncCore sharedSyncCore] updateSyncNodeInfoForNodeWithSyncId:nil alfrescoNode:self lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
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
    RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:self ifNotExistsCreateNew:NO inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
    return syncError.errorDescription;
}

- (RealmSyncNodeInfo *)topLevelSyncParentNodeInRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *topLevelSyncParent = nil;
    RealmSyncNodeInfo *syncNodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
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
        RealmSyncNodeInfo *syncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:self ifNotExistsCreateNew:NO inRealm:realm];
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
                    else if(!syncNode.lastDownloadedDate)
                    {
                        typeToReturn = SyncActivityTypeDownload;
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
        NSString *syncIdentifier = [[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node];
        if(syncIdentifier)
        {
            [syncIdentifiers addObject:syncIdentifier];
        }
    }
    return syncIdentifiers;
}

+ (AlfrescoNode *)alfrescoNodeForIdentifier:(NSString *)nodeId inRealm:(RLMRealm *)realm
{
    NSString *syncNodeId = [self nodeRefWithoutVersionIDFromIdentifier:nodeId];
    RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForId:syncNodeId inRealm:realm];
    
    return nodeInfo.alfrescoNode;
}

@end
