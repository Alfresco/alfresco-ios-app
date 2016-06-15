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
#import "SyncOperation.h"
#import "AlfrescoFileManager+Extensions.h"
#import "RealmSyncHelper.h"
#import "ConnectivityManager.h"
#import "AppConfigurationManager.h"
#import "DownloadManager.h"
#import "PreferenceManager.h"

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
@property (nonatomic, strong) NSMutableDictionary *permissions;
@property (nonatomic, strong) NSString *selectedAccountSyncIdentifier;

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
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(selectedProfileDidChange:) name:kAlfrescoConfigProfileDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(mainMenuConfigurationChanged:) name:kAlfrescoConfigFileDidUpdateNotification object:nil];
    }
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (RLMRealm *)mainThreadRealm
{
    _mainThreadRealm = [self realmForAccount:[AccountManager sharedManager].selectedAccount.accountIdentifier];
    
    return _mainThreadRealm;
}

#pragma mark - Sync Feature
- (RLMRealm *)realmForAccount:(NSString *)accountId
{
    return [self.realmManager createRealmWithName:accountId];
}

- (void)deleteRealmForAccount:(UserAccount *)account
{
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [self resetDefaultRealmConfiguration];
    }
    
    [self.realmManager deleteRealmWithName:account.accountIdentifier];
}

- (void)determineSyncFeatureStatus:(UserAccount *)changedAccount selectedProfile:(AlfrescoProfileConfig *)selectedProfile
{
    [[AppConfigurationManager sharedManager] isViewOfType:kAlfrescoConfigViewTypeSync presentInProfile:selectedProfile forAccount:changedAccount completionBlock:^(BOOL isViewPresent, NSError *error) {
        if(!error && (isViewPresent != changedAccount.isSyncOn))
        {
            if(isViewPresent)
            {
                [self realmForAccount:changedAccount.accountIdentifier];
                changedAccount.isSyncOn = YES;
                [[AccountManager sharedManager] saveAccountsToKeychain];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:changedAccount];
                if([changedAccount.accountIdentifier isEqualToString:[AccountManager sharedManager].selectedAccount.accountIdentifier])
                {
                    [self changeDefaultConfigurationForAccount:changedAccount];
                }
            }
            else
            {
                [self disableSyncForAccountFromConfig:changedAccount];
            }
        }
    }];
}

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account
{
    [RLMRealmConfiguration setDefaultConfiguration:[self.realmManager configForName:account.accountIdentifier]];
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];
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
            [self cancelDownloadOperations:YES uploadOperations:YES forAccountWithId:account.accountIdentifier];
            [self deleteRealmForAccount:account];
            account.isSyncOn = NO;
            [[AccountManager sharedManager] saveAccountsToKeychain];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
            completionBlock();
        }]];
        
        [presentingViewController presentViewController:confirmAlert animated:YES completion:nil];
    }
    else
    {
        [self deleteRealmForAccount:account];
        account.isSyncOn = NO;
        [[AccountManager sharedManager] saveAccountsToKeychain];
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
        completionBlock();
    }
}

- (void)disableSyncForAccountFromConfig:(UserAccount *)account
{
    [self cancelDownloadOperations:YES uploadOperations:NO forAccountWithId:account.accountIdentifier];
    [self deleteRealmForAccount:account];
    account.isSyncOn = NO;
    [[AccountManager sharedManager] saveAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:account];
}

#pragma mark - Sync operations
- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock
{
    if(node)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RLMRealm *backgroundRealm = [RLMRealm defaultRealm];
            NSMutableArray *arrayOfNodesToDelete = [NSMutableArray new];
            NSMutableArray *arrayOfNodesToSaveLocally = [NSMutableArray new];
            NSMutableArray *arrayOfPathsForFilesToBeDeleted = [NSMutableArray new];
            
            if(node.isDocument)
            {
                [weakSelf handleDocumentForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm];
            }
            else if(node.isFolder)
            {
                [weakSelf handleFolderForDelete:node arrayOfNodesToDelete:arrayOfNodesToDelete arrayOfNodesToSaveLocally:arrayOfNodesToSaveLocally arrayOfPaths:arrayOfPathsForFilesToBeDeleted inRealm:backgroundRealm];
            }
            
            BOOL hasSavedLocally = NO;
            
            if(arrayOfNodesToSaveLocally.count)
            {
                hasSavedLocally = YES;
                for(AlfrescoDocument *document in arrayOfNodesToSaveLocally)
                {
                    [weakSelf saveDeletedFileBeforeRemovingFromSync:document];
                }
            }
            
            [[RealmManager sharedManager] deleteRealmObjects:arrayOfNodesToDelete inRealm:backgroundRealm];
            for(NSString *path in arrayOfPathsForFilesToBeDeleted)
            {
                // No error handling here as we don't want to end up with Sync orphans
                [weakSelf.fileManager removeItemAtPath:path error:nil];
            }
            
            completionBlock(hasSavedLocally);
        });
    }
}

