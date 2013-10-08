//
//  SyncManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncManager.h"
#import "Reachability.h"
#import "Utility.h"
#import "CoreDataUtils.h"
#import "SyncRepository.h"
#import "SyncNodeInfo.h"
#import "SyncHelper.h"
#import "DownloadManager.h"
#import "UIAlertView+ALF.h"
#import "AccountManager.h"

static NSString * const kDidAskToSync = @"didAskToSync";

static NSUInteger const kSyncConfirmationOptionYes = 0;
static NSUInteger const kSyncConfirmationOptionNo = 1;

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsUnfavoritedOnServerWithLocalChanges = @"unFavoritedOnServerWithLocalChanges";
NSString * const kDocumentsDeletedOnServerWithLocalChanges = @"deletedOnServerWithLocalChanges";
static NSString * const kDocumentsToBeDeletedLocallyAfterUpload = @"toBeDeletedLocallyAfterUpload";

@interface SyncManager ()
@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) NSMutableDictionary *syncNodesInfo;
@property (nonatomic, strong) NSMutableDictionary *syncNodesStatus;
@property (nonatomic, strong) NSMutableDictionary *syncDownloads;
@property (nonatomic, strong) NSMutableDictionary *syncUploads;
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (nonatomic, assign) NSInteger nodeChildrenRequestsCount;
@end

@implementation SyncManager

#pragma mark - Public Interface

+ (SyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (NSArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSArray *syncedNodes))completionBlock
{
    self.alfrescoSession = alfrescoSession;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:alfrescoSession];
    self.syncNodesInfo = [NSMutableDictionary dictionary];
    self.syncNodesStatus = [NSMutableDictionary dictionary];
    self.syncDownloads = [NSMutableDictionary dictionary];
    self.syncUploads = [NSMutableDictionary dictionary];
    
    [self.documentFolderService clearFavoritesCache];
    [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
        
        if (array)
        {
            [self rearrangeNodesAndSync:array];
            completionBlock(array);
        }
    }];
    return [self topLevelSyncNodesOrNodesInFolder:nil];
}

- (NSMutableArray *)topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)folder
{
    NSString *folderKey = folder ? folder.identifier : self.alfrescoSession.repositoryInfo.identifier;
    NSMutableArray *syncNodes = [[self.syncNodesInfo objectForKey:folderKey] mutableCopy];
    
    if (!syncNodes)
    {
        syncNodes = [NSMutableArray array];
        NSArray *nodesInfo = nil;
        if (folder)
        {
            nodesInfo = [CoreDataUtils syncNodesInfoForFolderWithId:folder.identifier];
        }
        else
        {
            NSArray *repositories = [CoreDataUtils retrieveRecordsForTable:kSyncRepoManagedObject];
            if (repositories.count > 0)
            {
                // temporarily displaying nodes for first repository when offline until Accounts Manager is able to return identifier for selected Account
                SyncRepository *repository = repositories[0];
                nodesInfo = [CoreDataUtils topLevelSyncNodesInfoForRepositoryWithId:repository.repositoryId];
            }
        }
        
        for (SyncNodeInfo *nodeInfo in nodesInfo)
        {
            AlfrescoNode *alfrescoNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            if (alfrescoNode)
            {
                [syncNodes addObject:alfrescoNode];
            }
        }
    }
    return syncNodes;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
    return nodeInfo.syncContentPath;
}

- (SyncNodeStatus *)syncStatusForNode:(AlfrescoNode *)node
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNode:node inSyncNodesStatus:self.syncNodesStatus];
    
    // if user is offline determine if the node is modified locally
    if (!self.alfrescoSession && nodeStatus.activityType != SyncActivityTypeUpload)
    {
        BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node];
        if (isModifiedLocally)
        {
            nodeStatus.status = SyncStatusWaiting;
            nodeStatus.activityType = SyncActivityTypeUpload;
        }
    }
    return nodeStatus;
}

