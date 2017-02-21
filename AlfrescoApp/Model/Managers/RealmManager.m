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

#import "RealmManager.h"

#import "UserAccount.h"
#import "AlfrescoNode+Sync.h"
#import "AccountManager.h"

@interface RealmManager()
@property (nonatomic, strong) RLMRealm *mainThreadRealm;
@end

@implementation RealmManager

+ (RealmManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
        
        if([AccountManager sharedManager].selectedAccount)
        {
            [sharedObject createMainThreadRealmWithCompletionBlock:nil];
        }
    });
    return sharedObject;
}

#pragma mark - Private methods

- (void)createMainThreadRealmWithCompletionBlock:(void (^)(void))completionBlock
{
    if ([NSThread isMainThread])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            _mainThreadRealm = [self createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if (completionBlock)
            {
                completionBlock();
            }
        });
    }
    else
    {
        dispatch_sync(dispatch_get_main_queue(), ^{
            _mainThreadRealm = [self createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if (completionBlock)
            {
                completionBlock();
            }
        });
    }
}

- (RealmSyncError *)createSyncErrorInRealm:(RLMRealm *)realm
{
    RealmSyncError *error = [RealmSyncError new];
    [realm beginWriteTransaction];
    [realm addObject:error];
    [realm commitWriteTransaction];
    return error;
}

- (RealmSyncNodeInfo *)createSyncNodeInfoForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *syncNodeInfo = [RealmSyncNodeInfo new];
    syncNodeInfo.syncNodeInfoId = [node syncIdentifier];
    syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:node];
    syncNodeInfo.title = node.name;
    syncNodeInfo.isFolder = node.isFolder;
    [realm beginWriteTransaction];
    [realm addObject:syncNodeInfo];
    [realm commitWriteTransaction];
    return syncNodeInfo;
}

#pragma mark - Public methods
#pragma mark Realm management methods

- (RLMRealm *)createRealmWithName:(NSString *)realmName
{
    RLMRealmConfiguration *config = [self configForName:realmName];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        NSException *exception = [NSException exceptionWithName:kFailedToCreateRealmDatabase reason:error.description userInfo:@{kRealmSyncErrorKey : error}];
        [exception raise];
    }
    
    return realm;
}

- (void)deleteRealmWithName:(NSString *)realmName
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *realmFilepath = [self configForName:realmName].fileURL.path;
    NSArray<NSString *> *realmFilePaths = @[
                                            realmFilepath,
                                            [realmFilepath stringByAppendingPathExtension:@"lock"],
                                            [realmFilepath stringByAppendingPathExtension:@"log_a"],
                                            [realmFilepath stringByAppendingPathExtension:@"log_b"],
                                            [realmFilepath stringByAppendingPathExtension:@"note"]
                                            ];
    for (NSString *path in realmFilePaths) {
        NSError *error = nil;
        [manager removeItemAtPath:path error:&error];
        if (error) {
            // handle error
        }
    }
    
    _mainThreadRealm = nil;
}

- (RLMRealm *)realmForCurrentThread
{
    RLMRealm *realm = nil;
    if(([NSThread isMainThread]) && (self.mainThreadRealm))
    {
        realm = self.mainThreadRealm;
    }
    else
    {
        realm = [RLMRealm defaultRealm];
    }
    
    return realm;
}

- (RLMRealmConfiguration *)configForName:(NSString *)name
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    
    return config;
}

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account completionBlock:(void (^)(void))completionBlock
{
    [RLMRealmConfiguration setDefaultConfiguration:[self configForName:account.accountIdentifier]];
    [self createMainThreadRealmWithCompletionBlock:completionBlock];
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

#pragma mark Realm object management
- (RealmSyncNodeInfo *)syncNodeInfoForObject:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    [realm refresh];
    RealmSyncNodeInfo *nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId = %@", [node syncIdentifier]].firstObject;
    if(createNew && !nodeInfo)
    {
        nodeInfo = [self createSyncNodeInfoForNode:node inRealm:realm];
    }
    return nodeInfo;
}

- (RealmSyncNodeInfo *)syncNodeInfoForId:(NSString *)nodeId inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = nil;
    
    if (nodeId)
    {
        nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId = %@", nodeId].firstObject;
    }
    
    return nodeInfo;
}

- (RealmSyncError *)errorObjectForNode:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    RealmSyncError *syncError = nil;
    if (node)
    {
        RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [self createSyncErrorInRealm:realm];
            [realm beginWriteTransaction];
            syncError.errorId = [node syncIdentifier];
            [realm commitWriteTransaction];
        }
    }
    return syncError;
}

