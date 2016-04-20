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
#import <Realm/Realm.h>
#import "SyncConstants.h"
#import "SyncNodeStatus.h"

@protocol RealmSyncManagerProgressDelegate <NSObject>

@optional
- (void)numberOfSyncOperationsInProgress:(NSInteger)numberOfOperations;
- (void)totalSizeToSync:(unsigned long long)totalSize syncedSize:(unsigned long long)syncedSize;

@end

@interface RealmSyncManager : NSObject

@property (nonatomic, weak) id<RealmSyncManagerProgressDelegate> progressDelegate;
@property (nonatomic, strong) RLMRealm *mainThreadRealm;

/**
 * Returns the shared singleton
 */
+ (RealmSyncManager *)sharedManager;

- (RLMRealm *)createRealmForAccount:(UserAccount *)account;
- (void)deleteRealmForAccount:(UserAccount *)account;
- (void)disableSyncForAccount:(UserAccount*)account fromViewController:(UIViewController *)presentingViewController cancelBlock:(void (^)(void))cancelBlock completionBlock:(void (^)(void))completionBlock;
- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId;
- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier;
- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node;

/*
 * Sync Methods
 */
- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock;

/*
 * Sync Utilities
 */
- (BOOL)isCurrentlySyncing;
- (void)cancelAllSyncOperations;

/**
 * Realm Utilities
 */
- (void)changeDefaultConfigurationForAccount:(UserAccount *)account;

@end