#pragma mark - Private Methods

- (void)rearrangeNodesAndSync:(NSArray *)nodes
{
    // top level sync nodes are held in self.syncNodesInfo with key repository Identifier
    [self.syncNodesInfo setValue:[nodes mutableCopy] forKey:self.alfrescoSession.repositoryInfo.identifier];
    
    void (^checkIfFirstUseAndSync)(void) = ^ (void)
    {
        if ([self isFirstUse])
        {
            [self showSyncAlertIfFirstUseWithCompletionBlock:^(BOOL completed) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
                });
            }];
        }
        else
        {
            [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
        }
    };
    
    BOOL (^hasFolder)(NSArray *) = ^ BOOL (NSArray *nodesArray)
    {
        for (AlfrescoNode *alfrescoNode in nodesArray)
        {
            if (alfrescoNode.isFolder)
            {
                return YES;
            }
        }
        return NO;
    };
    
    if (!hasFolder(nodes))
    {
        checkIfFirstUseAndSync();
    }
    else
    {
        // retrieve nodes for top level sync nodes
        for (AlfrescoNode *node in nodes)
        {
            if (node.isFolder)
            {
                [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                    
                    if (self.nodeChildrenRequestsCount == 0)
                    {
                        checkIfFirstUseAndSync();
                    }
                }];
            }
        }
    }
}

- (void)retrieveNodeHierarchyForNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    if (node.isFolder && ([self.syncNodesInfo objectForKey:node.identifier] == nil))
    {
        self.nodeChildrenRequestsCount++;
        [self.documentFolderService retrieveChildrenInFolder:(AlfrescoFolder *)node completionBlock:^(NSArray *array, NSError *error) {
            
            self.nodeChildrenRequestsCount--;
            // nodes for each folder are held in self.syncNodesInfo with keys folder identifiers
            [self.syncNodesInfo setValue:array forKey:node.identifier];
            for (AlfrescoNode *node in array)
            {
                // recursive call to retrieve nodes hierarchies
                [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                    
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }];
            }
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
}

/*
 returns documents in folder hierarchies
 */
- (NSArray *)allRemoteSyncDocuments
{
    NSArray * (^documentsInContainer)(NSString *) = ^ NSArray * (NSString *containerId)
    {
        NSArray *folderNodes = [self.syncNodesInfo objectForKey:containerId];
        
        NSMutableArray *documents = [NSMutableArray array];
        for (AlfrescoNode *node in folderNodes)
        {
            if (node.isDocument)
            {
                [documents addObject:node];
            }
        }
        return documents;
    };
    
    BOOL (^nodesContainsDocument)(NSArray *, AlfrescoDocument *) = ^ BOOL (NSArray *array, AlfrescoDocument *document)
    {
        BOOL documentExists = NO;
        for (AlfrescoNode *node in array)
        {
            if ([node.identifier isEqualToString:document.identifier])
            {
                documentExists = YES;
            }
        }
        return documentExists;
    };
    
    NSMutableArray *allDocuments = [NSMutableArray array];
    NSMutableArray *syncNodesInfoKeys = [[self.syncNodesInfo allKeys] mutableCopy];
    [syncNodesInfoKeys removeObject:self.alfrescoSession.repositoryInfo.identifier];
    
    NSArray *topLevelDocuments = documentsInContainer(self.alfrescoSession.repositoryInfo.identifier);
    [allDocuments addObjectsFromArray:topLevelDocuments];
    
    for (NSString *syncFolderInfoKey in syncNodesInfoKeys)
    {
        NSArray *folderDocuments = documentsInContainer(syncFolderInfoKey);
        
        for (AlfrescoDocument *document in folderDocuments)
        {
            if (!nodesContainsDocument(topLevelDocuments, document))
            {
                [allDocuments addObject:document];
            }
        }
    }
    return allDocuments;
}

- (void)syncNodes:(NSArray *)nodes includeExistingSyncNodes:(BOOL)includeExistingSyncNodes
{
    if ([self isSyncEnabled])
    {
        NSMutableArray *nodesToUpload = [[NSMutableArray alloc] init];
        NSMutableArray *nodesToDownload = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *infoToBePreservedInNewNodes = [NSMutableDictionary dictionary];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNode:remoteNode inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.status = SyncStatusSuccessful;
            
            // getting last modification date for remote sync node
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for local node
            NSMutableDictionary *localNodeInfoToBePreserved = [NSMutableDictionary dictionary];
            SyncNodeInfo *localNodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:remoteNode.identifier];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:localNodeInfo.node];
            if (localNode)
            {
                // preserve node info until they are successfully downloaded or uploaded
                [localNodeInfoToBePreserved setValue:localNodeInfo.lastDownloadedDate forKey:kLastDownloadedDateKey];
                [localNodeInfoToBePreserved setValue:localNodeInfo.syncContentPath forKey:kSyncContentPathKey];
            }
            [infoToBePreservedInNewNodes setValue:localNodeInfoToBePreserved forKey:remoteNode.identifier];
            
            NSDate *lastModifiedDateForLocal = localNode.modifiedAt;
            
            if (remoteNode.name != nil && ![remoteNode.name isEqualToString:@""])
            {
                if ([self isNodeModifiedSinceLastDownload:remoteNode])
                {
                    [nodesToUpload addObject:remoteNode];
                    nodeStatus.status = SyncStatusWaiting;
                    nodeStatus.activityType = SyncActivityTypeUpload;
                }
                else
                {
                    if (lastModifiedDateForLocal != nil && lastModifiedDateForRemote != nil)
                    {
                        // Check if document is updated on server
                        BOOL reloadContent = [localNodeInfo.reloadContent intValue];
                        if (reloadContent || ([lastModifiedDateForLocal compare:lastModifiedDateForRemote] == NSOrderedAscending))
                        {
                            nodeStatus.status = SyncStatusWaiting;
                            nodeStatus.activityType = SyncActivityTypeDownload;
                            [nodesToDownload addObject:remoteNode];
                            [localNodeInfoToBePreserved setValue:[NSNumber numberWithBool:YES] forKey:kSyncReloadContentKey];
                        }
                    }
                    else
                    {
                        nodeStatus.status = SyncStatusWaiting;
                        nodeStatus.activityType = SyncActivityTypeDownload;
                        [nodesToDownload addObject:remoteNode];
                        [localNodeInfoToBePreserved setValue:[NSNumber numberWithBool:YES] forKey:kSyncReloadContentKey];
                    }
                }
            }
        }
        
        // block to syncs info and content for qualified nodes
        void (^syncInfoandContent)(void) = ^ void (void)
        {
            [[SyncHelper sharedHelper] updateLocalSyncInfoWithRemoteInfo:self.syncNodesInfo
                                                     forRepositoryWithId:self.alfrescoSession.repositoryInfo.identifier
                                                            preserveInfo:infoToBePreservedInNewNodes
                                                refreshExistingSyncNodes:includeExistingSyncNodes];
            self.syncNodesInfo = nil;
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                unsigned long long totalDownloadSize = [self totalSizeForDocuments:nodesToDownload];
                AlfrescoLogDebug(@"Total Download Size: %@", stringForLongFileSize(totalDownloadSize));
                
                if (totalDownloadSize > kDefaultMaximumAllowedDownloadSize)
                {
                    NSString *totalSizeString = stringForLongFileSize(totalDownloadSize);
                    NSString *maxAllowedString = stringForLongFileSize(kDefaultMaximumAllowedDownloadSize);
                    NSString *confirmationTitle = NSLocalizedString(@"sync.downloadsize.prompt.title", @"sync download size exceeded max alert title");
                    NSString *confirmationMessage = [NSString stringWithFormat:NSLocalizedString(@"sync.downloadsize.prompt.message", @"sync download size message alert message"), totalSizeString, maxAllowedString];
                    
                    [self displayConfirmationAlertWithTitle:confirmationTitle message:confirmationMessage completionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                        if (buttonIndex == kSyncConfirmationOptionYes)
                        {
                            [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                        }
                    }];
                }
                else
                {
                    [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                }
                
                [self uploadContentsForNodes:nodesToUpload withCompletionBlock:nil];
                
                if ([self didEncounterObstaclesDuringSync])
                {
                    NSDictionary *syncObstacles = @{kSyncObstaclesKey : [self syncObstacles]};
                    [[NSNotificationCenter defaultCenter] postNotificationName:kSyncObstaclesNotification object:nil userInfo:syncObstacles];
                }
            });
        };
        
        if (includeExistingSyncNodes)
        {
            [self deleteUnWantedSyncedNodes:nodes completionBlock:^(BOOL completed) {
                syncInfoandContent();
            }];
        }
        else
        {
            syncInfoandContent();
        }
    }
    else
    {
        [[SyncHelper sharedHelper] removeSyncContentAndInfo];
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node
{
    NSDate *downloadedDate = nil;
    NSDate *localModificationDate = nil;
    if (node.isDocument)
    {
        SyncHelper *syncHelper = [SyncHelper sharedHelper];
        // getting last downloaded date for node from local info
        downloadedDate = [syncHelper lastDownloadedDateForNode:node];
        
        // getting downloaded file locally updated Date
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [self contentPathForNode:(AlfrescoDocument *)node];
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    
    return ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
}

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes completionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableArray *identifiersForNodesToBeSynced = [nodes valueForKey:@"identifier"];
    NSMutableArray *missingSyncDocumentsInRemote = [NSMutableArray array];
    
    // retrieve stored nodes info for current repository
    NSArray *localNodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject];
    for (SyncNodeInfo *nodeInfo in localNodes)
    {
        BOOL isFolder = [nodeInfo.isFolder intValue];
        if (!isFolder && [nodeInfo.repository.repositoryId isEqualToString:self.alfrescoSession.repositoryInfo.identifier])
        {
            // check if remote list dosnt have nodeInfo (indicates the node is unfavorited or deleted)
            
            if (![identifiersForNodesToBeSynced containsObject:nodeInfo.syncNodeInfoId])
            {
                [missingSyncDocumentsInRemote addObject:nodeInfo.syncNodeInfoId];
            }
        }
    }
    
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    [syncObstableDeleted removeAllObjects];
    [syncObstacleUnFavorited removeAllObjects];
    
    __block int totalChecksForObstacles = missingSyncDocumentsInRemote.count;
    
    if (totalChecksForObstacles > 0)
    {
        for (NSString *nodeId in missingSyncDocumentsInRemote)
        {
            SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeId];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            // check if there is any problem with removing the node from local sync
            
            [self checkForObstaclesInRemovingDownloadForNode:localNode completionBlock:^(BOOL encounteredObstacle) {
                
                totalChecksForObstacles--;
                
                if (encounteredObstacle == NO)
                {
                    // if no problem with removing the node from local sync then delete the node from local sync nodes
                    [[SyncHelper sharedHelper] deleteNodeFromSync:localNode inRepitory:self.alfrescoSession.repositoryInfo.identifier];
                }
                else
                {
                    // if any problem encountered then set isUnfavoritedHasLocalChanges flag to YES so its not on deleted until its changes are synced to server
                    nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:YES];
                    nodeInfo.parentNode = nil;
                }
                
                if (totalChecksForObstacles == 0)
                {
                    [CoreDataUtils saveContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
    else
    {
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }
}

#pragma mark - Sync Obstacle Methods

- (BOOL)didEncounterObstaclesDuringSync
{
    BOOL obstacles = NO;
    
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [_syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if(syncObstableDeleted.count > 0 || syncObstacleUnFavorited.count > 0)
    {
        obstacles = YES;
    }
    
    return obstacles;
}

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node];
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [self.syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:node.identifier completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (alfrescoNode)
            {
                [syncObstacleUnFavorited addObject:node];
            }
            else
            {
                [syncObstableDeleted addObject:node];
            }
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
    else
    {
        if (completionBlock != NULL)
        {
            completionBlock(NO);
        }
    }
}

- (NSDictionary *)nodesWithObstacleDuringSync
{
    return self.syncObstacles;
}

- (void)syncUnfavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer
{
    NSString *contentPath = [self contentPathForNode:document];
    
    NSMutableArray *syncObstaclesUnfavorited = [self.syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if (syncToServer)
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document];
        }];
    }
    else
    {
        [[DownloadManager sharedManager] saveDocument:document contentPath:contentPath completionBlock:^(NSString *filePath) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document];
        }];
    }
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesUnfavoritedNodesIds = [syncObstaclesUnfavorited valueForKey:@"identifier"];
    for (int i = 0;  i < syncObstaclesUnfavoritedNodesIds.count; i++)
    {
        if ([syncObstaclesUnfavoritedNodesIds[i] isEqualToString:document.identifier])
        {
            [syncObstaclesUnfavorited removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)saveDeletedFavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document
{
    NSString *contentPath = [self contentPathForNode:document];
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:contentPath completionBlock:^(NSString *filePath) {
        [self.fileManager removeItemAtPath:contentPath error:nil];
        [[SyncHelper sharedHelper] resolvedObstacleForDocument:document];
    }];
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesUnfavoritedNodesIds = [syncObstableDeleted valueForKey:@"identifier"];
    for (int i = 0;  i < syncObstaclesUnfavoritedNodesIds.count; i++)
    {
        if ([syncObstaclesUnfavoritedNodesIds[i] isEqualToString:document.identifier])
        {
            [syncObstableDeleted removeObjectAtIndex:i];
            break;
        }
    }
}

#pragma mark - Private Utilities

- (unsigned long long)totalSizeForDocuments:(NSArray *)documents
{
    unsigned long long totalSize = 0;
    
    for (AlfrescoDocument *document in documents)
    {
        totalSize += document.contentLength;
    }
    return totalSize;
}

- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSString *repositoryId = self.alfrescoSession.repositoryInfo.identifier;
    BOOL isSyncNodesInfoInMemory = ([self.syncNodesInfo objectForKey:repositoryId] != nil);
    
    void (^addNodeToExistingSyncNodes)(AlfrescoNode *) = ^ void (AlfrescoNode *nodeToBeSynced)
    {
        if (isSyncNodesInfoInMemory)
        {
            NSMutableArray *topLevelSyncNodes = [self.syncNodesInfo objectForKey:repositoryId];
            [topLevelSyncNodes addObject:node];
        }
        else
        {
            [self.syncNodesInfo setValue:node forKey:repositoryId];
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:NO];
            });
        }
    };
    
    if (node.isFolder)
    {
        [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
            addNodeToExistingSyncNodes(node);
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }];
    }
    else
    {
        addNodeToExistingSyncNodes(node);
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }
}

