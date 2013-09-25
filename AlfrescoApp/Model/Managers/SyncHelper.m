//
//  SyncHelper.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncHelper.h"
#import "SyncNodeInfo.h"
#import "SyncRepository.h"
#import "CoreDataUtils.h"

NSString * const kLastDownloadedDateKey = @"lastDownloadedDate";
NSString * const kSyncNodeKey = @"node";

static NSString * const kSyncContentDirectory = @"sync/content";

@interface SyncHelper ()
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@end

@implementation SyncHelper

+ (SyncHelper *)sharedHelper
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (void)resetLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo forRepositoryWithId:(NSString *)repositoryId preserveInfo:(NSDictionary *)info
{
    // refresh data in Database for repository
    [self deleteStoredInfoForRepository:repositoryId];
    
    SyncRepository *syncRepository = [CoreDataUtils createSyncRepoMangedObject];
    syncRepository.repositoryId = repositoryId;
    
    NSMutableArray *syncNodesInfoKeys = [[syncNodesInfo allKeys] mutableCopy];
    
    NSArray *topLevelSyncItems = [syncNodesInfo objectForKey:repositoryId];
    
    [self populateNodes:topLevelSyncItems inParentFolder:syncRepository.repositoryId forRepository:repositoryId preserveInfo:info];
    [syncNodesInfoKeys removeObject:repositoryId];
    
    for (NSString *syncFolderInfoKey in syncNodesInfoKeys)
    {
        NSArray *nodesInFolder = [syncNodesInfo objectForKey:syncFolderInfoKey];
        
        if (nodesInFolder.count > 0)
        {
            [self populateNodes:nodesInFolder inParentFolder:syncFolderInfoKey forRepository:repositoryId preserveInfo:info];
        }
    }
    [CoreDataUtils saveContext];
}

- (void)deleteStoredInfoForRepository:(NSString *)repositoryId
{
    NSArray *allNodeInfos = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject];
    for (SyncNodeInfo *nodeInfo in allNodeInfos)
    {
        // delete all sync node info records for current repository so we get everything refreshed (except if file is changed locally but has changes - will be deleted after its uploaded)
        BOOL isUnfavoritedHasLocalChanges = [nodeInfo.isUnfavoritedHasLocalChanges intValue];
        if (!isUnfavoritedHasLocalChanges && [nodeInfo.repository.repositoryId isEqualToString:repositoryId])
        {
            [CoreDataUtils deleteRecordForManagedObject:nodeInfo];
        }
    }
}

- (void)populateNodes:(NSArray *)nodes inParentFolder:(NSString *)folderId forRepository:(NSString *)repositoryId preserveInfo:(NSDictionary *)info
{
    id (^objectInManagedObjectContextForNode)(NSString *) = ^ id (NSString *nodeId)
    {
        id objectInManagedContext = nil;
        NSSet *managedContextRegisteredObjects = [[CoreDataUtils managedObjectContext] registeredObjects];
        for (NSManagedObject *object in managedContextRegisteredObjects)
        {
            if ([object isKindOfClass:[SyncNodeInfo class]])
            {
                SyncNodeInfo *nodeInfo = (SyncNodeInfo *)object;
                if ([nodeInfo.syncNodeInfoId isEqualToString:nodeId])
                {
                    objectInManagedContext = nodeInfo;
                    break;
                }
            }
            else if ([object isKindOfClass:[SyncRepository class]])
            {
                SyncRepository *syncRepository = (SyncRepository *)object;
                if ([syncRepository.repositoryId isEqualToString:nodeId])
                {
                    objectInManagedContext = syncRepository;
                    break;
                }
            }
        }
        return objectInManagedContext;
    };
    
    BOOL (^updateInfoWithExistingInfoForSyncNode)(SyncNodeInfo *) = ^ BOOL (SyncNodeInfo *nodeInfo)
    {
        NSDictionary *infoTobePreserved = [info objectForKey:nodeInfo.syncNodeInfoId];
        
        if (infoTobePreserved)
        {
            AlfrescoNode *existingNode = [infoTobePreserved objectForKey:kSyncNodeKey];
            nodeInfo.lastDownloadedDate = [infoTobePreserved objectForKey:kLastDownloadedDateKey];
            
            if (existingNode)
            {
                nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:existingNode];
            }
        }
        return YES;
    };
    
    
    for (AlfrescoNode *alfrescoNode in nodes)
    {
        // check if we already have object in managedContext for alfrescoNode
        SyncNodeInfo *syncNodeInfo = objectInManagedObjectContextForNode(alfrescoNode.identifier);
        
        // create new nodeInfo for node if it does not exist yet
        if (!syncNodeInfo)
        {
            syncNodeInfo = [CoreDataUtils createSyncNodeInfoMangedObject];
            syncNodeInfo.syncNodeInfoId = alfrescoNode.identifier;
            syncNodeInfo.isFolder = [NSNumber numberWithBool:alfrescoNode.isFolder];
            syncNodeInfo.syncName = [self syncNameForNode:alfrescoNode];
            syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:alfrescoNode];
            syncNodeInfo.repository = objectInManagedObjectContextForNode(repositoryId);
            
        }
        
        // update node info with existing info for documents (will get their new info once they are successfully downloaded) - for folders update their nodes
        if ([syncNodeInfo.isFolder intValue])
        {
            syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:alfrescoNode];
        }
        else
        {
            updateInfoWithExistingInfoForSyncNode(syncNodeInfo);
        }
        
        // retrieve existing or create new parent folder in managed context
        id parentNodeInfo = objectInManagedObjectContextForNode(folderId);
        if (parentNodeInfo == nil)
        {
            parentNodeInfo = [CoreDataUtils createSyncNodeInfoMangedObject];
            [parentNodeInfo setIsFolder:[NSNumber numberWithBool:YES]];
        }
        [parentNodeInfo addNodesObject:syncNodeInfo];
    }
}