- (void)handleDocumentForDelete:(AlfrescoNode *)document arrayOfNodesToDelete:(NSMutableArray *)arrayToDelete arrayOfNodesToSaveLocally:(NSMutableArray *)arrayToSave arrayOfPaths:(NSMutableArray *)arrayOfPaths inRealm:(RLMRealm *)realm
{
    SyncNodeStatus *syncNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] inSyncNodesStatus:self.syncNodesStatus];
    syncNodeStatus.totalSize = 0;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:realm];
    if(nodeInfo)
    {
        [arrayToDelete addObject:nodeInfo];
    }
    BOOL isModifiedLocally = [self isNodeModifiedSinceLastDownload:document inRealm:realm];
    if(isModifiedLocally)
    {
        [arrayToSave addObject:document];
    }
    
    NSString *nodeSyncName = [self.syncHelper syncNameForNode:document inRealm:realm];
    NSString *syncNodeContentPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier] stringByAppendingPathComponent:nodeSyncName];
    if(syncNodeContentPath && nodeSyncName)
    {
        [arrayOfPaths addObject:syncNodeContentPath];
    }
}

- (void)handleFolderForDelete:(AlfrescoNode *)folder arrayOfNodesToDelete:(NSMutableArray *)arrayToDelete arrayOfNodesToSaveLocally:(NSMutableArray *)arrayToSave arrayOfPaths:(NSMutableArray *)arrayOfPaths inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *folderInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:folder] ifNotExistsCreateNew:NO inRealm:realm];
    if(folderInfo)
    {
        [arrayToDelete addObject:folderInfo];
    }
    RLMLinkingObjects *subNodes = folderInfo.nodes;
    for(RealmSyncNodeInfo *subNodeInfo in subNodes)
    {
        AlfrescoNode *subNode = subNodeInfo.alfrescoNode;
        if(subNode.isDocument)
        {
            [self handleDocumentForDelete:subNode arrayOfNodesToDelete:arrayToDelete arrayOfNodesToSaveLocally:arrayToSave arrayOfPaths:arrayOfPaths inRealm:realm];
        }
        else if(subNode.isFolder)
        {
            [self handleFolderForDelete:subNode arrayOfNodesToDelete:arrayToDelete arrayOfNodesToSaveLocally:arrayToSave arrayOfPaths:arrayOfPaths inRealm:realm];
        }
    }
}

- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document
{
    NSString *contentPath = [self contentPathForNode:document];
    NSMutableArray *syncObstableDeleted = [_syncObstacles objectForKey:kDocumentsDeletedOnServerWithLocalChanges];
    
    // copying to temporary location in order to rename the file to original name (sync uses node identifier as document name)
    NSString *temporaryPath = [NSTemporaryDirectory() stringByAppendingPathComponent:document.name];
    if([self.fileManager fileExistsAtPath:temporaryPath])
    {
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
    }
    [self.fileManager copyItemAtPath:contentPath toPath:temporaryPath error:nil];
    
    [[DownloadManager sharedManager] saveDocument:document contentPath:temporaryPath completionBlock:^(NSString *filePath) {
        [self.fileManager removeItemAtPath:contentPath error:nil];
        [self.fileManager removeItemAtPath:temporaryPath error:nil];
        RLMRealm *realm = [RLMRealm defaultRealm];
        [self.syncHelper resolvedObstacleForDocument:document inRealm:realm];
    }];
    
    // remove document from obstacles dictionary
    NSArray *syncObstaclesDeletedNodeIdentifiers = [self.syncHelper syncIdentifiersForNodes:syncObstableDeleted];
    for (int i = 0;  i < syncObstaclesDeletedNodeIdentifiers.count; i++)
    {
        if ([syncObstaclesDeletedNodeIdentifiers[i] isEqualToString:[self.syncHelper syncIdentifierForNode:document]])
        {
            [syncObstableDeleted removeObjectAtIndex:i];
            break;
        }
    }
}

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
                                                                            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                            
                                                                            if (succeeded)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                syncNodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:document];
                                                                                syncNodeInfo.lastDownloadedDate = [NSDate date];
                                                                                syncNodeInfo.syncContentPath = destinationPath;
                                                                                syncNodeInfo.reloadContent = NO;
                                                                                [backgroundRealm commitWriteTransaction];
                                                                                
                                                                                RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                                                                                [[RealmManager sharedManager] deleteRealmObject:syncError inRealm:backgroundRealm];
                                                                            }
                                                                            else
                                                                            {
                                                                                nodeStatus.status = SyncStatusFailed;
                                                                                syncNodeInfo.reloadContent = YES;
                                                                                
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
                                                                            RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:YES inRealm:backgroundRealm];
                                                                            if (uploadedDocument)
                                                                            {
                                                                                nodeStatus.status = SyncStatusSuccessful;
                                                                                nodeStatus.activityType = SyncActivityTypeIdle;
                                                                                
                                                                                [backgroundRealm beginWriteTransaction];
                                                                                nodeInfo.node = [NSKeyedArchiver archivedDataWithRootObject:uploadedDocument];
                                                                                nodeInfo.lastDownloadedDate = [NSDate date];
                                                                                nodeInfo.isRemovedFromSyncHasLocalChanges = NO;
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

- (void)cancelAllSyncOperations
{
    NSArray *syncOperationKeys = [self.syncOperations allKeys];
    
    for (NSString *accountId in syncOperationKeys)
    {
        [self cancelDownloadOperations:YES uploadOperations:YES forAccountWithId:accountId];
    }
}

- (void)cancelAllDownloadOperationsForAccountWithId:(NSString *)accountId
{
    [self cancelDownloadOperations:YES uploadOperations:NO forAccountWithId:accountId];
}

- (void)cancelDownloadOperations:(BOOL)shouldCancelDownloadOperations uploadOperations:(BOOL)shouldCancelUploadOperations forAccountWithId:(NSString *)accountId
{
    NSArray *syncDocumentIdentifiers = [self.syncOperations[accountId] allKeys];
    
    for (NSString *documentIdentifier in syncDocumentIdentifiers)
    {
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:documentIdentifier];
        if((nodeStatus.activityType == SyncActivityTypeDownload) && shouldCancelDownloadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:accountId];
        }
        else if ((nodeStatus.activityType == SyncActivityTypeUpload) && shouldCancelUploadOperations)
        {
            [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:accountId];
        }
    }
    
    if(shouldCancelUploadOperations && shouldCancelDownloadOperations)
    {
        AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
        syncProgress.totalSyncSize = 0;
        syncProgress.syncProgressSize = 0;
    }
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier
{
    [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:[AccountManager sharedManager].selectedAccount.accountIdentifier];
}

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier inAccountWithId:(NSString *)accountId
{
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSString *syncDocumentIdentifier = [Utility nodeRefWithoutVersionID:documentIdentifier];
        SyncNodeStatus *nodeStatus = [self syncStatusForNodeWithId:syncDocumentIdentifier];
        
        RLMRealm *backgroundRealm = [self realmForAccount:accountId];
        
        NSMutableDictionary *syncOperationForAccount = self.syncOperations[accountId];
        SyncOperation *syncOperation = [syncOperationForAccount objectForKey:syncDocumentIdentifier];
        [syncOperation cancelOperation];
        [syncOperationForAccount removeObjectForKey:syncDocumentIdentifier];
        nodeStatus.status = SyncStatusFailed;
        
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:syncDocumentIdentifier ifNotExistsCreateNew:NO inRealm:backgroundRealm];
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
    
    return isSyncing;
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