- (void)removeNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSString *repositoryId = self.alfrescoSession.repositoryInfo.identifier;
    if (self.syncNodesInfo)
    {
        NSMutableArray *topLevelSyncNodes = [self.syncNodesInfo objectForKey:repositoryId];
        NSInteger nodeIndex = [[topLevelSyncNodes valueForKey:@"identifier"] indexOfObject:node.identifier];
        if (nodeIndex != NSNotFound)
        {
            [topLevelSyncNodes removeObjectAtIndex:nodeIndex];
        }
    }
    else
    {
        SyncRepository *repository = [CoreDataUtils repositoryObjectForRepositoryWithId:repositoryId];
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier];
        if (repository)
        {
            [repository removeNodesObject:nodeInfo];
        }
        [CoreDataUtils saveContext];
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(YES);
    }
}

- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to download: %@", [nodes valueForKey:@"name"]);
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self downloadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (self.syncDownloads.count == 0)
                {
                    [CoreDataUtils saveContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
}

- (void)downloadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    NSString *syncNameForNode = [syncHelper syncNameForNode:document];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNode:document inSyncNodesStatus:self.syncNodesStatus];
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
    nodeStatus.status = SyncStatusLoading;
    
    NSString *destinationPath = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    
    AlfrescoRequest *downloadRequest = [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            nodeStatus.status = SyncStatusSuccessful;
            nodeStatus.activityType = SyncActivityTypeIdle;
            
            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
            nodeInfo.lastDownloadedDate = [NSDate date];
            nodeInfo.syncContentPath = destinationPath;
            nodeInfo.reloadContent = [NSNumber numberWithBool:NO];
        }
        else
        {
            nodeStatus.status = SyncStatusFailed;
            nodeInfo.reloadContent = [NSNumber numberWithBool:YES];
        }
        [self.syncDownloads removeObjectForKey:document.identifier];
        completionBlock(YES);
        
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        nodeStatus.bytesTransfered = bytesTransferred;
        nodeStatus.bytesTotal = bytesTotal;
    }];
    [self.syncDownloads setValue:downloadRequest forKey:document.identifier];
}

- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload: %@", [nodes valueForKey:@"name"]);
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (self.syncUploads.count == 0)
                {
                    [CoreDataUtils saveContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
}

- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    NSString *syncNameForNode = [syncHelper syncNameForNode:document];
    NSString *nodeExtension = [document.name pathExtension];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNode:document inSyncNodesStatus:self.syncNodesStatus];
    nodeStatus.status = SyncStatusLoading;
    NSString *contentPath = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:syncNameForNode];
    NSString *mimeType = @"application/octet-stream";
    
    if (nodeExtension != nil && ![nodeExtension isEqualToString:@""])
    {
        mimeType = [Utility mimeTypeForFileExtension:nodeExtension];
    }
    
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:contentPath]];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:contentPath];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    AlfrescoRequest *uploadRequest = [self.documentFolderService updateContentOfDocument:document contentStream:contentStream completionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
        if (uploadedDocument)
        {
            nodeStatus.status = SyncStatusSuccessful;
            nodeStatus.activityType = SyncActivityTypeIdle;
            SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
            nodeInfo.lastDownloadedDate = [NSDate date];
            nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:NO];
        }
        else
        {
            nodeStatus.status = SyncStatusFailed;
        }
        
        [self.syncUploads removeObjectForKey:document.identifier];
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        nodeStatus.bytesTransfered = bytesTransferred;
        nodeStatus.bytesTotal = bytesTotal;
    }];
    [self.syncUploads setValue:uploadRequest forKey:document.identifier];
}

