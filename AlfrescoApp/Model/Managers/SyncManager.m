//
//  SyncManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncManager.h"
#import "Utility.h"
#import "CoreDataSyncHelper.h"
#import "SyncAccount.h"
#import "SyncNodeInfo.h"
#import "SyncError.h"
#import "SyncHelper.h"
#import "DownloadManager.h"
#import "UIAlertView+ALF.h"
#import "AccountManager.h"
#import "UserAccount.h"
#import "SyncOperation.h"
#import "ConnectivityManager.h"
#import "PreferenceManager.h"

static NSString * const kDidAskToSync = @"didAskToSync";

static NSString * const kSyncQueueName = @"syncQueue";
static NSUInteger const kSyncMaxConcurrentOperations = 2;

static NSString * const kSyncProgressSizeKey = @"syncProgressSize";

/*
 * Sync Obstacle keys
 */
NSString * const kDocumentsRemovedFromSyncOnServerWithLocalChanges = @"removedFromSyncOnServerWithLocalChanges";
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
@property (nonatomic, strong) NSMutableDictionary *permissions;
@property (nonatomic, strong) CoreDataSyncHelper *syncCoreDataHelper;
@property (nonatomic, assign) unsigned long long totalSyncSize;
@property (nonatomic, assign) unsigned long long syncProgressSize;
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
        
        self.syncObstacles = @{kDocumentsRemovedFromSyncOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                               kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        self.syncCoreDataHelper = [[CoreDataSyncHelper alloc] init];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(statusChanged:)
                                                     name:kSyncStatusChangeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(reachabilityChanged:)
                                                     name:kAlfrescoConnectivityChangedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountInfoUpdated:)
                                                     name:kAlfrescoAccountUpdatedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(accountRemoved:)
                                                     name:kAlfrescoAccountRemovedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nodeAdded:)
                                                     name:kAlfrescoNodeAddedOnServerNotification
                                                   object:nil];
        
        [self addObserver:self forKeyPath:kSyncProgressSizeKey options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (NSMutableArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSMutableArray *syncedNodes))completionBlock
{
    if (self.syncQueue.operationCount == 0)
    {
        self.alfrescoSession = alfrescoSession;
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:alfrescoSession];
        self.syncNodesInfo = [NSMutableDictionary dictionary];
        self.syncNodesStatus = [NSMutableDictionary dictionary];
        
        if (self.documentFolderService)
        {
            [self.documentFolderService clear];
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
    NSString *folderKey = folder ? folder.identifier : [self selectedAccountIdentifier];
    NSMutableArray *syncNodes = [[self.syncNodesInfo objectForKey:folderKey] mutableCopy];
    
    if (!syncNodes)
    {
        syncNodes = [NSMutableArray array];
        NSArray *nodesInfo = nil;
        if (folder)
        {
            nodesInfo = [self.syncCoreDataHelper syncNodesInfoForFolderWithId:folder.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
        }
        else
        {
            SyncAccount *syncAccount = [self.syncCoreDataHelper accountObjectForAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
            if (syncAccount)
            {
                nodesInfo = [self.syncCoreDataHelper topLevelSyncNodesInfoForAccountWithId:syncAccount.accountId inManagedObjectContext:nil];
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

- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = [self.permissions objectForKey:node.identifier];
    
    if (!permissions)
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:node.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
        
        if (nodeInfo.permissions)
        {
            permissions = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.permissions];
        }
    }
    return permissions;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:document.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
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
    SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:node.identifier inAccountWithId:[self selectedAccountIdentifier] ifNotExistsCreateNew:NO inManagedObjectContext:nil];
    return syncError.errorDescription;
}

- (void)updateAllSyncNodeStatusWithStatus:(SyncStatus)status
{
    NSArray *nodeStatusKeys = [self.syncNodesStatus allKeys];
    for (NSString *nodeStatusKey in nodeStatusKeys)
    {
        SyncNodeStatus *nodeStatus = self.syncNodesStatus[nodeStatusKey];
        nodeStatus.status = status;
    }
}

#pragma mark - Private Methods

- (void)rearrangeNodesAndSync:(NSArray *)nodes
{
    // top level sync nodes are held in self.syncNodesInfo with key account Identifier
    if (nodes)
    {
        [self.syncNodesInfo setValue:[nodes mutableCopy] forKey:[self selectedAccountIdentifier]];
    }
    
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
    
    if ([self isSyncPreferenceOn])
    {
        [self retrievePermissionsForNodes:nodes withCompletionBlock:^{
            
            if (!hasFolder(nodes))
            {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
                });
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
                                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                    [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:YES];
                                });
                            }
                        }];
                    }
                }
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
            [self retrievePermissionsForNodes:array withCompletionBlock:^{
                
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
            }];
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
    [syncNodesInfoKeys removeObject:[self selectedAccountIdentifier]];
    
    NSArray *topLevelDocuments = documentsInContainer([self selectedAccountIdentifier]);
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
        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:remoteNode.identifier inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.status = SyncStatusSuccessful;
            
            // getting last modification date for remote sync node
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for local node
            NSMutableDictionary *localNodeInfoToBePreserved = [NSMutableDictionary dictionary];
            SyncNodeInfo *localNodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:remoteNode.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:privateManagedObjectContext];
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
                                                        forAccountWithId:[self selectedAccountIdentifier]
                                                            preserveInfo:infoToBePreservedInNewNodes
                                                             permissions:self.permissions
                                                refreshExistingSyncNodes:includeExistingSyncNodes
                                                  inManagedObjectContext:privateManagedObjectContext];
            self.syncNodesInfo = nil;
            self.permissions = nil;
            
            [self updateFolderSizes:YES andCheckIfAnyFileModifiedLocally:NO];
            
            dispatch_async(dispatch_get_main_queue(), ^{
                
                self.totalSyncSize = 0;
                self.syncProgressSize = 0;
                
                unsigned long long totalDownloadSize = [self totalSizeForDocuments:nodesToDownload];
                AlfrescoLogDebug(@"Total Download Size: %@", stringForLongFileSize(totalDownloadSize));
                
                if (totalDownloadSize > kDefaultMaximumAllowedDownloadSize)
                {
                    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.downloadsize.prompt.title", @"sync download size exceeded max alert title")
                                                                    message:[NSString stringWithFormat:NSLocalizedString(@"sync.downloadsize.prompt.message", @"Sync download size"), stringForLongFileSize(totalDownloadSize)]
                                                                   delegate:nil
                                                          cancelButtonTitle:NSLocalizedString(@"sync.downloadsize.prompt.cancel", @"Don't Sync")
                                                          otherButtonTitles:NSLocalizedString(@"sync.downloadsize.prompt.confirm", @"Sync Now"), nil];

                    [alert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                        if (!isCancelButton)
                        {
                            self.totalSyncSize += totalDownloadSize;
                            [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                        }
                    }];
                }
                else
                {
                    self.totalSyncSize += totalDownloadSize;
                    [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
                }
                
                self.totalSyncSize += [self totalSizeForDocuments:nodesToUpload];
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
            [self deleteUnWantedSyncedNodes:nodes inManagedObjectContext:privateManagedObjectContext completionBlock:^(BOOL completed) {
                [self.syncCoreDataHelper saveContextForManagedObjectContext:privateManagedObjectContext];
                [privateManagedObjectContext reset];
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
        [[SyncHelper sharedHelper] removeSyncContentAndInfoInManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
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
        downloadedDate = [syncHelper lastDownloadedDateForNode:node inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:managedContext];
        
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

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes inManagedObjectContext:(NSManagedObjectContext *)managedContext completionBlock:(void (^)(BOOL completed))completionBlock
{
    NSMutableArray *identifiersForNodesToBeSynced = [nodes valueForKey:@"identifier"];
    NSMutableArray *missingSyncDocumentsInRemote = [NSMutableArray array];
    
    // retrieve stored nodes info for current selected account
    NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"isFolder == NO && account.accountId == %@", [self selectedAccountIdentifier]];
    NSArray *localNodes = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:documentsPredicate inManagedObjectContext:managedContext];
    for (SyncNodeInfo *nodeInfo in localNodes)
    {
        // check if remote list dosnt have nodeInfo (indicates the node is removed from sync on server or deleted)
        
        if (![identifiersForNodesToBeSynced containsObject:nodeInfo.syncNodeInfoId])
        {
            [missingSyncDocumentsInRemote addObject:nodeInfo.syncNodeInfoId];
        }
    }
    
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleRemovedFromSync = [_syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    [syncObstableDeleted removeAllObjects];
    [syncObstacleRemovedFromSync removeAllObjects];
    
    __block NSInteger totalChecksForObstacles = missingSyncDocumentsInRemote.count;
    if (totalChecksForObstacles > 0)
    {
        for (NSString *nodeId in missingSyncDocumentsInRemote)
        {
            SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeId inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:managedContext];
            AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            // check if there is any problem with removing the node from local sync
            
            [self checkForObstaclesInRemovingDownloadForNode:localNode inManagedObjectContext:managedContext completionBlock:^(BOOL encounteredObstacle) {
                
                totalChecksForObstacles--;
                
                if (encounteredObstacle == NO)
                {
                    // if no problem with removing the node from local sync then delete the node from local sync nodes
                    [[SyncHelper sharedHelper] deleteNodeFromSync:localNode inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:managedContext];
                }
                else
                {
                    // if any problem encountered then set isRemovedFromSyncHasLocalChanges flag to YES so its not on deleted until its changes are synced to server
                    nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:YES];
                    nodeInfo.parentNode = nil;
                }
                
                if (totalChecksForObstacles == 0)
                {
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
    NSMutableArray *syncObstacleRemovedFromSync = [_syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if(syncObstableDeleted.count > 0 || syncObstacleRemovedFromSync.count > 0)
    {
        obstacles = YES;
    }
    
    return obstacles;
}

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:managedContext];
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleRemovedFromSync = [self.syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:node.identifier completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (alfrescoNode)
            {
                [syncObstacleRemovedFromSync addObject:node];
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

- (void)syncFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer
{
    NSString *contentPath = [self contentPathForNode:document];
    
    NSMutableArray *syncObstaclesRemovedFromSync = [self.syncObstacles objectForKey:kDocumentsRemovedFromSyncOnServerWithLocalChanges];
    
    if (syncToServer)
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
    else
    {
        [[DownloadManager sharedManager] saveDocument:document contentPath:contentPath completionBlock:^(NSString *filePath) {
            [self.fileManager removeItemAtPath:contentPath error:nil];
            [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesRemovedFromSyncNodeIdentifiers = [syncObstaclesRemovedFromSync valueForKey:@"identifier"];
    for (int i = 0;  i < syncObstaclesRemovedFromSyncNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesRemovedFromSyncNodeIdentifiers[i] isEqualToString:document.identifier])
        {
            [syncObstaclesRemovedFromSync removeObjectAtIndex:i];
            break;
        }
    }
}

- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document
{
    NSString *contentPath = [self contentPathForNode:document];
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:contentPath completionBlock:^(NSString *filePath) {
        [self.fileManager removeItemAtPath:contentPath error:nil];
        [[SyncHelper sharedHelper] resolvedObstacleForDocument:document inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }];
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesDeletedNodeIdentifiers = [syncObstableDeleted valueForKey:@"identifier"];
    for (int i = 0;  i < syncObstaclesDeletedNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesDeletedNodeIdentifiers[i] isEqualToString:document.identifier])
        {
            [syncObstableDeleted removeObjectAtIndex:i];
            break;
        }
    }
}

#pragma mark - Private Utilities

- (NSString *)selectedAccountIdentifier
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    return [self accountIdentifierForAccount:selectedAccount];
}

- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount
{
    NSString *accountIdentifier = userAccount.accountIdentifier;
    
    if (userAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, userAccount.selectedNetworkId];
    }
    return accountIdentifier;
}

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
    NSString *selectedAccountIdentifier = [self selectedAccountIdentifier];
    BOOL isSyncNodesInfoInMemory = ([self.syncNodesInfo objectForKey:selectedAccountIdentifier] != nil);
    
    void (^syncNode)(AlfrescoNode *) = ^ void (AlfrescoNode *nodeToBeSynced)
    {
        // start sync for this node only
        if ([self isSyncPreferenceOn])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                [self syncNodes:[self allRemoteSyncDocuments] includeExistingSyncNodes:NO];
            });
        }
    };
    
    [self retrievePermissionsForNodes:@[node] withCompletionBlock:^{
        
        if (isSyncNodesInfoInMemory)
        {
            NSMutableArray *topLevelSyncNodes = [self.syncNodesInfo objectForKey:selectedAccountIdentifier];
            [topLevelSyncNodes addObject:node];
        }
        else
        {
            self.syncNodesInfo = [NSMutableDictionary dictionary];
            [self.syncNodesInfo setValue:@[node] forKey:selectedAccountIdentifier];
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
    SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
    
    if (self.syncNodesInfo)
    {
        NSMutableArray *topLevelSyncNodes = [self.syncNodesInfo objectForKey:[self selectedAccountIdentifier]];
        NSInteger nodeIndex = [[topLevelSyncNodes valueForKey:@"identifier"] indexOfObject:node.identifier];
        if (nodeIndex != NSNotFound)
        {
            [topLevelSyncNodes removeObjectAtIndex:nodeIndex];
        }
    }
    else
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:node.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
        if (nodeInfo)
        {
            nodeInfo.isTopLevelSyncNode = [NSNumber numberWithBool:NO];
            if (!nodeInfo.parentNode)
            {
                nodeStatus.totalSize = 0;
                nodeStatus.status = SyncStatusRemoved;
                [self.syncNodesStatus removeObjectForKey:node.identifier];
            }
            else
            {
                // this is to trigger notification so the sync root view updates its total count
                nodeStatus.totalSize = nodeStatus.totalSize;
            }
        }
        [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(YES);
    }
}

- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock
{
    SyncNodeStatus *syncNodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
    syncNodeStatus.totalSize = 0;
    
    [self checkForObstaclesInRemovingDownloadForNode:node inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext completionBlock:^(BOOL encounteredObstacle) {
        
        if (node.isDocument && encounteredObstacle)
        {
            [self saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)node];
            completionBlock(YES);
        }
        else
        {
            SyncHelper *syncHelper = [SyncHelper sharedHelper];
            [syncHelper deleteNodeFromSync:node inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
            completionBlock(NO);
        }
    }];
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
                    [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                    if (completionBlock != NULL)
                    {
                        completionBlock(YES);
                    }
                }
            }];
        }
    }
}

- (void)retrievePermissionsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(void))completionBlock
{
    if (!self.permissions)
    {
        self.permissions = [NSMutableDictionary dictionary];
    }
    
    __block NSInteger totalPermissionRequests = nodes.count;
    
    if (nodes.count == 0)
    {
        completionBlock();
    }
    else
    {
        for (AlfrescoNode *node in nodes)
        {
            [self.documentFolderService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                
                totalPermissionRequests--;
                
                if (permissions)
                {
                    [self.permissions setObject:permissions forKey:node.identifier];
                }
                
                if (totalPermissionRequests == 0 && completionBlock != NULL)
                {
                    completionBlock();
                }
            }];
        }
    }
}

