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

#import "RealmSyncHelper.h"
#import "RealmManager.h"
#import "SyncNodeStatus.h"
#import "SyncConstants.h"
#import "AccountManager.h"

@interface RealmSyncHelper()

@property (nonatomic, strong) AlfrescoFileManager *fileManager;

@end

@implementation RealmSyncHelper

+ (RealmSyncHelper *)sharedHelper
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
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
    }
    return self;
}

- (NSString *)syncNameForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:realm];
    
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

- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:realm];
    return nodeInfo.lastDownloadedDate;
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
        NSString *syncIdentifier = [self syncIdentifierForNode:node];
        if(syncIdentifier)
        {
            [syncIdentifiers addObject:syncIdentifier];
        }
    }
    return syncIdentifiers;
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inRealm:(RLMRealm *)realm
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:realm];
    [realm beginWriteTransaction];
    nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
    [realm commitWriteTransaction];
}

#pragma mark - Delete Methods

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    NSString *nodeSyncName = [self syncNameForNode:node inRealm:realm];
    NSString *syncNodeContentPath = [[self syncContentDirectoryPathForAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier] stringByAppendingPathComponent:nodeSyncName];
    
    // No error handling here as we don't want to end up with Sync orphans
    [self.fileManager removeItemAtPath:syncNodeContentPath error:nil];
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:realm];
    [[RealmManager sharedManager] deleteRealmObject:nodeInfo inRealm:realm];
}

@end
