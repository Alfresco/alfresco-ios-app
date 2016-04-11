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

#import "RealmSyncManager.h"

#import "UserAccount.h"
#import "AccountManager.h"
#import "AccountSyncProgress.h"
#import "SyncNodeStatus.h"
#import "SyncOperation.h"
#import "AlfrescoFileManager+Extensions.h"
#import "RealmSyncHelper.h"
#import "RealmManager.h"
#import "ConnectivityManager.h"


@interface RealmSyncManager()

@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) NSMutableDictionary *syncQueues;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;
@property (nonatomic, strong) NSMutableDictionary *accountsSyncProgress;
@property (nonatomic, strong) NSMutableDictionary *syncNodesInfo;
@property (nonatomic, strong) NSMutableDictionary *syncNodesStatus;
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (nonatomic, strong) RealmSyncHelper *syncHelper;
@property (nonatomic, strong) RealmManager *realmManager;

@end

@implementation RealmSyncManager

#pragma mark - Singleton
+ (RealmSyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (instancetype)init
{
    self = [super init];
    if(self)
    {
        _fileManager = [AlfrescoFileManager sharedManager];
        
        // syncNodesInfo will hold mutable dictionaries for each account
        _syncNodesInfo = [NSMutableDictionary dictionary];
        
        _syncQueues = [NSMutableDictionary dictionary];
        _syncOperations = [NSMutableDictionary dictionary];
        _accountsSyncProgress = [NSMutableDictionary dictionary];
        
        _syncObstacles = @{kDocumentsRemovedFromSyncOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsDeletedOnServerWithLocalChanges: [NSMutableArray array],
                           kDocumentsToBeDeletedLocallyAfterUpload: [NSMutableArray array]};
        
        _syncHelper = [RealmSyncHelper sharedHelper];
        _realmManager = [RealmManager sharedManager];
    }
    
    return self;
}

#pragma mark - Public methods
- (RLMRealm *)createRealmForAccount:(UserAccount *)account
{
    return [self.realmManager createRealmWithName:account.accountIdentifier];
}

- (void)deleteRealmForAccount:(UserAccount *)account
{
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [self resetDefaultRealmConfiguration];
    }
    
    [self.realmManager deleteRealmWithName:account.accountIdentifier];
}

- (void)disableSyncForAccount:(UserAccount*)account fromViewController:(UIViewController *)presentingViewController cancelBlock:(void (^)(void))cancelBlock completionBlock:(void (^)(void))completionBlock
{
    if([self isCurrentlySyncing])
    {
        UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.pendingoperations.title", @"Pending sync operations") message:NSLocalizedString(@"action.pendingoperations.message", @"Stop pending operations") preferredStyle:UIAlertControllerStyleAlert];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            cancelBlock();
        }]];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.confirm", @"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cancelAllSyncOperations];
            [self deleteRealmForAccount:account];
            completionBlock();
        }]];
        
        [presentingViewController presentViewController:confirmAlert animated:YES completion:nil];
    }
    else
    {
        [self deleteRealmForAccount:account];
        completionBlock();
    }
}

#pragma mark - Delete node
- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
        SyncNodeStatus *syncNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
        syncNodeStatus.totalSize = 0;
        [self.syncHelper deleteNodeFromSync:node inRealm:backgroundRealm];
        completionBlock(NO);
    });
}

#pragma mark - Sync Operations - Download
- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to download: %@", [nodes valueForKey:@"name"]);
    
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[[[AccountManager sharedManager] selectedAccount].accountIdentifier];
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self downloadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (syncOperationsForSelectedAccount.count == 0)
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
    NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
    
    NSString *syncNameForNode = [self.syncHelper syncNameForNode:document inRealm:[RLMRealm defaultRealm]];
    __block SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] inSyncNodesStatus:self.syncNodesStatus];
    nodeStatus.status = SyncStatusLoading;
    
    NSString *destinationPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:destinationPath append:NO];
    
    NSOperationQueue *syncQueueForSelectedAccount = self.syncQueues[selectedAccountIdentifier];
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[selectedAccountIdentifier];
    
    SyncOperation *downloadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           downloadDocument:document outputStream:outputStream
                                                                    downloadCompletionBlock:^(BOOL succeeded, NSError *error) {
                                                                        
                                                                        [outputStream close];
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
                                                                            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] inRealm:backgroundRealm];
                                                                            
                                                                            if (succeeded)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
                                                                                syncNodeInfo.lastDownloadedDate = [NSDate date];
                                                                                syncNodeInfo.syncContentPath = destinationPath;
                                                                                syncNodeInfo.reloadContent = [NSNumber numberWithBool:NO];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                            }
                                                                            else
                                                                            {
                                                                                nodeStatus.status = SyncStatusFailed;
                                                                                syncNodeInfo.reloadContent = [NSNumber numberWithBool:YES];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                                
                                                                                syncError.errorCode = error.code;
                                                                                syncError.errorDescription = [error localizedDescription];
                                                                                
                                                                                syncNodeInfo.syncError = syncError;
                                                                            }
                                                                            
                                                                            [syncOperationsForSelectedAccount removeObjectForKey:[self.syncHelper syncIdentifierForNode:document]];
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                                completionBlock(YES);
                                                                            });
                                                                        });
                                                                        
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        AccountSyncProgress *syncProgress = self.accountsSyncProgress[selectedAccountIdentifier];
                                                                        syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    syncOperationsForSelectedAccount[[self.syncHelper syncIdentifierForNode:document]] = downloadOperation;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    
    syncQueueForSelectedAccount.suspended = YES;
    [syncQueueForSelectedAccount addOperation:downloadOperation];
    syncQueueForSelectedAccount.suspended = NO;
}