- (void)updateSyncNodeInfoForNode:(AlfrescoNode *)node lastDownloadedDate:(NSDate *)downloadedDate syncContentPath:(NSString *)syncContentPath inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *syncNodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
    [realm beginWriteTransaction];
    
    if(node)
    {
        syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:node];
        syncNodeInfo.title = node.name;
        syncNodeInfo.isFolder = node.isFolder;
    }
    
    if(downloadedDate)
    {
        syncNodeInfo.lastDownloadedDate = downloadedDate;
    }
    
    if(syncContentPath)
    {
        syncNodeInfo.syncContentPath = syncContentPath;
    }
    
    [realm commitWriteTransaction];
}

- (void)savePermissions:(AlfrescoPermissions *)permissions forNode:(AlfrescoNode *)node
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
    if(nodeInfo && !nodeInfo.invalidated)
    {
        [realm beginWriteTransaction];
        nodeInfo.permissions = [NSKeyedArchiver archivedDataWithRootObject:permissions];
        [realm commitWriteTransaction];
    }
}

- (void)deleteRealmObject:(RLMObject *)objectToDelete inRealm:(RLMRealm *)realm
{
    if(objectToDelete)
    {
        [realm beginWriteTransaction];
        [realm deleteObject:objectToDelete];
        [realm commitWriteTransaction];
    }
}

- (void)deleteRealmObjects:(NSArray *)objectsToDelete inRealm:(RLMRealm *)realm
{
    [realm beginWriteTransaction];
    for(RLMObject *object in objectsToDelete)
    {
        if ([object isKindOfClass:[RealmSyncNodeInfo class]] && !object.isInvalidated)
        {
            // Delete the associated RealmSyncError, if exists.
            RealmSyncError *realmSyncError = ((RealmSyncNodeInfo *)object).syncError;
            
            if (realmSyncError)
            {
                [realm deleteObject:realmSyncError];
            }
        }
        
        [realm deleteObject:object];
    }
    [realm commitWriteTransaction];
}

- (RLMResults *)allSyncNodesInRealm:(RLMRealm *)realm
{
    RLMResults *results = [RealmSyncNodeInfo allObjectsInRealm:realm];
    return results;
}

- (RLMResults *)topLevelSyncNodesInRealm:(RLMRealm *)realm
{
    RLMResults *allSyncNodes = [self allSyncNodesInRealm:realm];
    RLMResults *results = [allSyncNodes objectsWhere:@"isTopLevelSyncNode = YES"];
    return results;
}

- (RLMResults *)topLevelFoldersInRealm:(RLMRealm *)realm
{
    RLMResults *topLevelSyncNodes = [self topLevelSyncNodesInRealm:realm];
    RLMResults *results = [topLevelSyncNodes objectsWhere:@"isFolder = YES"];
    return results;
}

- (RLMResults *)allDocumentsInRealm:(RLMRealm *)realm
{
    RLMResults *allSyncNodes = [self allSyncNodesInRealm:realm];
    RLMResults *results = [allSyncNodes objectsWhere:@"isFolder = NO"];
    return results;
}

- (NSArray *)allNodesWithType:(NodesType)nodesType inFolder:(AlfrescoFolder *)folder recursive:(BOOL)recursive includeTopLevelNodes:(BOOL)shouldIncludeTopLevelNodes inRealm:(RLMRealm *)realm
{
    NSMutableArray *resultsArray = [NSMutableArray new];
    
    RealmSyncNodeInfo *folderSyncNode = [self syncNodeInfoForObject:folder ifNotExistsCreateNew:NO inRealm:realm];
    if (folderSyncNode)
    {
        if (nodesType == NodesTypeFolders || nodesType == NodesTypeDocumentsAndFolders)
        {
            if (folderSyncNode.isTopLevelSyncNode == NO || (folderSyncNode.isTopLevelSyncNode && shouldIncludeTopLevelNodes))
            {
                [resultsArray addObject:folderSyncNode.alfrescoNode];
            }
        }
        
        RLMLinkingObjects *children = folderSyncNode.nodes;
        
        for(RealmSyncNodeInfo *child in children)
        {
            if (child.isFolder && recursive)
            {
                AlfrescoFolder *childFolder = (AlfrescoFolder *)child.alfrescoNode;
                if(childFolder)
                {
                    [resultsArray addObjectsFromArray:[self allNodesWithType:nodesType inFolder:childFolder recursive:recursive includeTopLevelNodes:shouldIncludeTopLevelNodes inRealm:realm]];
                }
            }
            else if (!child.isFolder)
            {
                if (nodesType == NodesTypeDocuments || nodesType == NodesTypeDocumentsAndFolders)
                {
                    AlfrescoNode *childNode = child.alfrescoNode;
                    if(childNode)
                    {
                        if (childNode.isTopLevelSyncNode == NO || (childNode.isTopLevelSyncNode && shouldIncludeTopLevelNodes))
                        {
                            [resultsArray addObject:childNode];
                        }
                    }
                }
            }
        }
    }
    
    return resultsArray;
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inRealm:(RLMRealm *)realm
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:realm];
    [realm beginWriteTransaction];
    nodeInfo.isRemovedFromSyncHasLocalChanges = NO;
    [realm commitWriteTransaction];
}

@end
