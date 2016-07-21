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

#import <Foundation/Foundation.h>
#import "SyncNodeStatus.h"

@protocol RealmSyncManagerProgressDelegate <NSObject>

@optional
- (void)numberOfSyncOperationsInProgress:(NSInteger)numberOfOperations;
- (void)totalSizeToSync:(unsigned long long)totalSize syncedSize:(unsigned long long)syncedSize;

@end

@interface SyncOperationQueueManager : NSObject

@property (nonatomic, weak) id<RealmSyncManagerProgressDelegate> progressDelegate;

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session syncProgressDelegate:(id<RealmSyncManagerProgressDelegate>)syncProgressDelegate;
- (void)updateSession:(id<AlfrescoSession>)session;

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId;
- (void)removeSyncNodeStatusForNodeWithId:(NSString *)nodeId;

- (void)downloadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)uploadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)downloadContentsForNodes:(NSArray *)nodes withCompletionBlock:(void (^)(BOOL completed))completionBlock;

- (void)cancelDownloadOperations:(BOOL)shouldCancelDownloadOperations uploadOperations:(BOOL)shouldCancelUploadOperations;
- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier;

- (BOOL)isCurrentlySyncing;

@end
