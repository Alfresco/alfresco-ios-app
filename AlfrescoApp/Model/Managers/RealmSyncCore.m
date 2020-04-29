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

#import "RealmSyncCore.h"
#import "AlfrescoFileManager+Extensions.h"
#import "SyncConstants.h"
#import "AlfrescoNode+Utilities.h"

@implementation RealmSyncCore

#pragma mark - Singleton
+ (RealmSyncCore *)sharedSyncCore
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Realm management
- (RLMRealm *)realmWithIdentifier:(NSString *)identifier
{
    RLMRealmConfiguration *config = [self configForName:identifier];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        NSException *exception = [NSException exceptionWithName:kFailedToCreateRealmDatabase reason:error.description userInfo:@{kRealmSyncErrorKey : error}];
        [exception raise];
    }
    
    return realm;
}

- (RLMRealmConfiguration *)configForName:(NSString *)name
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    if(name.length)
    {
        NSString *configFilePath = nil;
        
        if ([self hasContentMigrationOccured])
        {
            NSURL *sharedAppGroupFolderURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
            configFilePath = [[sharedAppGroupFolderURL.path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
        }
        else
        {
            // Use the default directory, but replace the filename with the accountId
            configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
            
            //check if the file exists in Documents folder, otherwise use the AppGroup path
            if(![[AlfrescoFileManager sharedManager] fileExistsAtPath:configFilePath])
            {
                NSURL *sharedAppGroupFolderURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
                configFilePath = [[sharedAppGroupFolderURL.path stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
            }
        }
        
        config.fileURL = [NSURL URLWithString:configFilePath];
    }
    
    return config;
}

#pragma mark - Realm object methods
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
    
    RealmSyncNodeInfo *folderSyncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:folder ifNotExistsCreateNew:NO inRealm:realm];
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
                    if (child.isTopLevelSyncNode == NO || (child.isTopLevelSyncNode && shouldIncludeTopLevelNodes))
                    {
                        AlfrescoNode *childNode = child.alfrescoNode;
                        [resultsArray addObject:childNode];
                    }
                }
            }
        }
    }
    
    return resultsArray;
}

- (RealmSyncNodeInfo *)syncNodeInfoForObject:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    [realm refresh];
    RealmSyncNodeInfo *nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId = %@", [self syncIdentifierForNode:node]].firstObject;
    if(createNew && !nodeInfo)
    {
        nodeInfo = [self createSyncNodeInfoForNode:node inRealm:realm];
    }
    return nodeInfo;
}

- (RealmSyncNodeInfo *)syncNodeInfoForId:(NSString *)nodeSyncId inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = nil;
    
    if (nodeSyncId.length)
    {
        nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId = %@", nodeSyncId].firstObject;
    }
    
    return nodeInfo;
}

- (RealmSyncNodeInfo *)createSyncNodeInfoForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *syncNodeInfo = [RealmSyncNodeInfo new];
    syncNodeInfo.syncNodeInfoId = [self syncIdentifierForNode:node];
    syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:node];
    syncNodeInfo.title = node.name;
    syncNodeInfo.isFolder = node.isFolder;
    [realm beginWriteTransaction];
    [realm addOrUpdateObject:syncNodeInfo];
    [realm commitWriteTransaction];
    return syncNodeInfo;
}

