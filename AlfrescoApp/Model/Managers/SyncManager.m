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

static NSString * const kSyncInfoDirectory = @"sync/info";
static NSString * const kSyncContentDirectory = @"sync/content";
static NSString * const kSyncInfoFileName = @"syncInfo.plist";
static NSString * const kLastDownloadedDateKey = @"lastDownloadedDate";
static NSString * const kSyncNodeKey = @"node";

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
@property (nonatomic, strong) NSMutableDictionary *syncedNodesInfo;
@property (nonatomic, strong) NSDictionary *syncObstacles;
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
    
    [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
        
        [self syncNodes:array];
        completionBlock(array);
    }];
    
    // returns local synced files until request completes.
    return nil;
}

#pragma mark - Private Methods

- (NSString *)syncInfoDirectoryPath
{
    NSString *infoDirectory = [self.fileManager.homeDirectory stringByAppendingPathComponent:kSyncInfoDirectory];
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:infoDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:infoDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return infoDirectory;
}

- (NSString *)syncContentDirectoryPath
{
    NSString *contentDirectory = [self.fileManager.homeDirectory stringByAppendingPathComponent:kSyncContentDirectory];
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:contentDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return contentDirectory;
}

- (void)syncNodes:(NSArray *)nodes
{
    if ([self isSyncEnabled])
    {
        NSMutableArray *nodesToUpload = [[NSMutableArray alloc] init];
        NSMutableArray *nodesToDownload = [[NSMutableArray alloc] init];
        
        for (int i=0; i < nodes.count; i++)
        {
            AlfrescoNode *remoteNode = nodes[i];
            //cellWrapper.syncStatus = SyncStatusSuccessful;
            
            // getting last modification date from repository item on server
            NSDate *lastModifiedDateForRemote = remoteNode.modifiedAt;
            
            // getting last modification date for repository item from local directory
            AlfrescoNode *localNode = [self localNodeForSyncName:nil orRemoteNode:remoteNode];
            NSDate *lastModifiedDateForLocal = localNode.modifiedAt;
            
            if (remoteNode.name != nil && ![remoteNode.name isEqualToString:@""])
            {
                if ([self isNodeModifiedSinceLastDownload:remoteNode])
                {
                    NSLog(@"File Modified: %@", localNode.name);
                    [nodesToUpload addObject:localNode];
                    //[cellWrapper setSyncStatus:SyncStatusWaiting];
                }
                else
                {
                    if (true) // check if download is not currently happening for this node
                    {
                        if (lastModifiedDateForLocal != nil && lastModifiedDateForRemote != nil)
                        {
                            // Check if document is updated on server
                            if ([lastModifiedDateForLocal compare:lastModifiedDateForRemote] == NSOrderedAscending)
                            {
                                //[cellWrapper setActivityType:SyncActivityTypeDownload];
                                [nodesToDownload addObject:remoteNode];
                                //[cellWrapper setSyncStatus:SyncStatusWaiting];
                            }
                        }
                        else
                        {
                            //[cellWrapper setActivityType:SyncActivityTypeDownload];
                            [nodesToDownload addObject:remoteNode];
                            //[cellWrapper setSyncStatus:SyncStatusWaiting];
                        }
                    }
                    else
                    {
                        //[cellWrapper setActivityType:SyncActivityTypeDownload];
                        //[cellWrapper setSyncStatus:SyncStatusLoading];
                    }
                }
            }
        }
        
        [self downloadContentsForNodes:nodesToDownload withCompletionBlock:nil];
        [self uploadContentsForNodes:nodesToUpload withCompletionBlock:nil];
        [self deleteUnWantedSyncedNodes:nodes];
        
        if ([self didEncounterObstaclesDuringSync])
        {
            NSDictionary *syncObstacles = @{@"syncObstacles" : [self syncObstacles]};
            [[NSNotificationCenter defaultCenter] postNotificationName:kNotificationSyncObstacles object:syncObstacles userInfo:nil];
        }
    }
    else
    {
        [self removeSyncContentAndInfo];
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node
{
    //AlfrescoNode *localNode = [self localInfoForNode:node];
    
    // getting last downloaded date for repository item from local directory
    NSDate *downloadedDate = [self lastDownloadedDateForNode:node];   // need to update to get exact date when file was downloaded
    
    // getting downloaded file locally updated Date
    NSError *dateError = nil;
    NSString *pathToSyncedFile = [[self syncContentDirectoryPath] stringByAppendingPathComponent:[self syncNameForNode:node]];
    NSDictionary *fileAttributes = [[NSFileManager defaultManager] attributesOfItemAtPath:pathToSyncedFile error:&dateError];
    NSDate *localModificationDate = [fileAttributes objectForKey:NSFileModificationDate];
    
    return ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
}

- (void)deleteUnWantedSyncedNodes:(NSArray *)nodes
{
    NSMutableArray *identifiersForNodesToBeSynced = [[nodes valueForKey:@"identifier"] valueForKey:@"lastPathComponent"];
    NSArray *localSyncedNodesIdentifiers = [self.syncedNodesInfo allKeys];
    
    NSMutableArray *nodesToBeRemovedFromSynced = [localSyncedNodesIdentifiers mutableCopy];
    
    for (NSString *identifierForLocalSyncNode in localSyncedNodesIdentifiers)
    {
        for (NSString *identifierForNodeToBeSynced in identifiersForNodesToBeSynced)
        {
            if ([identifierForLocalSyncNode hasPrefix:identifierForNodeToBeSynced])
            {
                [nodesToBeRemovedFromSynced removeObject:identifierForLocalSyncNode];
            }
        }
    }
    
    for (NSString *identifier in nodesToBeRemovedFromSynced)
    {
        BOOL encounteredObstacle = NO;
        AlfrescoNode *localNode = [self localNodeForSyncName:identifier orRemoteNode:nil];
        encounteredObstacle = [self checkForObstaclesInRemovingDownloadForNode:localNode];
        
        if (encounteredObstacle == NO)
        {
            [self deleteNodeFromSync:localNode];
        }
    }
    
    [self saveSyncInfo];
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
    NSString *syncNameForNode = [self syncNameForNode:node];
    BOOL isDeletedOnServer = [self isNodeInSyncList:node];
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node];
    
    BOOL encounteredObstacle = NO;
    // Note: Deliberate property getter bypass
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    NSMutableArray *syncObstacleUnFavorited = [self.syncObstacles objectForKey:kDocumentsUnfavoritedOnServerWithLocalChanges];
    
    if (isDeletedOnServer && isModifiedLocally)
    {
        if (![syncObstableDeleted containsObject:syncNameForNode])
        {
            [syncObstableDeleted addObject:syncNameForNode];
            encounteredObstacle = YES;
        }
    }
    else if (!isDeletedOnServer && isModifiedLocally)
    {
        if (![syncObstacleUnFavorited containsObject:syncNameForNode])
        {
            [syncObstacleUnFavorited addObject:syncNameForNode];
            encounteredObstacle = YES;
        }
    }
    
    return encounteredObstacle;
}

#pragma mark - Private Utilities

- (NSString *)syncNameForNode:(AlfrescoNode *)node
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
    
    return newName;
}

