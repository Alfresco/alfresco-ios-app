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

#import "SyncOperationQueue.h"
#import "AccountSyncProgress.h"
#import "AlfrescoNode+Sync.h"
#import "SyncOperation.h"
#import "SyncNodeStatus.h"
#import "UserAccount.h"
#import "SyncConstants.h"
#import "RealmManager.h"
#import "AlfrescoNode+Networking.h"
#import "RealmSyncManager.h"
#import "AlfrescoNode+Utilities.h"

@interface SyncOperationQueue()

@property (nonatomic, strong) AccountSyncProgress *syncProgress;
@property (nonatomic, strong) NSOperationQueue *syncOperationQueue;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableDictionary *syncStatuses;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;
@property (atomic, assign) NSInteger syncOperationsStartedCount;

@end

@implementation SyncOperationQueue

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session syncProgressDelegate:(id<RealmSyncManagerProgressDelegate>)syncProgressDelegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.account = account;
    [self updateSession:session];
    self.fileManager = [AlfrescoFileManager sharedManager];
    self.progressDelegate = syncProgressDelegate;
    self.syncProgress = [[AccountSyncProgress alloc] initWithObserver:self];
    self.syncOperationQueue = [[NSOperationQueue alloc] init];
    self.syncOperationQueue.name = self.account.accountIdentifier;
    self.syncOperationQueue.maxConcurrentOperationCount = kSyncMaxConcurrentOperations;
    [self.syncOperationQueue addObserver:self forKeyPath:kSyncOperationCount options:0 context:NULL];
    self.syncOperations = [NSMutableDictionary new];
    self.syncStatuses = [NSMutableDictionary new];
    self.topLevelNodesInSyncProcessing = [NSMutableDictionary new];
    self.nodesInProcessingForDeletion = [NSMutableDictionary new];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
        RLMResults *allDocuments = [[RealmSyncCore sharedSyncCore] allDocumentsInRealm:realm];
        for(RealmSyncNodeInfo *document in allDocuments)
        {
            [self syncNodeStatusObjectForNodeWithId:document.syncNodeInfoId];
        }
    });
    
    return self;
}

#pragma mark - Download methods
- (void)addNodeToSync:(AlfrescoNode *)node isTopLevelNode:(BOOL)isTopLevel
{
    if(isTopLevel)
    {
        [self setNodeForSyncingAsTopLevel:node];
    }
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    [node saveNodeInRealm:realm isTopLevelNode:isTopLevel];
    
    [node retrieveNodePermissionsWithSession:self.session withCompletionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if(permissions)
        {
            SyncProgressType progressType = [self syncProgressTypeForNode:node];
            if(!((progressType == SyncProgressTypeUnsyncRequested) || (progressType == SyncProgressTypeInUnsyncProcessing)))
            {
                @try {
                    [[RealmManager sharedManager] savePermissions:permissions forNode:node];
                } @catch (NSException *exception) {
                    AlfrescoLogError(@"Exception thrown is %@", exception);
                };
            }
        }
    }];
}

- (void)addDocumentToSync:(AlfrescoDocument *)document isTopLevelNode:(BOOL)isTopLevel withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    RealmSyncCore *realmSync = [RealmSyncCore sharedSyncCore];
    NSString *syncID = [realmSync syncIdentifierForNode:(AlfrescoNode*)document];
    
    if ([self.syncOperations valueForKey:syncID])
    {
        [self addNodeToSync:document isTopLevelNode:isTopLevel];
    }
    else
    {
        [self addNodeToSync:document isTopLevelNode:isTopLevel];
        [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
            if(isTopLevel)
            {
                [self.topLevelNodesInSyncProcessing removeObjectForKey:[realmSync syncIdentifierForNode:document]];
            }
        }];
    }
    if (completionBlock)
    {
        completionBlock(YES);
    }
}

- (void)addFolderToSync:(AlfrescoFolder *)folder completionBlock:(void (^)(BOOL completed))completionBlock
{
    NSArray *folderChildren = self.syncNodesInfo[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:folder]];
    SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:folder]];
    if (folderChildren.count == 0)
    {
        nodeStatus.status = SyncStatusSuccessful;
    }
    self.syncOperationsStartedCount++;
    for(AlfrescoNode *subNode in folderChildren)
    {
        if(subNode.isFolder)
        {
            [self addFolderToSync:(AlfrescoFolder *)subNode completionBlock:completionBlock];
        }
        else
        {
            [self addDocumentToSync:(AlfrescoDocument *)subNode isTopLevelNode:NO withCompletionBlock:nil];
        }
    }
    
    self.syncOperationsStartedCount--;
    if(completionBlock)
    {
        completionBlock(YES);
    }
}