- (void)didUploadNode:(AlfrescoNode *)node fromPath:(NSString *)tempPath toFolder:(AlfrescoFolder *)folder
{
    if([AccountManager sharedManager].selectedAccount.isSyncOn)
    {
        RLMRealm *realm = [[RealmManager sharedManager] createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
        if([self isNodeInSyncList:folder inRealm:realm])
        {
            NSString *syncNameForNode = [self.syncHelper syncNameForNode:node inRealm:realm];
            RealmSyncNodeInfo *syncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:YES inRealm:realm];
            RealmSyncNodeInfo *parentSyncNodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:folder] ifNotExistsCreateNew:NO inRealm:realm];
            
            [realm beginWriteTransaction];
            syncNodeInfo.parentNode = parentSyncNodeInfo;
            syncNodeInfo.isTopLevelSyncNode = NO;
            [realm commitWriteTransaction];
            
            SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
            
            if(node.isDocument)
            {
                NSString *selectedAccountIdentifier = [[AccountManager sharedManager] selectedAccount].accountIdentifier;
                NSString *syncContentPath = [[self.syncHelper syncContentDirectoryPathForAccountWithId:selectedAccountIdentifier] stringByAppendingPathComponent:syncNameForNode];
                
                NSError *movingFileError = nil;
                [[AlfrescoFileManager sharedManager] copyItemAtPath:tempPath toPath:syncContentPath error:&movingFileError];
                
                if(movingFileError)
                {
                    nodeStatus.status = SyncStatusFailed;
                    
                    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:YES inRealm:realm];
                    [realm beginWriteTransaction];
                    syncError.errorCode = movingFileError.code;
                    syncError.errorDescription = [movingFileError localizedDescription];
                    
                    syncNodeInfo.syncError = syncError;
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
                else
                {
                    [[RealmManager sharedManager] updateSyncNodeInfoWithId:[self.syncHelper syncIdentifierForNode:node] withNode:node lastDownloadedDate:[NSDate date] syncContentPath:syncContentPath inRealm:realm];
                    nodeStatus.status = SyncStatusSuccessful;
                    nodeStatus.activityType = SyncActivityTypeIdle;
                    [realm beginWriteTransaction];
                    syncNodeInfo.reloadContent = NO;
                    [realm commitWriteTransaction];
                }
            }
            else if (node.isFolder)
            {
                [[RealmManager sharedManager] updateSyncNodeInfoWithId:[self.syncHelper syncIdentifierForNode:node] withNode:node lastDownloadedDate:nil syncContentPath:nil inRealm:realm];
                nodeStatus.status = SyncStatusSuccessful;
                nodeStatus.activityType = SyncActivityTypeIdle;
            }
        }
    }
}

- (void)didUploadNewVersionForDocument:(AlfrescoDocument *)document updatedDocument:(AlfrescoDocument *)updatedDocument fromPath:(NSString *)path
{
    if([AccountManager sharedManager].selectedAccount.isSyncOn)
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            RLMRealm *backgroundRealm = [[RealmManager sharedManager] createRealmWithName:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if([weakSelf isNodeInSyncList:document])
            {
                RealmSyncNodeInfo *documentInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[weakSelf.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:backgroundRealm];
                [backgroundRealm beginWriteTransaction];
                documentInfo.node = [NSKeyedArchiver archivedDataWithRootObject:updatedDocument];
                documentInfo.lastDownloadedDate = [NSDate date];
                [backgroundRealm commitWriteTransaction];
                
                [self.fileManager removeItemAtPath:[self contentPathForNode:document] error:nil];
                [self.fileManager moveItemAtPath:path toPath:[self contentPathForNode:document] error:nil];
            }
        });
    }
}

- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    NSString *selectedAccountIdentifier = selectedAccount.accountIdentifier;
    NSMutableDictionary *nodesInfoForSelectedAccount = self.syncNodesInfo[selectedAccountIdentifier];
    NSMutableArray *topLevelSyncNodes = nodesInfoForSelectedAccount[selectedAccountIdentifier];
    BOOL isSyncNodesInfoInMemory = (topLevelSyncNodes != nil);

    void (^syncNode)(AlfrescoNode *) = ^void (AlfrescoNode *nodeToBeSynced){
        // start sync for this node only
        if ([self isSyncEnabled])
        {
            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                SyncNodeStatus *syncNodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] inSyncNodesStatus:self.syncNodesStatus];
                
                if (syncNodeStatus.activityType == SyncActivityTypeIdle)
                {
                    syncNodeStatus.activityType = SyncActivityTypeDownload;
                }
                
                [self downloadDocument:(AlfrescoDocument *)node withCompletionBlock:^(BOOL completed) {
                    if (completionBlock)
                    {
                        completionBlock(YES);
                    }
                }];
            });
        }
    };
    
    if (selectedAccount.isSyncOn)
    {
        [self showSyncAlertWithCompletionBlock:^(BOOL completed) {
            [self retrievePermissionsForNodes:@[node] withCompletionBlock:^{
                if (isSyncNodesInfoInMemory)
                {
                    [topLevelSyncNodes addObject:node];
                }
                else
                {
                    NSMutableDictionary *nodesInfoForSelectedAccount = [NSMutableDictionary dictionary];
                    self.syncNodesInfo[selectedAccountIdentifier] = nodesInfoForSelectedAccount;
                    nodesInfoForSelectedAccount[selectedAccountIdentifier] = [@[node] mutableCopy];
                }
                
                if (node.isFolder == NO)
                {
                    syncNode(node);
                }
                
                //TODO: sync folders as well
            }];
        }];
    }
    else
    {
        [topLevelSyncNodes addObject:node];
        if (completionBlock != NULL)
        {
            completionBlock(YES);
        }
    }
}

