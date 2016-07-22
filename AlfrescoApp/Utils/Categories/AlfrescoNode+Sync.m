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
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    
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
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    return nodeInfo.lastDownloadedDate;
}

- (NSString *)contentPath
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifier] ifNotExistsCreateNew:NO inRealm:[RLMRealm defaultRealm]];
    
    NSString *newNodePath = nil;
    if(nodeInfo && (nodeInfo.isFolder == NO))
    {
        NSString *syncDirectory = [[AlfrescoFileManager sharedManager] syncFolderPath];
        newNodePath = [syncDirectory stringByAppendingPathComponent:nodeInfo.syncContentPath];
    }
    
    return newNodePath;
}

- (BOOL)isTopLevelSyncNode
{
    BOOL isTopLevelSyncNode = NO;
    RLMRealm *realm = [RLMRealm defaultRealm];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
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
    return [self isNodeInSyncListInRealm:[RLMRealm defaultRealm]];
}

- (BOOL)isNodeInSyncListInRealm:(RLMRealm *)realm
{
    BOOL isInSyncList = NO;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
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
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:syncNodeId ifNotExistsCreateNew:NO inRealm:realm];
    
    return nodeInfo.alfrescoNode;
}

@end
