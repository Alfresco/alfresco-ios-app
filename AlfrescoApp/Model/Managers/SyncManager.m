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

static NSString * const kDidAskToSync = @"didAskToSync";

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsUnfavoritedOnServerWithLocalChanges = @"unFavsOnServerWithLocalChanges";
NSString * const kDocumentsDeletedOnServerWithLocalChanges = @"deletedOnServerWithLocalChanges";
NSString * const kDocumentsToBeDeletedLocallyAfterUpload = @"toBeDeletedLocallyAfterUpload";

@interface SyncManager ()
@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) NSMutableDictionary *syncNodesInfo;
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (atomic, assign) NSInteger nodeChildrenRequestsCount;
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
        id localFolder = nil;
        if (folder)
        {
            localFolder = [CoreDataUtils nodeInfoForObjectWithNodeId:folderKey];
        }
        else
        {
            // if folder is nil - retrieve top level sync nodes
            localFolder = [CoreDataUtils repositoryObjectForRepositoryWithId:folderKey];
        }
        
        if (localFolder)
        {
            NSSet *synNodesInfo = [localFolder nodes];
            syncNodes = [NSMutableArray array];
            
            for (SyncNodeInfo *node in synNodesInfo)
            {
                AlfrescoNode *alfrescoNode = [NSKeyedUnarchiver unarchiveObjectWithData:node.node];
                [syncNodes addObject:alfrescoNode];
            }
        }
    }
    return syncNodes;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    return [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:[syncHelper syncNameForNode:document]];
}

#pragma mark - Private Methods

- (void)rearrangeNodesAndSync:(NSArray *)nodes
{
    // top level sync nodes are held in self.syncNodesInfo with key repository Identifier
    [self.syncNodesInfo setValue:nodes forKey:self.alfrescoSession.repositoryInfo.identifier];
    
    // retrieve nodes for top level sync nodes
    for (AlfrescoNode *node in nodes)
    {
        [self retrieveNodeHierarchyForNode:node withCompletionBlock:^(BOOL completed) {
            
            if (self.nodeChildrenRequestsCount == 0)
            {
                
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    
                    [self syncNodes:[self allRemoteSyncDocuments]];
                });
            }
        }];
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

- (void)syncNodes:(NSArray *)nodes
{
    if ([self isSyncEnabled])
    {
        NSMutableArray *nodesToUpload = [[NSMutableArray alloc] init];
        NSMutableArray *nodesToDownload = [[NSMutableArray alloc] init];
        
        NSMutableDictionary *infoToBePreservedInNewNodes = [NSMutableDictionary dictionary];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            // SyncStatusSuccessful;
            
            // getting last modification date for remote sync node
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for local node
            NSMutableDictionary *localNodeInfoToBePreserved = [NSMutableDictionary dictionary];
            SyncNodeInfo *localNodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:remoteNode.identifier];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:localNodeInfo.node];
            if (localNode)
            {
                [localNodeInfoToBePreserved setValue:localNode forKey:kSyncNodeKey];
                [infoToBePreservedInNewNodes setValue:localNodeInfoToBePreserved forKey:localNode.identifier];
            }
            // preserve node info until they are successfully downloaded or uploaded
            [localNodeInfoToBePreserved setValue:localNodeInfo.lastDownloadedDate forKey:kLastDownloadedDateKey];
            
            NSDate *lastModifiedDateForLocal = localNode.modifiedAt;
            
            if (remoteNode.name != nil && ![remoteNode.name isEqualToString:@""])
            {
                if ([self isNodeModifiedSinceLastDownload:remoteNode])
                {
                    [nodesToUpload addObject:remoteNode];
                    // SyncStatusWaiting
                }
                else
                {
                    if (lastModifiedDateForLocal != nil && lastModifiedDateForRemote != nil)
                    {
                        // Check if document is updated on server
                        if ([lastModifiedDateForLocal compare:lastModifiedDateForRemote] == NSOrderedAscending)
                        {
                            // SyncActivityTypeDownload;
                            // SyncStatusWaiting;
                            [nodesToDownload addObject:remoteNode];
                        }
                    }
                    else
                    {
                        // SyncActivityTypeDownload;
                        // SyncStatusWaiting;
                        [nodesToDownload addObject:remoteNode];
                    }
                }
            }
        }
        
        [self deleteUnWantedSyncedNodes:nodes];
        [[SyncHelper sharedHelper] resetLocalSyncInfoWithRemoteInfo:self.syncNodesInfo forRepositoryWithId:self.alfrescoSession.repositoryInfo.identifier preserveInfo:infoToBePreservedInNewNodes];
        self.syncNodesInfo = nil;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            
            [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
            [self uploadContentsForNodes:nodesToUpload withCompletionBlock:nil];
            
            if ([self didEncounterObstaclesDuringSync])
            {
                NSDictionary *syncObstacles = @{@"syncObstacles" : [self syncObstacles]};
                [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSyncObstacles object:syncObstacles userInfo:nil];
            }
        });
    }
    else
    {
        [[SyncHelper sharedHelper] removeSyncContentAndInfo];
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    // getting last downloaded date for repository item from local directory
    NSDate *downloadedDate = [syncHelper lastDownloadedDateForNode:node];   // need to update to get exact date when file was downloaded
    
    // getting downloaded file locally updated Date
    NSError *dateError = nil;
    NSString *pathToSyncedFile = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:[syncHelper syncNameForNode:node]];
    NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
    NSDate *localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    
    return ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
}

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes
{
    NSMutableArray *identifiersForNodesToBeSynced = [nodes valueForKey:@"identifier"];
    NSMutableArray *localNodesForCurrentRepository = [NSMutableArray array];
    
    // retrieve stored nodes info for current repository
    NSArray *localNodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject];
    for (SyncNodeInfo *nodeInfo in localNodes)
    {
        if ([nodeInfo.repository.repositoryId isEqualToString:self.alfrescoSession.repositoryInfo.identifier])
        {
            [localNodesForCurrentRepository addObject:nodeInfo];
        }
    }
    
    for (SyncNodeInfo *nodeInfo in localNodesForCurrentRepository)
    {
        // check if nodeInfo is not a folder and remote list dosnt have nodeInfo (indicates the node is unfavorited or deleted)
        BOOL isFolder = [nodeInfo.isFolder intValue];
        if (!isFolder && ![identifiersForNodesToBeSynced containsObject:nodeInfo.syncNodeInfoId])
        {
            BOOL encounteredObstacle = NO;
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            // check if there is any problem with removing the node from local sync
            encounteredObstacle = [self checkForObstaclesInRemovingDownloadForNode:localNode];
            
            if (encounteredObstacle == NO)
            {
                // if no problem with removing the node from local sync then delete the node from local sync nodes
                [[SyncHelper sharedHelper] deleteNodeFromSync:localNode inRepitory:self.alfrescoSession.repositoryInfo.identifier];
            }
            else
            {
                // if any problem encountered then set isUnfavoritedHasLocalChanges flag to YES so its not on deleted until its changes are synced to server
                nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:YES];
            }
        }
    }
    [CoreDataUtils saveContext];
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