#pragma mark - Sync node information
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
        
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:realm];
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

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node
{
    return [self isNodeInSyncList:node inRealm:self.mainThreadRealm];
}

- (BOOL)isNodeInSyncList:(AlfrescoNode *)node inRealm:(RLMRealm *)realm
{
    BOOL isInSyncList = NO;
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:realm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode || nodeInfo.parentNode)
        {
            isInSyncList = YES;
        }
    }
    return isInSyncList;
}

- (BOOL)isTopLevelSyncNode:(AlfrescoNode *)node
{
    BOOL isTopLevelSyncNode = NO;
    
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:self.mainThreadRealm];
    if (nodeInfo)
    {
        if (nodeInfo.isTopLevelSyncNode)
        {
            isTopLevelSyncNode = YES;
        }
    }
    
    return isTopLevelSyncNode;
}

- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node
{
    RealmSyncError *syncError = [[RealmManager sharedManager] errorObjectForNodeWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:self.mainThreadRealm];
    return syncError.errorDescription;
}

- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    SyncNodeStatus *nodeStatus = [self.syncHelper syncNodeStatusObjectForNodeWithId:syncNodeId inSyncNodesStatus:self.syncNodesStatus];
    return nodeStatus;
}

- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = [self.permissions objectForKey:[self.syncHelper syncIdentifierForNode:node]];
    
    if (!permissions)
    {
        RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:node] ifNotExistsCreateNew:NO inRealm:[RLMRealm defaultRealm]];
        
        if (nodeInfo.permissions)
        {
            permissions = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.permissions];
        }
    }
    return permissions;
}

- (NSString *)contentPathForNode:(AlfrescoDocument *)document
{
    RealmSyncNodeInfo *nodeInfo = [self.realmManager syncNodeInfoForObjectWithId:[self.syncHelper syncIdentifierForNode:document] ifNotExistsCreateNew:NO inRealm:[RLMRealm defaultRealm]];
    
    NSString *newNodePath = nil;
    if(nodeInfo)
    {
        NSString *syncDirectory = [[AlfrescoFileManager sharedManager] syncFolderPath];
        newNodePath = [syncDirectory stringByAppendingPathComponent:nodeInfo.syncContentPath];
    }
    
    return newNodePath;
}

- (AlfrescoNode *)alfrescoNodeForIdentifier:(NSString *)nodeId inRealm:(RLMRealm *)realm
{
    NSString *syncNodeId = [Utility nodeRefWithoutVersionID:nodeId];
    RealmSyncNodeInfo *nodeInfo = [[RealmManager sharedManager] syncNodeInfoForObjectWithId:syncNodeId ifNotExistsCreateNew:NO inRealm:realm];
    
    AlfrescoNode *node = nil;
    if (nodeInfo.node)
    {
        node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
    }
    return node;
}

#pragma mark - Sync progress delegate
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

#pragma mark - NSNotifications
- (void)selectedProfileDidChange:(NSNotification *)notification
{
    UserAccount *changedAccount = notification.userInfo[kAlfrescoConfigProfileDidChangeForAccountKey];
    AlfrescoProfileConfig *selectedProfile = notification.object;
    [self determineSyncFeatureStatus:changedAccount selectedProfile:selectedProfile];
}