- (void)downloadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    NSString *syncNameForNode = [syncHelper syncNameForNode:document inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:document.identifier inSyncNodesStatus:self.syncNodesStatus];
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:document.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
    nodeStatus.status = SyncStatusLoading;
    
    NSString *destinationPath = [[syncHelper syncContentDirectoryPathForAccountWithId:[self selectedAccountIdentifier]] stringByAppendingPathComponent:syncNameForNode];
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
            
            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:document.identifier inAccountWithId:[self selectedAccountIdentifier] ifNotExistsCreateNew:NO inManagedObjectContext:nil];
            [self.syncCoreDataHelper deleteRecordForManagedObject:syncError inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }
        else
        {
            nodeStatus.status = SyncStatusFailed;
            nodeInfo.reloadContent = [NSNumber numberWithBool:YES];
            
            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:document.identifier inAccountWithId:[self selectedAccountIdentifier] ifNotExistsCreateNew:YES inManagedObjectContext:nil];
            syncError.errorCode = @(error.code);
            syncError.errorDescription = [error localizedDescription];
            
            nodeInfo.syncError = syncError;
        }
        [self.syncOperations removeObjectForKey:document.identifier];
        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
        completionBlock(YES);
        
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        self.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
        nodeStatus.bytesTransfered = bytesTransferred;
        nodeStatus.totalBytesToTransfer = bytesTotal;
    }];
    [self.syncOperations setValue:downloadOperation forKey:document.identifier];
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
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
                    [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
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
    NSString *syncNameForNode = [syncHelper syncNameForNode:document inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    NSString *nodeExtension = [document.name pathExtension];
    SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:document.identifier inSyncNodesStatus:self.syncNodesStatus];
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:document.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
    nodeStatus.status = SyncStatusLoading;
    NSString *contentPath = [[syncHelper syncContentDirectoryPathForAccountWithId:[self selectedAccountIdentifier]] stringByAppendingPathComponent:syncNameForNode];
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
                                                                            nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:document.identifier
                                                                                                                                     inAccountWithId:[self selectedAccountIdentifier]
                                                                                                                                ifNotExistsCreateNew:NO
                                                                                                                              inManagedObjectContext:nil];
                                                                            [self.syncCoreDataHelper deleteRecordForManagedObject:syncError inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            
                                                                            SyncError *syncError = [self.syncCoreDataHelper errorObjectForNodeWithId:document.identifier
                                                                                                                                     inAccountWithId:[self selectedAccountIdentifier]
                                                                                                                                ifNotExistsCreateNew:YES
                                                                                                                              inManagedObjectContext:nil];
                                                                            syncError.errorCode = @(error.code);
                                                                            syncError.errorDescription = [error localizedDescription];
                                                                            
                                                                            nodeInfo.syncError = syncError;
                                                                        }
                                                                        
                                                                        [self.syncOperations removeObjectForKey:document.identifier];
                                                                        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                        if (completionBlock != NULL)
                                                                        {
                                                                            completionBlock(YES);
                                                                        }
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        self.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    [self.syncOperations setValue:uploadOperation forKey:document.identifier];
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    [self.syncQueue addOperation:uploadOperation];
}