- (void)syncFolder:(AlfrescoFolder *)folder isTopLevelNode:(BOOL)isTopLevel
{
    [self addNodeToSync:folder isTopLevelNode:isTopLevel];
    
    __weak typeof(self) weakSelf = self;
    [self addFolderToSync:folder completionBlock:^(BOOL completed) {
        if(self.syncOperationsStartedCount == 0)
        {
            //all operations have been started
            if([weakSelf syncProgressTypeForNode:folder] == SyncProgressTypeUnsyncRequested)
            {
                weakSelf.nodesInProcessingForDeletion[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:folder]] = @YES;
                [weakSelf cancelSyncForFolder:folder completionBlock:^{
                    [[RealmSyncManager sharedManager] cleanRealmOfNode:folder];
                }];
            }
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
                
                if (self.syncOperationQueue.operationCount == 0)
                {
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
    NSString *syncNameForNode = [[RealmSyncCore sharedSyncCore] syncNameForNode:document inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
    __block SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]];
    nodeStatus.totalSize = [document contentLength];
    
    NSString *destinationPath = [[self syncContentDirectoryPathForAccountWithId:self.account.accountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    
    SyncOperation *downloadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           downloadDocument:document outputStream:outputStream
                                                                    downloadCompletionBlock:^(BOOL succeeded, NSError *error) {
                                                                        
                                                                        [outputStream close];
                                                                        RLMRealm *backgroundRealm = [[RealmManager sharedManager] realmForCurrentThread];
                                                                        [backgroundRealm refresh];
                                                                        RealmSyncNodeInfo *syncNodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                        
                                                                        SyncProgressType syncProgressType = [self syncProgressTypeForNode:document];
                                                                        if (succeeded)
                                                                        {
                                                                            nodeStatus.status = SyncStatusSuccessful;
                                                                            nodeStatus.activityType = SyncActivityTypeIdle;
                                                                            
                                                                            if(syncProgressType == SyncProgressTypeInProcessing)
                                                                            {
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
                                                                                syncNodeInfo.lastDownloadedDate = [NSDate date];
                                                                                syncNodeInfo.syncContentPath = syncNameForNode;
                                                                                syncNodeInfo.reloadContent = NO;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                                
                                                                                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDownloadedNotification object:document];
                                                                            }
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            
                                                                            if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                                                                            {
                                                                                // Remove file
                                                                                NSString *filePath = syncNodeInfo.syncContentPath;
                                                                                NSError *deleteError;
                                                                                [self.fileManager removeItemAtPath:filePath error:&deleteError];
                                                                                
                                                                                // Remove sync status
                                                                                [self removeSyncNodeStatusForNodeWithId:syncNodeInfo.syncNodeInfoId];
                                                                                
                                                                                // Remove RealmSyncError object if exists
                                                                                RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:syncNodeInfo.alfrescoNode ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                                
                                                                                // Remove RealmSyncNodeInfo object
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncNodeInfo inRealm:backgroundRealm];
                                                                            }
                                                                            else if(!((error.code == kAlfrescoErrorCodeNetworkRequestCancelled) && (syncProgressType == SyncProgressTypeUnsyncRequested || syncProgressType == SyncProgressTypeInUnsyncProcessing)))
                                                                            {
                                                                                SyncProgressType syncProgressType = [self syncProgressTypeForNode:document];
                                                                                if(syncProgressType == SyncProgressTypeInProcessing)
                                                                                {
                                                                                    RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:document ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                                    
                                                                                    [backgroundRealm beginWriteTransaction];
                                                                                    syncNodeInfo.reloadContent = YES;
                                                                                    syncError.errorCode = error.code;
                                                                                    syncError.errorDescription = [error localizedDescription];
                                                                                    syncNodeInfo.syncError = syncError;
                                                                                    [backgroundRealm commitWriteTransaction];
                                                                                }
                                                                            }
                                                                        }
                                                                        
                                                                        [self.syncOperations removeObjectForKey:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]];
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                            if (completionBlock != NULL)
                                                                            {
                                                                                completionBlock(YES);
                                                                            }
                                                                        });
                                                                        
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        self.syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    
    nodeStatus.status = SyncStatusLoading;
    nodeStatus.activityType = SyncActivityTypeDownload;
    nodeStatus.bytesTransfered = 0;
    nodeStatus.totalBytesToTransfer = 0;
    
    self.syncProgress.totalSyncSize += document.contentLength;
    [self notifyProgressDelegateAboutCurrentProgress];
    
    self.syncOperationQueue.suspended = YES;
    self.syncOperations[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]] = downloadOperation;
    [self.syncOperationQueue addOperation:downloadOperation];
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    self.syncOperationQueue.suspended = NO;
}

