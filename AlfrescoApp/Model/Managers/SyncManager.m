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
#import "SyncError.h"
#import "SyncHelper.h"
#import "DownloadManager.h"
#import "UIAlertView+ALF.h"
#import "AccountManager.h"
#import "Account.h"
#import "SyncOperation.h"

static NSString * const kDidAskToSync = @"didAskToSync";

static NSString * const kSyncQueueName = @"syncQueue";
static NSUInteger const kSyncMaxConcurrentOperations = 2;

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
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (atomic, assign) NSInteger nodeChildrenRequestsCount;
@property (nonatomic, strong) NSOperationQueue *syncQueue;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;
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
    if (self.syncQueue.operationCount == 0)
    {
        self.alfrescoSession = alfrescoSession;
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:alfrescoSession];
        self.syncNodesInfo = [NSMutableDictionary dictionary];
        self.syncNodesStatus = [NSMutableDictionary dictionary];
        
        if (self.documentFolderService)
        {
            [self.documentFolderService clearFavoritesCache];
            [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
                
                if (array)
                {
                    [self rearrangeNodesAndSync:array];
                    completionBlock([self topLevelSyncNodesOrNodesInFolder:nil]);
                }
            }];
        }
        else
        {
            [self updateFolderSizes:YES andCheckIfAnyFileModifiedLocally:YES];
        }
    }
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
            nodesInfo = [CoreDataUtils syncNodesInfoForFolderWithId:folder.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        }
        else
        {
            NSString *selectedAccountId = self.alfrescoSession ? self.alfrescoSession.repositoryInfo.identifier : [[[AccountManager sharedManager] selectedAccount] repositoryId];
            SyncRepository *repository = [CoreDataUtils repositoryObjectForRepositoryWithId:selectedAccountId inManagedObjectContext:[CoreDataUtils managedObjectContext]];
            if (repository)
            {
                nodesInfo = [CoreDataUtils topLevelSyncNodesInfoForRepositoryWithId:repository.repositoryId inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    
    // if folder is nil - means favorite nodes are being returned
    if (!folder)
    {
        for (AlfrescoNode *node in syncNodes)
        {
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.isFavorite = YES;
        }
    }
    
    return syncNodes;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    return nodeInfo.syncContentPath;
}

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:nodeId inSyncNodesStatus:self.syncNodesStatus];
    return nodeStatus;
}

- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node
{
    SyncError *syncError = [CoreDataUtils errorObjectForNodeWithId:node.identifier ifNotExistsCreateNew:NO inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    return syncError.errorDescription;
}

#pragma mark - Private Methods

- (void)rearrangeNodesAndSync:(NSArray *)nodes
{
    // top level sync nodes are held in self.syncNodesInfo with key repository Identifier
    if (nodes)
    {
        [self.syncNodesInfo setValue:[nodes mutableCopy] forKey:self.alfrescoSession.repositoryInfo.identifier];
    }
    
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
        NSManagedObjectContext *privateManagedObjectContext = [CoreDataUtils createPrivateManagedObjectContext];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:remoteNode.identifier inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.status = SyncStatusSuccessful;
            
            // getting last modification date for remote sync node
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for local node
            NSMutableDictionary *localNodeInfoToBePreserved = [NSMutableDictionary dictionary];
            SyncNodeInfo *localNodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:remoteNode.identifier inManagedObjectContext:privateManagedObjectContext];
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
                if ([self isNodeModifiedSinceLastDownload:remoteNode inManagedObjectContext:privateManagedObjectContext])
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
                                                refreshExistingSyncNodes:includeExistingSyncNodes
                                                  inManagedObjectContext:privateManagedObjectContext];
            self.syncNodesInfo = nil;
            
            [self updateFolderSizes:YES andCheckIfAnyFileModifiedLocally:NO];
            
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
        [[SyncHelper sharedHelper] removeSyncContentAndInfoInManagedObjectContext:[CoreDataUtils managedObjectContext]];
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSDate *downloadedDate = nil;
    NSDate *localModificationDate = nil;
    if (node.isDocument)
    {
        SyncHelper *syncHelper = [SyncHelper sharedHelper];
        // getting last downloaded date for node from local info
        downloadedDate = [syncHelper lastDownloadedDateForNode:node inManagedObjectContext:managedContext];
        
        // getting downloaded file locally updated Date
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [self contentPathForNode:(AlfrescoDocument *)node];
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    BOOL isModifiedLocally = ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
    
    if (isModifiedLocally)
    {
        SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
        
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [self contentPathForNode:(AlfrescoDocument *)node];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        if (!dateError)
        {
            nodeStatus.localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
        }
    }
    return isModifiedLocally;
}

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes completionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableArray *identifiersForNodesToBeSynced = [nodes valueForKey:@"identifier"];
    NSMutableArray *missingSyncDocumentsInRemote = [NSMutableArray array];
    
    // retrieve stored nodes info for current repository
    NSArray *localNodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
            SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeId inManagedObjectContext:[CoreDataUtils managedObjectContext]];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            // check if there is any problem with removing the node from local sync
            
            [self checkForObstaclesInRemovingDownloadForNode:localNode completionBlock:^(BOOL encounteredObstacle) {
                
                totalChecksForObstacles--;
                
                if (encounteredObstacle == NO)
                {
                    // if no problem with removing the node from local sync then delete the node from local sync nodes
                    [[SyncHelper sharedHelper] deleteNodeFromSync:localNode inRepitory:self.alfrescoSession.repositoryInfo.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
                }
                else
                {
                    // if any problem encountered then set isUnfavoritedHasLocalChanges flag to YES so its not on deleted until its changes are synced to server
                    nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:YES];
                    nodeInfo.parentNode = nil;
                }
                
                if (totalChecksForObstacles == 0)
                {
                    [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    
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
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        }];
    }
    else
    {
        [[DownloadManager sharedManager] saveDocument:document contentPath:contentPath completionBlock:^(NSString *filePath) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
        [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    [self showSyncAlertIfFirstUseWithCompletionBlock:^(BOOL completed) {
        NSString *repositoryId = self.alfrescoSession.repositoryInfo.identifier;
        BOOL isSyncNodesInfoInMemory = ([self.syncNodesInfo objectForKey:repositoryId] != nil);
        
        void (^syncNode)(AlfrescoNode *) = ^ void (AlfrescoNode *nodeToBeSynced)
        {
            // start sync for this node only if s
            if (!isSyncNodesInfoInMemory)
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:NO];
                });
            }
        };
        
        if (isSyncNodesInfoInMemory)
        {
            NSMutableArray *topLevelSyncNodes = [self.syncNodesInfo objectForKey:repositoryId];
            [topLevelSyncNodes addObject:node];
        }
        else
        {
            self.syncNodesInfo = [NSMutableDictionary dictionary];
            [self.syncNodesInfo setValue:@[node] forKey:repositoryId];
        }
        
        if (node.isFolder)
        {
            [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
                if (self.nodeChildrenRequestsCount == 0)
                {
                    syncNode(node);
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
        else
        {
            syncNode(node);
            if (completionBlock != NULL)
            {
                completionBlock(YES);
            }
        }
    }];
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
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        if (nodeInfo)
        {
            nodeInfo.isTopLevelSyncNode = [NSNumber numberWithBool:NO];
        }
        [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
                
                if (self.syncOperations.count == 0)
                {
                    [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    NSString *syncNameForNode = [syncHelper syncNameForNode:document inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:document.identifier inSyncNodesStatus:self.syncNodesStatus];
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    nodeStatus.status = SyncStatusLoading;
    
    NSString *destinationPath = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    
    SyncOperation *downloadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService downloadDocument:document outputStream:outputStream downloadCompletionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            nodeStatus.status = SyncStatusSuccessful;
            nodeStatus.activityType = SyncActivityTypeIdle;
            
            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
            nodeInfo.lastDownloadedDate = [NSDate date];
            nodeInfo.syncContentPath = destinationPath;
            nodeInfo.reloadContent = [NSNumber numberWithBool:NO];
            
            SyncError *syncError = [CoreDataUtils errorObjectForNodeWithId:document.identifier ifNotExistsCreateNew:NO inManagedObjectContext:[CoreDataUtils managedObjectContext]];
            [CoreDataUtils deleteRecordForManagedObject:syncError inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        }
        else
        {
            nodeStatus.status = SyncStatusFailed;
            nodeInfo.reloadContent = [NSNumber numberWithBool:YES];
            
            SyncError *syncError = [CoreDataUtils errorObjectForNodeWithId:document.identifier ifNotExistsCreateNew:YES inManagedObjectContext:[CoreDataUtils managedObjectContext]];
            syncError.errorCode = [NSNumber numberWithInt:error.code];
            syncError.errorDescription = [error localizedDescription];
            
            nodeInfo.syncError = syncError;
        }
        [self.syncOperations removeObjectForKey:document.identifier];
        completionBlock(YES);
        
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        nodeStatus.bytesTransfered = bytesTransferred;
        nodeStatus.totalBytesToTransfer = bytesTotal;
    }];
    [self.syncOperations setValue:downloadOperation forKey:document.identifier];
    [self.syncQueue addOperation:downloadOperation];
}

- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload: %@", [nodes valueForKey:@"name"]);
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (self.syncOperations.count == 0)
                {
                    [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    NSString *syncNameForNode = [syncHelper syncNameForNode:document inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    NSString *nodeExtension = [document.name pathExtension];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:document.identifier inSyncNodesStatus:self.syncNodesStatus];
    SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    
    SyncOperation *uploadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           uploadDocument:document
                                                                              inputStream:contentStream
                                                                    uploadCompletionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
                                                                        if (uploadedDocument)
                                                                        {
                                                                            nodeStatus.status = SyncStatusSuccessful;
                                                                            nodeStatus.activityType = SyncActivityTypeIdle;
                                                                            
                                                                            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                            nodeInfo.lastDownloadedDate = [NSDate date];
                                                                            nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:NO];
                                                                            
                                                                            SyncError *syncError = [CoreDataUtils errorObjectForNodeWithId:document.identifier
                                                                                                                      ifNotExistsCreateNew:NO
                                                                                                                    inManagedObjectContext:[CoreDataUtils managedObjectContext]];
                                                                            [CoreDataUtils deleteRecordForManagedObject:syncError inManagedObjectContext:[CoreDataUtils managedObjectContext]];
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            
                                                                            SyncError *syncError = [CoreDataUtils errorObjectForNodeWithId:document.identifier
                                                                                                                      ifNotExistsCreateNew:YES
                                                                                                                    inManagedObjectContext:[CoreDataUtils managedObjectContext]];
                                                                            syncError.errorCode = [NSNumber numberWithInt:error.code];
                                                                            syncError.errorDescription = [error localizedDescription];
                                                                            
                                                                            nodeInfo.syncError = syncError;
                                                                        }
                                                                        
                                                                        [self.syncOperations removeObjectForKey:document.identifier];
                                                                        if (completionBlock != NULL)
                                                                        {
                                                                            completionBlock(YES);
                                                                        }
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    [self.syncOperations setValue:uploadOperation forKey:document.identifier];
    [self.syncQueue addOperation:uploadOperation];
}

#pragma mark - Public Utilities

- (void)cancelSyncForDocument:(AlfrescoDocument *)document
{
    SyncOperation *syncOperation = [self.syncOperations objectForKey:document.identifier];
    [syncOperation cancelOperation];
    [self.syncOperations removeObjectForKey:document.identifier];
}

- (void)retrySyncForDocument: (AlfrescoDocument *)document
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:document.identifier];
    
    if (nodeStatus.activityType == SyncActivityTypeDownload)
    {
        [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
            [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
        }];
    }
    else
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [CoreDataUtils saveContextForManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:node.identifier inManagedObjectContext:[CoreDataUtils managedObjectContext]];
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
    else
    {
        completionBlock(YES);
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

- (void)updateFolderSizes:(BOOL)updateFolderSizes andCheckIfAnyFileModifiedLocally:(BOOL)checkIfModified
{
    if (updateFolderSizes)
    {
        NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"isFolder == NO && repository.repositoryId == %@", [[[AccountManager sharedManager] selectedAccount] repositoryId]];
        NSArray *documentsInfo = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:documentsPredicate inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        
        for (SyncNodeInfo *nodeInfo in documentsInfo)
        {
            AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.totalSize = ((AlfrescoDocument *)node).contentLength;
            
            if (checkIfModified && nodeStatus.activityType != SyncActivityTypeUpload)
            {
                BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:[CoreDataUtils managedObjectContext]];
                if (isModifiedLocally)
                {
                    nodeStatus.status = SyncStatusOffline;
                    nodeStatus.activityType = SyncActivityTypeUpload;
                }
            }
        }
    }
}

#pragma mark - Status Changed Notification Handling

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    
    SyncNodeStatus *nodeStatus = notification.object;
    NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    
    // update total size for parent folder
    if ([propertyChanged isEqualToString:kSyncTotalSize])
    {
        syncHelper = [SyncHelper sharedHelper];
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeStatus.nodeId inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        
        SyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
        if (parentNodeInfo)
        {
            AlfrescoNode *parentNode = [NSKeyedUnarchiver unarchiveObjectWithData:parentNodeInfo.node];
            SyncNodeStatus *parentNodeStatus = [self syncStatusForNodeWithId:parentNode.identifier];
            
            NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
            parentNodeStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
        }
        else
        {
            // if parent folder is nil - update total size for repository
            NSString *repostoryId = self.alfrescoSession ? self.alfrescoSession.repositoryInfo.identifier : [[[AccountManager sharedManager] selectedAccount] repositoryId];
            SyncNodeStatus *repositorySyncStatus = [syncHelper syncNodeStatusObjectForNodeWithId:repostoryId inSyncNodesStatus:self.syncNodesStatus];
            if (nodeStatus != repositorySyncStatus)
            {
                NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
                repositorySyncStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
            }
        }
    }
    // update sync status for folder depending on its child nodes statuses
    else if ([propertyChanged isEqualToString:kSyncStatus])
    {
        syncHelper = [SyncHelper sharedHelper];
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeStatus.nodeId inManagedObjectContext:[CoreDataUtils managedObjectContext]];
        SyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
        
        if (parentNodeInfo)
        {
            AlfrescoLogDebug(@"Info Log: %@" , syncHelper);
            SyncNodeStatus *parentNodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:parentNodeInfo.syncNodeInfoId inSyncNodesStatus:self.syncNodesStatus];
            NSSet *subNodes = parentNodeInfo.nodes;
            
            SyncStatus syncStatus = SyncStatusSuccessful;
            for (SyncNodeInfo *subNodeInfo in subNodes)
            {
                SyncNodeStatus *subNodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:subNodeInfo.syncNodeInfoId inSyncNodesStatus:self.syncNodesStatus];
                
                if (subNodeStatus.status == SyncStatusLoading)
                {
                    syncStatus = SyncStatusLoading;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusFailed)
                {
                    syncStatus = SyncStatusFailed;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusOffline)
                {
                    syncStatus = SyncStatusOffline;
                    parentNodeStatus.activityType = SyncActivityTypeUpload;
                    break;
                }
                else if (subNodeStatus.status == SyncStatusWaiting)
                {
                    syncStatus = SyncStatusWaiting;
                }
            }
            parentNodeStatus.status = syncStatus;
        }
    }
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
        
        self.syncQueue = [[NSOperationQueue alloc] init];
        self.syncQueue.name = kSyncQueueName;
        self.syncQueue.maxConcurrentOperationCount = kSyncMaxConcurrentOperations;
        self.syncOperations = [NSMutableDictionary dictionary];
        
        self.syncObstacles = @{kDocumentsUnfavoritedOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusChanged:)
                                                     name:kSyncStatusChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
