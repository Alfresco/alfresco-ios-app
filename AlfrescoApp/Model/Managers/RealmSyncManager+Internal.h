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
#import "AccountManager.h"
#import "ConnectivityManager.h"

@interface RealmSyncManager()

@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (atomic, assign) NSInteger nodeRequestsInProgressCount;
@property (nonatomic, strong) NSMutableDictionary *syncQueues;
@property (nonatomic, strong) NSMutableDictionary *syncNodesInfo;
@property (nonatomic, strong) NSDictionary *syncObstacles;
@property (nonatomic, strong) NSMutableDictionary *permissions;
@property (nonatomic, strong) NSString *selectedAccountSyncIdentifier;

@property (nonatomic, strong) NSMutableDictionary *nodesToDownload;
@property (nonatomic, strong) NSMutableDictionary *nodesToUpload;

@property (nonatomic) BOOL disableSyncInProgress;
@property (nonatomic) BOOL lastConnectivityFlag;

@property (atomic, strong) NSMutableDictionary *unsyncCompletionBlocks;

- (SyncOperationQueue *)currentOperationQueue;

@end