- (NSString *)breakString:(NSString *)fullString atString:(NSString *)string
{
    NSRange stringRange = [fullString rangeOfString:string];
    
    NSString *subString = @"";
    if (stringRange.location != NSNotFound)
    {
        subString = [fullString substringToIndex:stringRange.location];
    }
    return subString;
}

- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    NSLog(@"to download: %@", [nodes valueForKey:@"name"]);
    
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
                    [self saveSyncInfo];
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
    NSString *syncNameForNode = [self syncNameForNode:document];
    
    NSString *destinationPath = [self.syncContentDirectoryPath stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    
    [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            // Note: we're assuming that there will be no problem saving the metadata if the content saves successfully
            id nodeInfo = [self prepareNodeInfoForSync:document];
            [self.syncedNodesInfo setValue:nodeInfo forKey:syncNameForNode];
        }
        completionBlock(YES);
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        // TODO: Progress indicator update
    }];
}

- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    
    NSLog(@"files to upload number: %d", nodes.count);
    __block int totalUploads = nodes.count;
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                totalUploads--;
                
                if (totalUploads == 0)
                {
                    [self saveSyncInfo];
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
    NSString *syncNameForNode = [self syncNameForNode:document];
    NSString *nodeExtension = [document.name pathExtension];
    NSString *contentPath = [self.syncContentDirectoryPath stringByAppendingPathComponent:syncNameForNode];
    NSString *mimeType = @"application/octet-stream";
    
    if (nodeExtension != nil && ![nodeExtension isEqualToString:@""])
    {
        mimeType = [Utility mimeTypeForFileExtension:nodeExtension];
    }
    
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:contentPath]];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:contentPath];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    [self.documentFolderService updateContentOfDocument:document contentStream:contentStream completionBlock:^(AlfrescoDocument *document, NSError *error) {
        NSLog(@"file uploaded ");
        if (document)
        {
            NSMutableArray *documentsToBeDeleted = [self.syncObstacles objectForKey:kDocumentsToBeDeletedLocallyAfterUpload];
            if ([documentsToBeDeleted containsObject:syncNameForNode])
            {
                [documentsToBeDeleted removeObject:syncNameForNode];
                [self deleteNodeFromSync:document];
            }
            
            if ([self.syncedNodesInfo objectForKey:syncNameForNode] != nil)
            {
                id nodeInfo = [self prepareNodeInfoForSync:document];
                [self.syncedNodesInfo setValue:nodeInfo forKey:syncNameForNode];
            }
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(NO);
        }
        
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        
    }];
}

#pragma mark - SyncInfo Utilities

- (NSDictionary *)prepareNodeInfoForSync:(AlfrescoNode *)node
{
    NSData *archivedNode = [NSKeyedArchiver archivedDataWithRootObject:node];
    NSDictionary *nodeInfo = @{kSyncNodeKey: archivedNode, kLastDownloadedDateKey: [NSDate date]};
    return nodeInfo;
}

