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

@implementation RealmManager

+ (RealmManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

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
}

- (RealmSyncNodeInfo *)syncNodeInfoForObjectWithId:(NSString *)objectId ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    [realm refresh];
    RealmSyncNodeInfo *nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId = %@", objectId].firstObject;
    if(createNew && !nodeInfo)
    {
        nodeInfo = [self createSyncNodeInfoForNodeWithId:objectId inRealm:realm];
    }
    return nodeInfo;
}

- (RLMRealmConfiguration *)configForName:(NSString *)name
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    
    return config;
}

- (RealmSyncError *)errorObjectForNodeWithId:(NSString *)nodeId ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    RealmSyncError *syncError = nil;
    
    if (nodeId)
    {
        RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObjectWithId:nodeId ifNotExistsCreateNew:NO inRealm:realm];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [self createSyncErrorInRealm:realm];
            [realm beginWriteTransaction];
            syncError.errorId = nodeId;
            [realm commitWriteTransaction];
        }
    }
    return syncError;
}

- (RealmSyncError *)createSyncErrorInRealm:(RLMRealm *)realm
{
    RealmSyncError *error = [RealmSyncError new];
    [realm beginWriteTransaction];
    [realm addObject:error];
    [realm commitWriteTransaction];
    return error;
    
}

- (RealmSyncNodeInfo *)createSyncNodeInfoForNodeWithId:(NSString *)nodeId inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *syncNodeInfo = [RealmSyncNodeInfo new];
    syncNodeInfo.syncNodeInfoId = nodeId;
    [realm beginWriteTransaction];
    [realm addObject:syncNodeInfo];
    [realm commitWriteTransaction];
    return syncNodeInfo;
}

- (void)updateSyncNodeInfoWithId:(NSString *)objectId withNode:(AlfrescoNode *)node lastDownloadedDate:(NSDate *)downloadedDate syncContentPath:(NSString *)syncContentPath inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *syncNodeInfo = [self syncNodeInfoForObjectWithId:objectId ifNotExistsCreateNew:NO inRealm:realm];
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

- (NSArray *)alfrescoNodesForSyncNodesInRealm:(RLMRealm *)realm
{
    RLMResults *allRealmSyncNodes = [self allSyncNodesInRealm:realm];
    NSMutableArray *alfrescoNodes = [NSMutableArray array];
    
    for (RealmSyncNodeInfo *realmSyncNodeInfo in allRealmSyncNodes)
    {
        if (realmSyncNodeInfo.alfrescoNode)
        {
            [alfrescoNodes addObject:realmSyncNodeInfo.alfrescoNode.identifier];
        }
    }

    return alfrescoNodes;
}

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account
{
    [RLMRealmConfiguration setDefaultConfiguration:[self configForName:account.accountIdentifier]];
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inRealm:(RLMRealm *)realm
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObjectWithId:[document syncIdentifier] ifNotExistsCreateNew:NO inRealm:realm];
    [realm beginWriteTransaction];
    nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
    [realm commitWriteTransaction];
}

@end