#pragma mark - Sync Operations - Upload
- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AlfrescoLogDebug(@"Files to upload: %@", [nodes valueForKey:@"name"]);
    NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[selectedAccountIdentifier];
    
    for (AlfrescoNode *node in nodes)
    {
        if (node.isDocument)
        {
            [self uploadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                
                if (syncOperationsForSelectedAccount.count == 0)
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
    NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
    
    NSString *syncNameForNode = [self.syncHelper syncNameForNode:document inRealm:[RLMRealm defaultRealm]];
    NSString *nodeExtension = [document.name pathExtension];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] inSyncNodesStatus:self.syncNodesStatus];
    nodeStatus.status = SyncStatusLoading;
    NSString *contentPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    
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
    
    NSOperationQueue *syncQueueForSelectedAccount = self.syncQueues[selectedAccountIdentifier];
    NSMutableDictionary *syncOperationsForSelectedAccount = self.syncOperations[selectedAccountIdentifier];
    
    SyncOperation *uploadOperation = [[SyncOperation alloc] initWithDocumentFolderService:self.documentFolderService
                                                                           uploadDocument:document
                                                                              inputStream:contentStream
                                                                    uploadCompletionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
                                                                        
                                                                        [readStream close];
                                                                        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                                                                            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
                                                                            RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] inRealm:backgroundRealm];
                                                                            if (uploadedDocument)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                                nodeInfo.lastDownloadedDate = [NSDate date];
                                                                                nodeInfo.isRemovedFromSyncHasLocalChanges = [NSNumber numberWithBool:NO];
                                                                                [backgroundRealm commitWriteTransaction];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                            }
                                                                            else
                                                                            {
                                                                                nodeStatus.status = SyncStatusFailed;
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                syncError.errorCode = error.code;
                                                                                syncError.errorDescription = [error localizedDescription];
                                                                                
                                                                                nodeInfo.syncError = syncError;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                            }

                                                                            [syncOperationsForSelectedAccount removeObjectForKey:[self.syncHelper syncIdentifierForNode:document]];
                                                                            dispatch_async(dispatch_get_main_queue(), ^{
                                                                                [self notifyProgressDelegateAboutNumberOfNodesInProgress];
                                                                                if (completionBlock != NULL)
                                                                                {
                                                                                    completionBlock(YES);
                                                                                }
                                                                            });
                                                                        });
                                                                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                                                                        AccountSyncProgress *syncProgress = self.accountsSyncProgress[selectedAccountIdentifier];
                                                                        syncProgress.syncProgressSize += (bytesTransferred - nodeStatus.bytesTransfered);
                                                                        nodeStatus.bytesTransfered = bytesTransferred;
                                                                        nodeStatus.totalBytesToTransfer = bytesTotal;
                                                                    }];
    syncOperationsForSelectedAccount[[self.syncHelper syncIdentifierForNode:document]] = uploadOperation;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
    [syncQueueForSelectedAccount addOperation:uploadOperation];
}

#pragma mark - Sync Utilities
- (void)cancelAllSyncOperations
{
    NSArray *syncOperationKeys = [self.syncOperations allKeys];
    
    for (NSString *accountId in syncOperationKeys)
    {
        [self cancelAllSyncOperationsForAccountWithId:accountId];
    }
}

- (void)cancelAllSyncOperationsForAccountWithId:(NSString *)accountId
{
    NSArray *syncDocumentIdentifiers = [self.syncOperations[accountId] allKeys];
    
    for (NSString *documentIdentifier in syncDocumentIdentifiers)
    {
        [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:accountId];
    }
    
    AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
    syncProgress.totalSyncSize = 0;
    syncProgress.syncProgressSize = 0;
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier inAccountWithId:(NSString *)accountId
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *syncDocumentIdentifier = [Utility nodeRefWithoutVersionID:documentIdentifier];
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:syncDocumentIdentifier];
        
        RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
        
        NSMutableDictionary *syncOperationForAccount = self.syncOperations[accountId];
        SyncOperation *syncOperation = [syncOperationForAccount objectForKey:syncDocumentIdentifier];
        [syncOperation cancelOperation];
        [syncOperationForAccount removeObjectForKey:syncDocumentIdentifier];
        nodeStatus.status = SyncStatusFailed;
        
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:syncDocumentIdentifier inRealm:backgroundRealm];
        RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:syncDocumentIdentifier ifNotExistsCreateNew:YES inRealm:backgroundRealm];
        [backgroundRealm beginWriteTransaction];
        syncError.errorCode = kSyncOperationCancelledErrorCode;
        nodeInfo.syncError = syncError;
        [backgroundRealm commitWriteTransaction];
        
        [self notifyProgressDelegateAboutNumberOfNodesInProgress];
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
        syncProgress.totalSyncSize -= nodeStatus.totalSize;
        syncProgress.syncProgressSize -= nodeStatus.bytesTransfered;
        nodeStatus.bytesTransfered = 0;
    });
}

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:syncNodeId inSyncNodesStatus:self.syncNodesStatus];
    return nodeStatus;
}