- (BOOL)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node
{
    BOOL isDeletedOnServer = [self isNodeInSyncList:node];
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node];
    
    BOOL encounteredObstacle = NO;
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [self.syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if (isDeletedOnServer && isModifiedLocally)
    {
        if (![[syncObstableDeleted valueForKey:@"identifier"] containsObject:node.identifier])
        {
            [syncObstableDeleted addObject:node];
            encounteredObstacle = YES;
        }
    }
    else if (!isDeletedOnServer && isModifiedLocally)
    {
        if (![[syncObstacleUnFavorited valueForKey:@"identifier"] containsObject:node.identifier])
        {
            [syncObstacleUnFavorited addObject:node];
            encounteredObstacle = YES;
        }
    }
    return encounteredObstacle;
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

- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to download: %@", [nodes valueForKey:@"name"]);
    
    NSInteger (^calculateTotalDownloads)(NSArray *) = ^ NSInteger (NSArray *downloads)
    {
        int numberOfDocuments = 0;
        for (AlfrescoNode *node in downloads)
        {
            if (node.isDocument)
            {
                numberOfDocuments++;
            }
        }
        return numberOfDocuments;
    };
    
    
    __block int totalDownloads = calculateTotalDownloads(nodes);
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self downloadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                totalDownloads--;
                
                if (totalDownloads == 0)
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
    
    NSString *destinationPath = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    
    [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
            nodeInfo.lastDownloadedDate = [NSDate date];
        }
        completionBlock(YES);
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        // TODO: Progress indicator update
    }];
}

- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload number: %d", nodes.count);
    __block int totalUploads = nodes.count;
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                totalUploads--;
                
                if (totalUploads == 0)
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
    NSString *contentPath = [[syncHelper syncContentDirectoryPathForRepository:self.alfrescoSession.repositoryInfo.identifier] stringByAppendingPathComponent:syncNameForNode];
    NSString *mimeType = @"application/octet-stream";
    
    if (nodeExtension != nil && ![nodeExtension isEqualToString:@""])
    {
        mimeType = [Utility mimeTypeForFileExtension:nodeExtension];
    }
    
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:contentPath]];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:contentPath];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    [self.documentFolderService updateContentOfDocument:document contentStream:contentStream completionBlock:^(AlfrescoDocument *document, NSError *error) {
        if (document)
        {
            SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:document.identifier];
            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
            nodeInfo.lastDownloadedDate = [NSDate date];
            nodeInfo.isUnfavoritedHasLocalChanges = [NSNumber numberWithBool:NO];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(NO);
        }
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        
    }];
}

#pragma mark - Public Utilities

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

- (BOOL)isFirstUse
{
    BOOL didAskToSync = [[NSUserDefaults standardUserDefaults] boolForKey:kDidAskToSync];
    if (didAskToSync)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isSyncEnabled
{
    // temporarary set YES until we have preferences set
    BOOL syncPreferenceEnabled = YES;    // [[NSUserDefaults standardUserDefaults] boolForKey:kSyncPreference]
    BOOL syncOnCellularEnabled = YES;    // [[NSUserDefaults standardUserDefaults] boolForKey:kSyncOnCellular]
    
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