- (void)sessionReceived:(NSNotification *)notification
{
    UserAccount *changedAccount = [AccountManager sharedManager].selectedAccount;
    [self changeDefaultConfigurationForAccount:changedAccount];
    AlfrescoProfileConfig *selectedProfileForAccount = [AppConfigurationManager sharedManager].selectedProfile;
    [self determineSyncFeatureStatus:changedAccount selectedProfile:selectedProfileForAccount];
    
    id<AlfrescoSession> session = notification.object;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    
    self.selectedAccountSyncIdentifier = changedAccount.accountIdentifier;
    NSOperationQueue *syncQueue = self.syncQueues[self.selectedAccountSyncIdentifier];
    
    if (!syncQueue)
    {
        syncQueue = [[NSOperationQueue alloc] init];
        syncQueue.name = self.selectedAccountSyncIdentifier;
        syncQueue.maxConcurrentOperationCount = kSyncMaxConcurrentOperations;
        
        self.syncQueues[self.selectedAccountSyncIdentifier] = syncQueue;
        self.syncOperations[self.selectedAccountSyncIdentifier] = [NSMutableDictionary dictionary];
        
        AccountSyncProgress *syncProgress = [[AccountSyncProgress alloc] initWithObserver:self];
        self.accountsSyncProgress[self.selectedAccountSyncIdentifier] = syncProgress;
    }
    
    syncQueue.suspended = NO;
    [self notifyProgressDelegateAboutNumberOfNodesInProgress];
}

- (void)mainMenuConfigurationChanged:(NSNotification *)notification
{
    // if no object is passed with the notification then we have no accounts in the app
    if(notification.object)
    {
        if([notification.object respondsToSelector:@selector(account)])
        {
            UserAccount *changedAccount = [notification.object performSelector:@selector(account)];
            AlfrescoConfigService *configServiceForAccount = [[AppConfigurationManager sharedManager] configurationServiceForAccount:changedAccount];
            [configServiceForAccount retrieveProfileWithIdentifier:changedAccount.selectedProfileIdentifier completionBlock:^(AlfrescoProfileConfig *config, NSError *error) {
                if(config)
                {
                    [self determineSyncFeatureStatus:changedAccount selectedProfile:config];
                }
            }];
        }
    }
}

#pragma mark - Realm notifications
- (RLMNotificationToken *)notificationTokenForAlfrescoNode:(AlfrescoNode *)node notificationBlock:(void (^)(RLMResults<RealmSyncNodeInfo *> *results, RLMCollectionChange *change, NSError *error))block
{
    RLMNotificationToken *token = nil;
    
    if(node)
    {
        token = [[RealmSyncNodeInfo objectsInRealm:self.mainThreadRealm where:@"syncNodeInfoId == %@", [[RealmSyncHelper sharedHelper] syncIdentifierForNode:node]] addNotificationBlock:block];
    }
    else
    {
        token = [[RealmSyncNodeInfo objectsInRealm:[RealmSyncManager sharedManager].mainThreadRealm where:@"isTopLevelSyncNode = %@", @YES] addNotificationBlock:block];
    }
    
    return token;
}

#pragma mark - Private methods
- (NSString *)accountIdentifierForAccount:(UserAccount *)userAccount
{
    NSString *accountIdentifier = userAccount.accountIdentifier;
    
    if (userAccount.accountType == UserAccountTypeCloud)
    {
        accountIdentifier = [NSString stringWithFormat:@"%@-%@", accountIdentifier, userAccount.selectedNetworkId];
    }
    return accountIdentifier;
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

- (BOOL)isFirstUse
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    return !selectedAccount.didAskToSync;
}

- (void)showSyncAlertWithCompletionBlock:(void (^)(BOOL completed))completionBlock
{
    AccountManager *accountManager = [AccountManager sharedManager];
    UserAccount *selectedAccount = accountManager.selectedAccount;
    
    if ([self isFirstUse] && !selectedAccount.isSyncOn)
    {
        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"sync.enable.message", @"Would you like to automatically keep your favorite documents in sync with this %@?"), [[UIDevice currentDevice] model]];
        [self displayConfirmationAlertWithTitle:NSLocalizedString(@"sync.enable.title", @"Sync Documents")
                                        message:message
                                completionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                                    
                                    selectedAccount.didAskToSync = YES;
                                    selectedAccount.isSyncOn = !isCancelButton;
                                    [accountManager saveAccountsToKeychain];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:selectedAccount];
                                    completionBlock(YES);
                                }];
    }
    else
    {
        completionBlock(YES);
    }
}

- (void)displayConfirmationAlertWithTitle:(NSString *)title message:(NSString *)message completionBlock:(UIAlertViewDismissBlock)completionBlock
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:NSLocalizedString(@"No", @"No")
                                          otherButtonTitles:NSLocalizedString(@"Yes", @"Yes"), nil];
    [alert showWithCompletionBlock:completionBlock];
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
                    self.permissions[[self.syncHelper syncIdentifierForNode:node]] = permissions;
                }
                
                if (totalPermissionRequests == 0 && completionBlock != NULL)
                {
                    completionBlock();
                }
            }];
        }
    }
}

@end