- (NSMutableDictionary *)syncedNodesInfo
{
    if (!_syncedNodesInfo)
    {
        NSString *syncInfoPath = [[self syncInfoDirectoryPath] stringByAppendingPathComponent:kSyncInfoFileName];
        
        if ([self.fileManager fileExistsAtPath:syncInfoPath isDirectory:NO])
        {
            NSError *error = nil;
            NSData *syncInfoData = [self.fileManager dataWithContentsOfURL:[NSURL fileURLWithPath:syncInfoPath]];
            _syncedNodesInfo = [NSPropertyListSerialization propertyListWithData:syncInfoData options:NSPropertyListMutableContainers format:NULL error:&error];
            
            if (!error)
            {
                AlfrescoLogDebug(@"Error reading plist from file '%@', error = '%@'", syncInfoPath, error.localizedDescription);
            }
        }
        else
        {
            _syncedNodesInfo = [NSMutableDictionary dictionary];
        }
    }
    return _syncedNodesInfo;
}

- (AlfrescoNode *)localNodeForSyncName:(NSString *)syncName orRemoteNode:(AlfrescoNode *)node
{
    NSString *localSyncName = node ? [self syncNameForNode:node] : syncName;
    AlfrescoNode *localNode = [NSKeyedUnarchiver unarchiveObjectWithData:[[self.syncedNodesInfo objectForKey:localSyncName] objectForKey:kSyncNodeKey]];
    
    return localNode;
}

- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node
{
    NSDate *downloadDate = [[self.syncedNodesInfo objectForKey:[self syncNameForNode:node]] objectForKey:kLastDownloadedDateKey];
    return downloadDate;
}

- (void)saveSyncInfo
{
    NSString *syncInfoPath = [self.syncInfoDirectoryPath stringByAppendingPathComponent:kSyncInfoFileName];
    
    if (self.syncedNodesInfo)
    {
        NSError *error = nil;
        NSData *syncInfoBinary = [NSPropertyListSerialization dataWithPropertyList:self.syncedNodesInfo format:NSPropertyListBinaryFormat_v1_0 options:0 error:&error];
        if (syncInfoBinary)
        {
            [syncInfoBinary writeToFile:syncInfoPath atomically:YES];
            //Complete protection in metadata since the file is always read one time and we write it when the application is active
        }
        else
        {
            AlfrescoLogDebug(@"Error writing sync Info to file '%@', error = '%@'", syncInfoPath, error.localizedDescription);
        }
    }
}

#pragma mark - Delete Methods

- (void)deleteNodeFromSync:(AlfrescoNode *)node
{
    NSString *nodeSyncName = [self syncNameForNode:node];
    NSString *syncNodeContentPath = [self.syncContentDirectoryPath stringByAppendingPathComponent:nodeSyncName];
    
    NSError *error = nil;
    [self.fileManager removeItemAtPath:syncNodeContentPath error:&error];
    
    if (!error)
    {
        [self.syncedNodesInfo removeObjectForKey:nodeSyncName];
    }
}

- (void)deleteNodesFromSync:(NSArray *)array
{
    for (AlfrescoNode *node in array)
    {
        [self deleteNodeFromSync:node];
    }
    [self saveSyncInfo];
}

- (void)removeSyncContentAndInfo
{
    NSError *error = nil;
    NSArray *documentPaths = [self.fileManager contentsOfDirectoryAtPath:self.syncContentDirectoryPath error:&error];
    
    for (NSString *path in documentPaths)
    {
        NSString *syncDocumentContentPath = [self.syncContentDirectoryPath stringByAppendingPathComponent:path];
        [self.fileManager removeItemAtPath:syncDocumentContentPath error:&error];
    }
    
    if (!error)
    {
        NSString *syncInfoPath = [self.syncInfoDirectoryPath stringByAppendingPathComponent:kSyncInfoFileName];
        [self.fileManager removeItemAtPath:syncInfoPath error:&error];
    }
}

#pragma mark - Public Utilities

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node
{
    __block BOOL isInSyncList = NO;
    [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *favorites, NSError *error) {
        
        if([[favorites valueForKey:@"identifier"] containsObject:node.identifier])
        {
            isInSyncList = YES;
        }
    }];
    
    return isInSyncList;
}

- (BOOL)isFirstUse
{
    BOOL didAskToSync = YES;   //  [[FDKeychainUserDefaults standardUserDefaults] boolForKey:kDidAskToSync]
    if (didAskToSync)
    {
        return NO;
    }
    return YES;
}

- (BOOL)isSyncEnabled
{
    BOOL syncPreferenceEnabled = true;   // kSyncPreference     [[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncPreference]
    BOOL syncOnCellularEnabled = true;    // [[FDKeychainUserDefaults standardUserDefaults] boolForKey:kSyncOnCellular]
    if (syncPreferenceEnabled)
    {
        Reachability *reach = [Reachability reachabilityForInternetConnection];
        NetworkStatus status = [reach currentReachabilityStatus];
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
