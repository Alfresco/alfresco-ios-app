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

#import "SyncOperationQueueManager.h"
#import "AccountSyncProgress.h"
#import "AlfrescoNode+Sync.h"
#import "SyncOperation.h"
#import "SyncNodeStatus.h"
#import "UserAccount.h"
#import "SyncConstants.h"
#import "RealmManager.h"

@interface SyncOperationQueueManager()

@property (nonatomic, strong) AccountSyncProgress *syncProgress;
@property (nonatomic, strong) NSOperationQueue *syncOperationQueue;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableDictionary *syncStatuses;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;

@end

@implementation SyncOperationQueueManager

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
    [self.syncOperationQueue addObserver:self forKeyPath:@"operations" options:0 context:NULL];
    
    return self;
}

#pragma mark - Download methods
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
    NSString *syncNameForNode = [document syncNameInRealm:[RLMRealm defaultRealm]];
    __block SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[document syncIdentifier]];
    nodeStatus.status = SyncStatusLoading;
    
    self.syncProgress.totalSyncSize += document.contentLength;
    [self notifyProgressDelegateAboutCurrentProgress];
    
    NSString *destinationPath = [[self syncContentDirectoryPathForAccountWithId:self.account.accountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    
    SyncOperation *downloadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           downloadDocument:document outputStream:outputStream
                                                                    downloadCompletionBlock:^(BOOL succeeded, NSError *error) {
                                                                        
                                                                        [outputStream close];
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
                                                                            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[document syncIdentifier] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                            
                                                                            if (succeeded)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
                                                                                syncNodeInfo.lastDownloadedDate = [NSDate date];
                                                                                syncNodeInfo.syncContentPath = syncNameForNode;
                                                                                syncNodeInfo.reloadContent = NO;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[document syncIdentifier] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
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
                                                                                    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:syncNodeInfo.syncNodeInfoId ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                    [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                                    
                                                                                    // Remove RealmSyncNodeInfo object
                                                                                    [[RealmManager sharedManager] deleteRealmObject:syncNodeInfo inRealm:backgroundRealm];
                                                                                }
                                                                                else
                                                                                {
                                                                                    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[document syncIdentifier] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                                    
                                                                                    [backgroundRealm beginWriteTransaction];
                                                                                    syncNodeInfo.reloadContent = YES;
                                                                                    syncError.errorCode = error.code;
                                                                                    syncError.errorDescription = [error localizedDescription];
                                                                                    syncNodeInfo.syncError = syncError;
                                                                                    [backgroundRealm commitWriteTransaction];
                                                                                }
                                                                            }

                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                                completionBlock(YES);
                                                                            });
                                                                        });
                                                                        
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        self.syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    self.syncOperationQueue.suspended = YES;
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
    NSString *syncNameForNode = [document syncNameInRealm:[RLMRealm defaultRealm]];
    NSString *nodeExtension = [document.name pathExtension];
    __block SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:[document syncIdentifier]];
    nodeStatus.status = SyncStatusLoading;
    
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
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
                                                                            RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[document syncIdentifier] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                            if (uploadedDocument)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                                nodeInfo.lastDownloadedDate = [NSDate date];
                                                                                nodeInfo.isRemovedFromSyncHasLocalChanges = NO;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[document syncIdentifier] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                            }
                                                                            else
                                                                            {
                                                                                nodeStatus.status = SyncStatusFailed;
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[document syncIdentifier] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                syncError.errorCode = error.code;
                                                                                syncError.errorDescription = [error localizedDescription];
                                                                                nodeInfo.syncError = syncError;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                            }
                                                                            
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                                if (completionBlock != NULL)
                                                                                {
                                                                                    completionBlock(YES);
                                                                                }
                                                                            });
                                                                        });
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        self.syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    [self.syncOperationQueue setSuspended:YES];
    [self.syncOperationQueue addOperation:uploadOperation];
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
- (void)cancelDownloadOperations:(BOOL)shouldCancelDownloadOperations uploadOperations:(BOOL)shouldCancelUploadOperations
{
    for (SyncOperation *syncOperation in self.syncOperationQueue.operations)
    {
        NSString *documentIdentifier = [syncOperation.document syncIdentifier];
        SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:documentIdentifier];
        if((nodeStatus.activityType == SyncActivityTypeDownload) && shouldCancelDownloadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier];
            
        }
        else if ((nodeStatus.activityType == SyncActivityTypeUpload) && shouldCancelUploadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier];
        }
    }
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [self.syncOperationQueue setSuspended:YES];
        NSString *syncDocumentIdentifier = [Utility nodeRefWithoutVersionID:documentIdentifier];
        SyncNodeStatus *nodeStatus = [self syncNodeStatusObjectForNodeWithId:syncDocumentIdentifier];
        
        RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
        
        SyncOperation *syncOperation = self.syncOperations[syncDocumentIdentifier];
        
        if (syncOperation)
        {
            [syncOperation cancelOperation];
            [self.syncOperations removeObjectForKey:syncDocumentIdentifier];
            nodeStatus.status = SyncStatusFailed;
            
            RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:syncDocumentIdentifier ifNotExistsCreateNew:NO inRealm:backgroundRealm];
            RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:syncDocumentIdentifier ifNotExistsCreateNew:YES inRealm:backgroundRealm];
            [backgroundRealm beginWriteTransaction];
            syncError.errorCode = kSyncOperationCancelledErrorCode;
            nodeInfo.syncError = syncError;
            [backgroundRealm commitWriteTransaction];
            
            [self notifyProgressDelegateAboutNumberOfNodesInProgress];
            self.syncProgress.totalSyncSize -= nodeStatus.totalSize;
            self.syncProgress.syncProgressSize -= nodeStatus.bytesTransfered;
            nodeStatus.bytesTransfered = 0;
        }
    });
}

#pragma mark - Sync progress delegate
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncProgressSizeKey])
    {
        [self notifyProgressDelegateAboutCurrentProgress];
    }
    else if([keyPath isEqualToString:@"operations"])
    {
        if(self.syncOperationQueue == object)
        {
            if(self.syncOperationQueue.operationCount == 0)
            {
                self.syncProgress.totalSyncSize = 0;
                self.syncProgress.syncProgressSize = 0;
            }
        }
    }
}

- (void)notifyProgressDelegateAboutNumberOfNodesInProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(numberOfSyncOperationsInProgress:)])
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.progressDelegate numberOfSyncOperationsInProgress:self.syncOperationQueue.operationCount];
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
        [self.syncStatuses setValue:nodeStatus forKey:nodeId];
    }
    
    return nodeStatus;
}

- (void)removeSyncNodeStatusForNodeWithId:(NSString *)nodeId
{
    [self.syncStatuses removeObjectForKey:nodeId];
}

- (BOOL)isCurrentlySyncing
{
    return self.syncOperationQueue.operationCount > 0;
}

@end