#pragma mark - Upload methods
- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload: %@", [nodes valueForKey:@"name"]);
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (self.syncOperationQueue.operationCount == 0)
                {
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
    NSString *syncNameForNode = [[RealmSyncCore sharedSyncCore] syncNameForNode:document inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
    NSString *nodeExtension = [document.name pathExtension];
    __block SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]];
    nodeStatus.status = SyncStatusLoading;
    nodeStatus.activityType = SyncActivityTypeUpload;
    nodeStatus.bytesTransfered = 0;
    nodeStatus.totalBytesToTransfer = 0;
    
    self.syncProgress.totalSyncSize += document.contentLength;
    [self notifyProgressDelegateAboutCurrentProgress];
    
    NSString *contentPath = [[self syncContentDirectoryPathForAccountWithId:self.account.accountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    
    NSString *mimeType = document.contentMimeType;
    if (!mimeType)
    {
        mimeType = @"application/octet-stream";
        
        if (nodeExtension.length > 0)
        {
            mimeType = [Utility mimeTypeForFileExtension:nodeExtension];
        }
    }
    
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:contentPath]];
    NSInputStream *readStream = [[AlfrescoFileManager sharedManager] inputStreamWithFilePath:contentPath];
    AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:readStream mimeType:mimeType length:contentFile.length];
    
    SyncOperation *uploadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           uploadDocument:document
                                                                              inputStream:contentStream
                                                                    uploadCompletionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
                                                                        
                                                                        [readStream close];
                                                                        RLMRealm *backgroundRealm = [[RealmManager sharedManager] realmForCurrentThread];
                                                                        RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:document ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                        if (uploadedDocument)
                                                                        {
                                                                            nodeStatus.status = SyncStatusSuccessful;
                                                                            nodeStatus.activityType = SyncActivityTypeIdle;
                                                                            
                                                                            [backgroundRealm beginWriteTransaction];
                                                                            nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                            nodeInfo.lastDownloadedDate = [NSDate date];
                                                                            nodeInfo.isRemovedFromSyncHasLocalChanges = NO;
                                                                            [backgroundRealm commitWriteTransaction];
                                                                            
                                                                            RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:document ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                            [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                        }
                                                                        else
                                                                        {
                                                                            nodeStatus.status = SyncStatusFailed;
                                                                            
                                                                            RealmSyncError *syncError = [[RealmSyncCore sharedSyncCore] errorObjectForNode:document ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                            
                                                                            [backgroundRealm beginWriteTransaction];
                                                                            syncError.errorCode = error.code;
                                                                            syncError.errorDescription = [error localizedDescription];
                                                                            nodeInfo.syncError = syncError;
                                                                            [backgroundRealm commitWriteTransaction];
                                                                        }
                                                                        
                                                                        [self.syncOperations removeObjectForKey:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]];
                                                                        dispatch_async(dispatch_get_main_queue(), ^{
                                                                            [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                            if (completionBlock != NULL)
                                                                            {
                                                                                completionBlock(YES);
                                                                            }
                                                                        });
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        self.syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    [self.syncOperationQueue setSuspended:YES];
    [self.syncOperationQueue addOperation:uploadOperation];
    self.syncOperations[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:document]] = uploadOperation;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    [self.syncOperationQueue setSuspended:NO];
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

#pragma mark - Cancel operations

- (void)cancelOperationsType:(CancelOperationsType)cancelType
{
    BOOL shouldCancelDownloadOperations = cancelType & CancelDownloadOperations;
    BOOL shouldCancelUploadOperations = cancelType & CancelUploadOperations;

    NSArray *syncDocumentIdentifiers = [self.syncOperations allKeys];
    
    for (NSString *documentIdentifier in syncDocumentIdentifiers)
    {
        SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:documentIdentifier];
        if((nodeStatus.activityType == SyncActivityTypeDownload) && shouldCancelDownloadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier completionBlock:nil];
        }
        else if ((nodeStatus.activityType == SyncActivityTypeUpload) && shouldCancelUploadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier completionBlock:nil];
        }
    }
    
    if(shouldCancelUploadOperations && shouldCancelDownloadOperations)
    {
        self.syncProgress.totalSyncSize = 0;
        self.syncProgress.syncProgressSize = 0;
        [self notifyProgressDelegateAboutCurrentProgress];
    }
}