#pragma mark - Public Utilities

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:documentIdentifier];
    
    SyncOperation *syncOperation = [self.syncOperations objectForKey:documentIdentifier];
    [syncOperation cancelOperation];
    [self.syncOperations removeObjectForKey:documentIdentifier];
    nodeStatus.status = SyncStatusFailed;
    
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    self.totalSyncSize -= nodeStatus.totalSize;
    self.syncProgressSize -= nodeStatus.bytesTransfered;
    nodeStatus.bytesTransfered = 0;
}

- (void)retrySyncForDocument: (AlfrescoDocument *)document
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:document.identifier];
    
    self.totalSyncSize += document.contentLength;
    [self notifyProgressDelegateAboutCurrentProgress];
    
    if (nodeStatus.activityType == SyncActivityTypeDownload)
    {
        [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
            [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
    else
    {
        [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
            [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
}

- (void)cancelAllSyncOperations
{
    NSArray *syncDocumentIdentifiers = [self.syncOperations allKeys];
    
    for (NSString *documentIdentifier in syncDocumentIdentifiers)
    {
        [self cancelSyncForDocumentWithIdentifier:documentIdentifier];
    }
    self.totalSyncSize = 0;
    self.syncProgressSize = 0;
}

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node
{
    BOOL isInSyncList = NO;
    SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:node.identifier inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:nil];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode.boolValue || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (BOOL)isCurrentlySyncing
{
    return (self.syncQueue.operationCount > 0);
}

- (BOOL)isFirstUse
{
    BOOL didAskToSync = [[NSUserDefaults standardUserDefaults] boolForKey:kDidAskToSync];
    return !didAskToSync;
}

/*
 * shows if sync is enabled based on cellular / wifi preference
 */
- (BOOL)isSyncEnabled
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    BOOL syncPreferenceEnabled = selectedAccount.isSyncOn;
    BOOL syncOnCellularEnabled = [[PreferenceManager sharedManager] shouldSyncOnCellular];
    
    if (syncPreferenceEnabled)
    {
        BOOL isCurrentlyOnCellular = [[ConnectivityManager sharedManager] isOnCellular];
        BOOL isCurrentlyOnWifi = [[ConnectivityManager sharedManager] isOnWifi];
        
        // if the device is on cellular and "sync on cellular" is set OR the device is on wifi, return YES
        if ((isCurrentlyOnCellular && syncOnCellularEnabled) || isCurrentlyOnWifi)
        {
            return YES;
        }
    }
    return NO;
}

- (BOOL)isSyncPreferenceOn
{
    UserAccount *userAccount = [[AccountManager sharedManager] selectedAccount];
    return userAccount.isSyncOn;
}

#pragma mark - UIAlertview Methods

- (void)updateFolderSizes:(BOOL)updateFolderSizes andCheckIfAnyFileModifiedLocally:(BOOL)checkIfModified
{
    if (updateFolderSizes)
    {
        NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
        NSPredicate *documentsPredicate = [NSPredicate predicateWithFormat:@"isFolder == NO && account.accountId == %@", [self selectedAccountIdentifier]];
        NSArray *documentsInfo = [self.syncCoreDataHelper retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:documentsPredicate inManagedObjectContext:privateManagedObjectContext];
        
        for (SyncNodeInfo *nodeInfo in documentsInfo)
        {
            AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
            SyncNodeStatus *nodeStatus = [[SyncHelper sharedHelper] syncNodeStatusObjectForNodeWithId:node.identifier inSyncNodesStatus:self.syncNodesStatus];
            nodeStatus.totalSize = ((AlfrescoDocument *)node).contentLength;
            
            if (checkIfModified && nodeStatus.activityType != SyncActivityTypeUpload)
            {
                BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inManagedObjectContext:privateManagedObjectContext];
                if (isModifiedLocally)
                {
                    nodeStatus.status = SyncStatusWaiting;
                    nodeStatus.activityType = SyncActivityTypeUpload;
                }
            }
        }
        [privateManagedObjectContext reset];
        privateManagedObjectContext = nil;
    }
}

#pragma mark - Status Changed Notification Handling

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    NSManagedObjectContext *privateManagedObjectContext = [self.syncCoreDataHelper createChildManagedObjectContext];
    
    SyncNodeStatus *nodeStatus = notification.object;
    NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    
    // update total size for parent folder
    if ([propertyChanged isEqualToString:kSyncTotalSize])
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeStatus.nodeId inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:privateManagedObjectContext];
        
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
            // if parent folder is nil - update total size for account
            SyncNodeStatus *accountSyncStatus = [syncHelper syncNodeStatusObjectForNodeWithId:[self selectedAccountIdentifier] inSyncNodesStatus:self.syncNodesStatus];
            if (nodeStatus != accountSyncStatus)
            {
                NSDictionary *change = [info objectForKey:kSyncStatusChangeKey];
                accountSyncStatus.totalSize += nodeStatus.totalSize - [[change valueForKey:NSKeyValueChangeOldKey] longLongValue];
            }
        }
    }
    // update sync status for folder depending on its child nodes statuses
    else if ([propertyChanged isEqualToString:kSyncStatus])
    {
        SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:nodeStatus.nodeId inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:privateManagedObjectContext];
        SyncNodeInfo *parentNodeInfo = nodeInfo.parentNode;
        
        if (parentNodeInfo)
        {
            NSString *parentNodeId = parentNodeInfo.syncNodeInfoId;
            SyncNodeStatus *parentNodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:parentNodeId inSyncNodesStatus:self.syncNodesStatus];
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
    
    [privateManagedObjectContext reset];
    privateManagedObjectContext = nil;
}