- (RealmSyncError *)errorObjectForNode:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    RealmSyncError *syncError = nil;
    if (node)
    {
        RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [self createSyncErrorInRealm:realm];
            [realm beginWriteTransaction];
            syncError.errorId = [[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node];
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

- (NSString *)syncIdentifierForNode:(AlfrescoNode *)node
{
    NSString *syncIdentifier = [(AlfrescoProperty *)[node.properties objectForKey:kAlfrescoNodeVersionSeriesIdKey] value];
    if (!syncIdentifier)
    {
        syncIdentifier = [node nodeRefWithoutVersionID];
    }
    return syncIdentifier;
}

- (void)updateSyncNodeInfoForNodeWithSyncId:(NSString *)nodeSyncId alfrescoNode:(AlfrescoNode *)node lastDownloadedDate:(NSDate *)downloadedDate syncContentPath:(NSString *)syncContentPath inRealm:(RLMRealm *)realm
{
    if(nodeSyncId.length == 0)
    {
        nodeSyncId = [self syncIdentifierForNode:node];
    }
    
    RealmSyncNodeInfo *syncNodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForId:nodeSyncId inRealm:realm];
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

- (void)didUploadNode:(AlfrescoNode *)node fromPath:(NSString *)tempPath toFolder:(AlfrescoFolder *)folder forAccountIdentifier:(NSString *)accountIdentifier
{
    RLMRealm *realm = [self realmWithIdentifier:accountIdentifier];
    if([self isNode:folder inSyncListInRealm:realm])
    {
        NSString *syncNameForNode = [self syncNameForNode:node inRealm:realm];
        RealmSyncNodeInfo *syncNodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:YES inRealm:realm];
        RealmSyncNodeInfo *parentSyncNodeInfo = [self syncNodeInfoForObject:folder ifNotExistsCreateNew:NO inRealm:realm];
        
        [realm beginWriteTransaction];
        syncNodeInfo.parentNode = parentSyncNodeInfo;
        syncNodeInfo.isTopLevelSyncNode = NO;
        [realm commitWriteTransaction];
            
        if(node.isDocument)
        {
            NSString *syncContentPath = [[self syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:syncNameForNode];
            
            NSError *movingFileError = nil;
            [[AlfrescoFileManager sharedManager] copyItemAtPath:tempPath toPath:syncContentPath error:&movingFileError];
            
            if(movingFileError)
            {                
                RealmSyncError *syncError = [self errorObjectForNode:node ifNotExistsCreateNew:YES inRealm:realm];
                [realm beginWriteTransaction];
                syncError.errorCode = movingFileError.code;
                syncError.errorDescription = [movingFileError localizedDescription];
                
                syncNodeInfo.syncError = syncError;
                syncNodeInfo.reloadContent = NO;
                [realm commitWriteTransaction];
            }
            else
            {
                [self updateSyncNodeInfoForNodeWithSyncId:nil alfrescoNode:node lastDownloadedDate:[NSDate date] syncContentPath:syncNameForNode inRealm:realm];
                [realm beginWriteTransaction];
                syncNodeInfo.reloadContent = NO;
                [realm commitWriteTransaction];
            }
        }
        else if (node.isFolder)
        {
            [self updateSyncNodeInfoForNodeWithSyncId:nil alfrescoNode:node lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
        }
    }
}

- (void)didUploadNewVersionForDocument:(AlfrescoDocument *)document updatedDocument:(AlfrescoDocument *)updatedDocument fromPath:(NSString *)path forAccountIdentifier:(NSString *)accountIdentifier
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *backgroundRealm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
        if([self isNode:document inSyncListInRealm:backgroundRealm])
        {
            RealmSyncNodeInfo *documentInfo = [self syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
            [backgroundRealm beginWriteTransaction];
            documentInfo.node = [NSKeyedArchiver archivedDataWithRootObject:updatedDocument];
            documentInfo.lastDownloadedDate = [NSDate date];
            [backgroundRealm commitWriteTransaction];
            
            if(path.length)
            {
                NSString *existingDocumentPath = [self contentPathForNode:document forAccountIdentifier:accountIdentifier];
                [[AlfrescoFileManager sharedManager] removeItemAtPath:existingDocumentPath error:nil];
                [[AlfrescoFileManager sharedManager] moveItemAtPath:path toPath:existingDocumentPath error:nil];
            }
        }
    });
}

- (BOOL)isNode:(AlfrescoNode *)node inSyncListInRealm:(RLMRealm *)realm
{
    BOOL isInSyncList = NO;
    RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (NSString *)contentPathForNode:(AlfrescoNode *)node forAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *newNodePath = nil;
    if(accountIdentifier.length)
    {
        RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:[self realmWithIdentifier:accountIdentifier]];
        
        if(nodeInfo && (nodeInfo.isFolder == NO) && nodeInfo.syncContentPath)
        {
            newNodePath = [[self syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:nodeInfo.syncContentPath];
        }
    }
    
    return newNodePath;
}

- (NSString *)syncNameForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
    
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

- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountIdentifier
{
    NSString *contentDirectory = [[AlfrescoFileManager sharedManager] syncFolderPath];
    if (accountIdentifier)
    {
        contentDirectory = [contentDirectory stringByAppendingPathComponent:accountIdentifier];
    }
    
    BOOL dirExists = [[AlfrescoFileManager sharedManager] fileExistsAtPath:contentDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [[AlfrescoFileManager sharedManager] createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return contentDirectory;
}

#pragma mark - Content migration
- (BOOL)isContentMigrationNeeded
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    BOOL isMigrationNeededResult = ![defaults boolForKey:kHasSyncedContentMigrationOccurred];
    //disabling the migration until File Provider support is ready
    isMigrationNeededResult = NO;
    return isMigrationNeededResult;
}

- (BOOL)hasContentMigrationOccured
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    return [defaults boolForKey:kHasSyncedContentMigrationOccurred];
}

- (void)initiateContentMigrationProcessForAccounts:(NSArray *)accounts
{
    void (^saveContentMigrationOccured)(void) = ^()
    {
        NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
        [defaults setBool:YES
                   forKey:kHasSyncedContentMigrationOccurred];
        [defaults synchronize];
    };
    
    if (accounts.count)
    {
        __block BOOL migrationOfRealmFilesSucceded;
        __block BOOL migrationOfSyncFolderSucceded;
        
        [self migrateRealmFilesWithCompletionBlock:^(BOOL succeeded, NSError *error) {
            migrationOfRealmFilesSucceded = succeeded;
        }];
        
        [self migrateSyncFolderWithCompletionBlock:^(BOOL succeeded, NSError *error) {
            migrationOfSyncFolderSucceded = succeeded;
        }];
        
        if (migrationOfRealmFilesSucceded && migrationOfSyncFolderSucceded)
        {
            saveContentMigrationOccured();
        }
    }
    else
    {
        saveContentMigrationOccured();
    }
}

- (void)migrateRealmFilesWithCompletionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    NSURL *sharedAppGroupFolderURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSURL *url = [NSURL URLWithString:documentsDirectoryPath];
    __block NSError *error = nil;
    NSArray *array = [[NSFileManager defaultManager] contentsOfDirectoryAtURL:url includingPropertiesForKeys:@[NSURLNameKey] options:0 error:&error];
    
    if (error)
    {
        AlfrescoLogError(@"Error fetching documents folder content. Error: %@", error.localizedDescription);
    }
    
    __block BOOL moveErrorOccured;
    
    [array enumerateObjectsUsingBlock:^(NSURL *url, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *lastPathComponent = url.lastPathComponent;
        
        if ([lastPathComponent containsString:@"realm"])
        {
            NSString *destinationPath = [sharedAppGroupFolderURL.path stringByAppendingPathComponent:lastPathComponent];
            [[AlfrescoFileManager sharedManager] moveItemAtPath:url.path toPath:destinationPath error:&error];
            
            if (error)
            {
                AlfrescoLogError(@"Error moving a realm file. Error: %@", error.localizedDescription);
                moveErrorOccured = YES;
            }
        }
    }];
    
    completionBlock(moveErrorOccured, error);
}

- (void)migrateSyncFolderWithCompletionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    NSString *documentsDirectoryPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *oldSyncPath = [documentsDirectoryPath stringByAppendingPathComponent:kSyncFolder];
    NSString *newSyncPath = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier].path stringByAppendingPathComponent:kSyncFolder];
    
    NSError *moveError = nil;
    [[AlfrescoFileManager sharedManager] moveItemAtPath:oldSyncPath toPath:newSyncPath error:&moveError];
    
    if (moveError)
    {
        AlfrescoLogError(@"Error moving Sync folder. Error: %@", moveError);
    }
    
    if (completionBlock)
    {
        completionBlock(moveError ? NO : YES, moveError);
    }
}

@end