- (void)cancelSyncForNode:(AlfrescoNode *)node completionBlock:(void (^)(void))completionBlock
{
    if(node)
    {
        if(node.isDocument)
        {
            [self cancelSyncForDocumentWithIdentifier:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node] completionBlock:completionBlock];
        }
        else
        {
            [self cancelSyncForFolder:(AlfrescoFolder *)node completionBlock:completionBlock];
        }
    }
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier completionBlock:(void (^)(void))completionBlock
{
    NSString *syncDocumentIdentifier = [AlfrescoNode nodeRefWithoutVersionIDFromIdentifier:documentIdentifier];
    SyncOperation *syncOperation = self.syncOperations[syncDocumentIdentifier];
    
    [self cancelOperation:syncOperation forNodeSyncIdentifier:syncDocumentIdentifier];
    
    if(completionBlock)
    {
        completionBlock();
    }
}

- (void)cancelSyncForFolder:(AlfrescoFolder *)folder completionBlock:(void (^)(void))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSArray *folderChildren = self.syncNodesInfo[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:folder]];
        if(folderChildren.count == 0)
        {
            RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
            folderChildren = [[RealmSyncCore sharedSyncCore] allNodesWithType:NodesTypeDocuments inFolder:folder recursive:YES includeTopLevelNodes:NO inRealm:realm];
        }
        for(AlfrescoNode *subNode in folderChildren)
        {
            SyncOperation *syncOperation = self.syncOperations[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:subNode]];
            [self cancelOperation:syncOperation forNodeSyncIdentifier:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:subNode]];
        }
        if(completionBlock)
        {
            completionBlock();
        }
    });
}

- (void)cancelOperation:(SyncOperation *)syncOp forNodeSyncIdentifier:(NSString *)nodeSyncIdentifier
{
    if (syncOp)
    {
        [syncOp cancelOperation];
        [self.syncOperations removeObjectForKey:nodeSyncIdentifier];
        SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:nodeSyncIdentifier];
        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
        
        if (self.syncProgress.totalSyncSize >= nodeStatus.totalSize)
        {
            self.syncProgress.totalSyncSize -= nodeStatus.totalSize;
        }
        else
        {
            self.syncProgress.totalSyncSize = 0;
        }
        
        if (self.syncProgress.syncProgressSize >= nodeStatus.bytesTransfered)
        {
            self.syncProgress.syncProgressSize -= nodeStatus.bytesTransfered;
        }
        else
        {
            self.syncProgress.syncProgressSize = 0;
        }
        
         nodeStatus.status = SyncStatusFailed;
    }
}

#pragma mark - Sync progress delegate
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncProgressSizeKey])
    {
        [self notifyProgressDelegateAboutCurrentProgress];
    }
    else if([keyPath isEqualToString:kSyncOperationCount])
    {
        if(self.syncOperationQueue == object)
        {
            if(self.syncOperationQueue.operationCount == 0)
            {
                self.syncProgress.totalSyncSize = 0;
                self.syncProgress.syncProgressSize = 0;
                [self notifyProgressDelegateAboutCurrentProgress];
            }
        }
    }
}

- (void)notifyProgressDelegateAboutNumberOfNodesInProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(numberOfSyncOperationsInProgress:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressDelegate numberOfSyncOperationsInProgress:self.syncOperations.count];
        });
    }
}

- (void)notifyProgressDelegateAboutCurrentProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(totalSizeToSync:syncedSize:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressDelegate totalSizeToSync:self.syncProgress.totalSyncSize syncedSize:self.syncProgress.syncProgressSize];
        });
    }
}

#pragma mark - Public methods
- (void)updateSession:(id<AlfrescoSession>)session
{
    self.session = session;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
}

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId
{
    SyncNodeStatus *nodeStatus = [self.syncStatuses objectForKey:nodeId];
    
    if (!nodeStatus && nodeId)
    {
        nodeStatus = [[SyncNodeStatus alloc] initWithNodeId:nodeId];
        [self.syncStatuses setObject:nodeStatus forKey:nodeId];
        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
        RealmSyncNodeInfo *syncNodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForId:nodeId inRealm:realm];
        if(syncNodeInfo)
        {
            if(!syncNodeInfo.isFolder)
            {
                if(syncNodeInfo.syncError)
                {
                    nodeStatus.status = SyncStatusFailed;
                }
                else if(!syncNodeInfo.lastDownloadedDate)
                {
                    nodeStatus.status = SyncStatusWaiting;
                }
            }
            
            nodeStatus.activityType = [syncNodeInfo.alfrescoNode determineSyncActivityTypeInRealm:realm];
        }
    }
    
    return nodeStatus;
}