- (NSString *)syncNameForNode:(AlfrescoNode *)node
{
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier];
    
    if (nodeInfo.syncName == nil || [nodeInfo.syncName isEqualToString:@""])
    {
        NSString *newName = @"";
        NSString *nodeExtension = [node.name pathExtension];
        
        if (nodeExtension == nil || [nodeExtension isEqualToString:@""])
        {
            newName = [node.identifier lastPathComponent];
        }
        else
        {
            newName = [NSString stringWithFormat:@"%@.%@", [node.identifier lastPathComponent], nodeExtension];
        }
        nodeInfo.syncName = newName;
        [CoreDataUtils saveContext];
    }
    return nodeInfo.syncName;
}

- (NSString *)syncContentDirectoryPathForRepository:(NSString *)repositoryId
{
    NSString *contentDirectory = [self.fileManager.homeDirectory stringByAppendingPathComponent:kSyncContentDirectory];
    if (repositoryId)
    {
        contentDirectory = [contentDirectory stringByAppendingPathComponent:repositoryId];
    }
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:contentDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    return contentDirectory;
}

#pragma mark - SyncInfo Utilities

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId
{
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeId];
    if (nodeInfo.node)
    {
        return [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
    }
    return nil;
}

- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node
{
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier];
    return nodeInfo.lastDownloadedDate;
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
    nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:NO];
    [CoreDataUtils saveContext];
}

#pragma mark - Delete Methods

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRepitory:(NSString *)repositoryId
{
    NSString *nodeSyncName = [self syncNameForNode:node];
    NSString *syncNodeContentPath = [[self syncContentDirectoryPathForRepository:repositoryId] stringByAppendingPathComponent:nodeSyncName];
    
    NSError *error = nil;
    [self.fileManager removeItemAtPath:syncNodeContentPath error:&error];
    
    if (!error)
    {
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier];
        [CoreDataUtils deleteRecordForManagedObject:nodeInfo];
    }
}

- (void)deleteNodesFromSync:(NSArray *)array inRepitory:(NSString *)repositoryId
{
    for (AlfrescoNode *node in array)
    {
        [self deleteNodeFromSync:node inRepitory:repositoryId];
    }
    [CoreDataUtils saveContext];
}

- (void)removeSyncContentAndInfo
{
    NSString *syncContentDirectory = [self syncContentDirectoryPathForRepository:nil];
    NSError *error = nil;
    [self.fileManager removeItemAtPath:syncContentDirectory error:&error];
    
    if (!error)
    {
        [CoreDataUtils deleteAllRecordsInTable:kSyncRepoManagedObject];
        [CoreDataUtils deleteAllRecordsInTable:kSyncNodeInfoManagedObject];
        [CoreDataUtils saveContext];
    }
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
    }
    return self;
}

@end