#pragma mark - Public Utilities

- (void)cancelSyncForDocument:(AlfrescoDocument *)document
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNode:document];
    
    if (nodeStatus.activityType == SyncActivityTypeDownload)
    {
        AlfrescoRequest *downloadRequest = [self.syncDownloads objectForKey:document.identifier];
        [downloadRequest cancel];
        [self.syncDownloads removeObjectForKey:document.identifier];
    }
    else
    {
        AlfrescoRequest *uploadRequest = [self.syncUploads objectForKey:document.identifier];
        [uploadRequest cancel];
        [self.syncUploads removeObjectForKey:document.identifier];
    }
}

- (void)retrySyncForDocument: (AlfrescoDocument *)document
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNode:document];
    
    if (nodeStatus.activityType == SyncActivityTypeDownload)
    {
        [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
            [CoreDataUtils saveContext];
        }];
    }
    else
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [CoreDataUtils saveContext];
        }];
    }
}

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node
{
    BOOL isInSyncList = NO;
    if (self.syncNodesInfo)
    {
        NSArray *allNodes = [[self allRemoteSyncDocuments] valueForKey:@"identifier"];
        if ([allNodes containsObject:node.identifier])
        {
            isInSyncList = YES;
        }
    }
    else
    {
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier];
        if (nodeInfo)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (void)showSyncAlertIfFirstUseWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    if ([self isFirstUse])
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"sync.enable.message", @"Would you like to automatically keep your favorite documents in sync with this %@?"), [[UIDevice currentDevice] model]];
        [self displayConfirmationAlertWithTitle:NSLocalizedString(@"sync.enable.title", @"Sync Documents")
                                        message:message
                                completionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                                    
                                    if (buttonIndex == kSyncConfirmationOptionYes)
                                    {
                                        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kSyncPreference];
                                        [[NSUserDefaults standardUserDefaults] boolForKey:kSyncOnCellular];   // temporary
                                    }
                                    else
                                    {
                                        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:kSyncPreference];
                                    }
                                    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:kDidAskToSync];
                                    [[NSUserDefaults standardUserDefaults] synchronize];
                                    completionBlock(YES);
                                }];
    }
}