- (void)removeSyncNodeStatusForNodeWithId:(NSString *)nodeId
{
    SyncNodeStatus *nodeStatus = [self.syncStatuses objectForKey:nodeId];
    nodeStatus.status = SyncStatusRemoved;
    nodeStatus.totalSize = 0;
}

- (void)resetSyncNodeStatusInformation
{
    self.syncStatuses = [NSMutableDictionary new];
}

- (BOOL)isCurrentlySyncing
{
    return self.syncOperationQueue.operationCount > 0;
}

- (void)pauseSyncing:(BOOL)shouldPause
{
    [self.syncOperationQueue setSuspended:shouldPause];
}

- (BOOL)isCurrentlySyncingNode:(AlfrescoNode *)node
{
    BOOL returnSyncStatus = NO;
    if(self.syncOperations[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]])
    {
        returnSyncStatus = YES;
    }
    else
    {
        NSNumber *isSyncing = self.topLevelNodesInSyncProcessing[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
        if(isSyncing)
        {
            returnSyncStatus = YES;
        }
        else
        {
            RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
            NSArray *childrenDocumentsOfFolder = [[RealmSyncCore sharedSyncCore] allNodesWithType:NodesTypeDocuments inFolder:(AlfrescoFolder *)node recursive:YES includeTopLevelNodes:NO inRealm:realm];
            for(AlfrescoNode *child in childrenDocumentsOfFolder)
            {
                if(self.syncOperations[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:child]])
                {
                    returnSyncStatus = YES;
                    break;
                }
            }
        }
    }
    return returnSyncStatus;
}

- (void)resetSyncProgressInformationForNode:(AlfrescoNode *)node
{
    [self.topLevelNodesInSyncProcessing removeObjectForKey:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
    [self.nodesInProcessingForDeletion removeObjectForKey:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
}

- (void)setNodeForRemoval:(AlfrescoNode *)node
{
    self.topLevelNodesInSyncProcessing[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]] = @NO;
}

- (void)setNodeForSyncingAsTopLevel:(AlfrescoNode *)node
{
    if(!self.topLevelNodesInSyncProcessing[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]])
    {
        self.topLevelNodesInSyncProcessing[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]] = @YES;
        SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
        nodeStatus.status = SyncStatusLoading;
    }
}

- (BOOL)shouldContinueSyncProcessForNode:(AlfrescoNode *)node
{
    BOOL shouldContinueSync = NO;
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RealmSyncNodeInfo *topLevelParentNode = [node topLevelSyncParentNodeInRealm:realm];
    if(topLevelParentNode)
    {
        NSNumber *isSyncing = self.topLevelNodesInSyncProcessing[topLevelParentNode.syncNodeInfoId];
        if(isSyncing)
        {
            if(isSyncing.boolValue)
            {
                shouldContinueSync = YES;
            }
        }
        else
        {
            shouldContinueSync = YES;
        }
    }
    
    return shouldContinueSync;
}

- (SyncProgressType)syncProgressTypeForNode:(AlfrescoNode *)node
{
    SyncProgressType progressType = SyncProgressTypeNotInProcessing;
    
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RealmSyncNodeInfo *topLevelParentNode = [node topLevelSyncParentNodeInRealm:realm];
    if(topLevelParentNode)
    {
        NSNumber *isSyncing = self.topLevelNodesInSyncProcessing[topLevelParentNode.syncNodeInfoId];
        if(isSyncing)
        {
            if(isSyncing.boolValue)
            {
                progressType = SyncProgressTypeInProcessing;
            }
            else
            {
                NSNumber *isDeleting = self.nodesInProcessingForDeletion[topLevelParentNode.syncNodeInfoId];
                progressType = isDeleting? SyncProgressTypeInUnsyncProcessing : SyncProgressTypeUnsyncRequested;
            }
        }
    }
    
    return progressType;
}

#pragma mark - Private methods
- (BOOL)didStartProcessingDeleteForNode:(AlfrescoNode *)node
{
    BOOL didStartProcessing = NO;
    RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
    RealmSyncNodeInfo *topLevelParentNode = [node topLevelSyncParentNodeInRealm:realm];
    if(topLevelParentNode)
    {
        NSNumber *isProcessing = self.nodesInProcessingForDeletion[topLevelParentNode.syncNodeInfoId];
        if(isProcessing)
        {
            didStartProcessing = YES;
        }
    }
    
    return didStartProcessing;
}

- (void)setProgressDelegate:(id<RealmSyncManagerProgressDelegate>)progressDelegate
{
    _progressDelegate = progressDelegate;
    if(_progressDelegate)
    {
        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
        [self notifyProgressDelegateAboutCurrentProgress];
    }
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    [self updateSession:notification.object];
}

@end