#pragma mark - Sync Progress Information Methods

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncProgressSizeKey])
    {
        [self notifyProgressDelegateAboutCurrentProgress];
    }
}

- (void)notifyProgressDelegateAboutNumberOfNodesInProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(numberOfSyncOperationsInProgress:)])
    {
        [self.progressDelegate numberOfSyncOperationsInProgress:self.syncOperations.count];
    }
}

- (void)notifyProgressDelegateAboutCurrentProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(totalSizeToSync:syncedSize:)])
    {
        [self.progressDelegate totalSizeToSync:self.totalSyncSize syncedSize:self.syncProgressSize];
    }
}

#pragma mark - Account Notifications

- (void)accountInfoUpdated:(NSNotification *)notification
{
    UserAccount *notificationAccount = notification.object;
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    
    if (!notificationAccount.isSyncOn)
    {
        if (notificationAccount == selectedAccount)
        {
            [self cancelAllSyncOperations];
        }
        [syncHelper removeSyncContentAndInfoForAccountWithId:notificationAccount.accountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        [self updateAllSyncNodeStatusWithStatus:SyncStatusRemoved];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *notificationAccount = notification.object;
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    SyncHelper *syncHelper = [SyncHelper sharedHelper];
    
    if (notificationAccount == selectedAccount)
    {
        [self cancelAllSyncOperations];
    }
    [syncHelper removeSyncContentAndInfoForAccountWithId:notificationAccount.accountIdentifier inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
    [self updateAllSyncNodeStatusWithStatus:SyncStatusRemoved];
}

#pragma mark - Reachibility Changed Notification

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    if (!hasInternetConnection)
    {
        self.alfrescoSession = nil;
        self.documentFolderService = nil;
        [self syncDocumentsAndFoldersForSession:nil withCompletionBlock:nil];
    }
}

#pragma mark - Upload Node Notification

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *infoDictionary = notification.object;
    AlfrescoFolder *parentFolder = infoDictionary[kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([self isNodeInSyncList:parentFolder])
    {
        SyncHelper *syncHelper = [SyncHelper sharedHelper];
        AlfrescoNode *subNode = [infoDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        SyncNodeStatus *nodeStatus = [syncHelper syncNodeStatusObjectForNodeWithId:subNode.identifier inSyncNodesStatus:self.syncNodesStatus];
        
        [self retrievePermissionsForNodes:@[subNode] withCompletionBlock:^{
            
            [syncHelper populateNodes:@[subNode]
                       inParentFolder:parentFolder.identifier
                     forAccountWithId:[self selectedAccountIdentifier]
                         preserveInfo:nil
                          permissions:self.permissions
               inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
            
            if (subNode.isFolder)
            {
                nodeStatus.status = SyncStatusSuccessful;
            }
            else
            {
                NSString *syncNameForNode = [syncHelper syncNameForNode:subNode inAccountWithId:[self selectedAccountIdentifier] inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                SyncNodeInfo *nodeInfo = [self.syncCoreDataHelper nodeInfoForObjectWithNodeId:subNode.identifier
                                                                              inAccountWithId:[self selectedAccountIdentifier]
                                                                       inManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
                
                NSURL *contentLocation = infoDictionary[kAlfrescoNodeAddedOnServerContentLocationLocally];
                NSString *destinationURL = [NSURL fileURLWithPath:[[syncHelper syncContentDirectoryPathForAccountWithId:[self selectedAccountIdentifier]] stringByAppendingPathComponent:syncNameForNode]];
                
                NSError *error = nil;
                [[NSFileManager defaultManager] copyItemAtURL:contentLocation toURL:[NSURL fileURLWithPath:destinationURL] error:&error];
                
                nodeStatus.totalSize = [(AlfrescoDocument *)subNode contentLength];
                if (error)
                {
                    nodeStatus.status = SyncStatusFailed;
                }
                else
                {
                    nodeStatus.status = SyncStatusSuccessful;
                    nodeStatus.activityType = SyncActivityTypeIdle;
                    
                    nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:subNode];
                    nodeInfo.lastDownloadedDate = [NSDate date];
                    nodeInfo.syncContentPath = destinationURL;
                    nodeInfo.reloadContent = [NSNumber numberWithBool:NO];
                }
            }
            [self.syncCoreDataHelper saveContextForManagedObjectContext:self.syncCoreDataHelper.managedObjectContext];
        }];
    }
}

@end