- (BOOL)isFirstUse
{
    BOOL didAskToSync = [[NSUserDefaults standardUserDefaults] boolForKey:kDidAskToSync];
    return !didAskToSync;
}

- (BOOL)isSyncEnabled
{
    BOOL syncPreferenceEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kSyncPreference];
    BOOL syncOnCellularEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:kSyncOnCellular];
    
    if (syncPreferenceEnabled)
    {
        Reachability *reachability = [Reachability reachabilityForInternetConnection];
        NetworkStatus status = [reachability currentReachabilityStatus];
        // if the device is on cellular and "sync on cellular" is set OR the device is on wifi, return YES
        if ((status == ReachableViaWWAN && syncOnCellularEnabled) || status == ReachableViaWiFi)
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - UIAlertview Methods

- (void)displayConfirmationAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(UIAlertViewDismissBlock)completionBlock
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:nil
                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), NSLocalizedString(@"No", @"No"), nil];
    [alert showWithCompletionBlock:completionBlock];
}

#pragma mrak - Favorites Methods

- (void)addFavorite:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL succeeded))completionBlock;
{
    __weak SyncManager *weakSelf = self;
    [self.documentFolderService addFavorite:node completionBlock:^(BOOL succeeded, BOOL isFavorited, NSError *error) {
        if (succeeded)
        {
            if ([weakSelf isFirstUse])
            {
                [weakSelf showSyncAlertIfFirstUseWithCompletionBlock:^(BOOL completed) {
                    
                    [weakSelf addNodeToSync:node withCompletionBlock:^(BOOL completed) {
                        if (completionBlock != NULL)
                        {
                            completionBlock(succeeded);
                        }
                    }];
                }];
            }
            else
            {
                [weakSelf addNodeToSync:node withCompletionBlock:^(BOOL completed) {
                    if (completionBlock != NULL)
                    {
                        completionBlock(succeeded);
                    }
                }];
            }
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(NO);
            }
        }
    }];
}

- (void)removeFavorite:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL succeeded))completionBlock;
{
    __weak SyncManager *weakSelf = self;
    [self.documentFolderService removeFavorite:node completionBlock:^(BOOL succeeded, BOOL isFavorited, NSError *error) {
        if (succeeded)
        {
            [weakSelf removeNodeFromSync:node withCompletionBlock:^(BOOL succeeded) {
                if (completionBlock != NULL)
                {
                    completionBlock(succeeded);
                }
            }];
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(succeeded);
            }
        }
    }];
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
        
        self.syncObstacles = @{kDocumentsUnfavoritedOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
    }
    return self;
}


@end