- (BOOL)isCurrentlySyncing
{
    __block BOOL isSyncing = NO;
    
    [self.syncQueues enumerateKeysAndObjectsUsingBlock:^(id key, NSOperationQueue *queue, BOOL *stop) {
        
        isSyncing = queue.operationCount > 0;
        
        if (isSyncing)
        {
            *stop = YES;
        }
    }];
    
    return YES;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    RealmSyncNodeInfo *nodeInfo = [self.realmManager syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] inRealm:[RLMRealm defaultRealm]];
    
    //since this path was stored as a full path and not relative to the Documents folder, the following is necessary to get to the correct path for the node
    NSString *newNodePath = nil;
    if(nodeInfo)
    {
        NSString *storedPath = nodeInfo.syncContentPath;
        NSString *relativePath = [self getRelativeSyncPath:storedPath];
        NSString *syncDirectory = [[AlfrescoFileManager sharedManager] syncFolderPath];
        newNodePath = [syncDirectory stringByAppendingPathComponent:relativePath];
    }
    
    return newNodePath;
}

// this parses a path to get the relative path to the Sync folder
- (NSString *) getRelativeSyncPath:(NSString *)oldPath
{
    NSString *newPath = nil;
    NSArray *array = [oldPath componentsSeparatedByString:[NSString stringWithFormat:@"%@/",kSyncFolder]];
    if(array.count >= 2)
    {
        newPath = array[1];
    }
    
    return newPath;
}

- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock
{
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:node inRealm:realm];
    
    NSMutableArray *syncObstableDeleted = [self.syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    if (isModifiedLocally)
    {
        // check if node is not deleted on server
        [self.documentFolderService retrieveNodeWithIdentifier:[self.syncHelper syncIdentifierForNode:node] completionBlock:^(AlfrescoNode *alfrescoNode, NSError *error) {
            if (error)
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

- (void)retrySyncForDocument:(AlfrescoDocument *)document completionBlock:(void (^)(void))completionBlock
{
    SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:[self.syncHelper syncIdentifierForNode:document]];
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[selectedAccountIdentifier];
        syncProgress.totalSyncSize += document.contentLength;
        [self notifyProgressDelegateAboutCurrentProgress];
        
        if (nodeStatus.activityType == SyncActivityTypeDownload)
        {
            [self downloadDocument:document withCompletionBlock:^(BOOL completed) {
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
        else
        {
            [self uploadDocument:document withCompletionBlock:^(BOOL completed) {
                if (completionBlock)
                {
                    completionBlock();
                }
            }];
        }
    }
    else
    {
        if (nodeStatus.activityType != SyncActivityTypeDownload)
        {
            nodeStatus.status = SyncStatusWaiting;
            nodeStatus.activityType = SyncActivityTypeUpload;
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }
}

- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    NSDate *downloadedDate = nil;
    NSDate *localModificationDate = nil;
    if (node.isDocument)
    {
        // getting last downloaded date for node from local info
        downloadedDate = [self.syncHelper lastDownloadedDateForNode:node inRealm:realm];
        
        // getting downloaded file locally updated Date
        NSError *dateError = nil;
        
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] inRealm:realm];
        NSString *pathToSyncedFile = nodeInfo.syncContentPath;
        NSDictionary *fileAttributes = [self.fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        localModificationDate = [fileAttributes objectForKey:kAlfrescoFileLastModification];
    }
    BOOL isModifiedLocally = ([downloadedDate compare:localModificationDate] == NSOrderedAscending);
    
    if (isModifiedLocally)
    {
        SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
        
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

#pragma mark - Realm Utilities
- (void)changeDefaultConfigurationForAccount:(UserAccount *)account
{
    [RLMRealmConfiguration setDefaultConfiguration:[self.realmManager configForName:account.accountIdentifier]];
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    [RLMRealmConfiguration setDefaultConfiguration:config];
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
        NSMutableDictionary *syncOperations = self.syncOperations[[[AccountManager sharedManager] selectedAccount].accountIdentifier];
        [self.progressDelegate numberOfSyncOperationsInProgress:syncOperations.count];
    }
}

- (void)notifyProgressDelegateAboutCurrentProgress
{
    if ([self.progressDelegate respondsToSelector:@selector(totalSizeToSync:syncedSize:)])
    {
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[[[AccountManager sharedManager] selectedAccount].accountIdentifier];
        [self.progressDelegate totalSizeToSync:syncProgress.totalSyncSize syncedSize:syncProgress.syncProgressSize];
    }
}

@end
