/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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
#import <UIKit/UIKit.h>
#import "RealmSyncCore.h"
#import "RealmSyncNodeInfo.h"
#import "SyncConstants.h"
#import "SyncNodeStatus.h"
#import "RealmManager.h"
#import "SyncOperationQueue.h"
#import "AlfrescoNode+Sync.h"

@protocol RealmSyncManagerSyncDisabledDelegate <NSObject>

- (void)syncFeatureStatusChanged:(BOOL)isSyncOn;

@end

@interface RealmSyncManager : NSObject

typedef NS_ENUM(NSInteger, DeleteRule)
{
    DeleteRuleAllNodes,                             // Delete subtree root node and all children, regardless they are top level or not
    DeleteRuleRootByForceAndKeepTopLevelChildren,   // Delete the root node (even if it's top level) and all children that are not top level.
                                                    //(eg. When unsyncing a folder, you want to delete the root, even if it's top level)
    DeleteRuleRootAndAndKeepTopLevelChildren        // Delete the root node only if isn't top level and all children that are not top level.
};

@property (nonatomic, weak) id<RealmSyncManagerProgressDelegate> progressDelegate;
@property (nonatomic, weak) id<RealmSyncManagerSyncDisabledDelegate> syncDisabledDelegate;

+ (RealmSyncManager *)sharedManager;

- (void)refreshWithCompletionBlock:(void (^)(BOOL completed))completionBlock;

/*
 * Sync Utilities
 */
- (BOOL)isCurrentlySyncing;
- (void)cancelAllSyncOperations;

/**
 * Sync node information
 */
- (BOOL)isNodeModifiedSinceLastDownload:(AlfrescoNode *)node inRealm:(RLMRealm *)realm;
- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId;
- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node;

/**
 * Sync operations
 */
- (void)deleteNodeFromSync:(AlfrescoNode *)node deleteRule:(DeleteRule)deleteRule withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock;
- (void)retrySyncForDocument:(AlfrescoDocument *)document completionBlock:(void (^)(void))completionBlock;
- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier completionBlock:(void (^)(void))completionBlock;
- (void)uploadDocument:(AlfrescoDocument *)document withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)unsyncNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)removeNode:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock;
- (void)cleanRealmOfNode:(AlfrescoNode *)node;
- (void)didUploadNode:(AlfrescoNode *)node fromPath:(NSString *)path toFolder:(AlfrescoFolder *)folder;

/**
 * Sync Feature
 */
- (RLMRealm *)realmForAccount:(NSString *)accountId;
- (void)deleteRealmForAccount:(UserAccount *)account;
- (void)disableSyncForAccount:(UserAccount*)account fromViewController:(UIViewController *)presentingViewController cancelBlock:(void (^)(void))cancelBlock completionBlock:(void (^)(void))completionBlock;
- (void)enableSyncForAccount:(UserAccount *)account;
- (void)cleanUpAccount:(UserAccount *)account cancelOperationsType:(CancelOperationsType)cancelType;

/**
 * Realm notifications
 */
- (RLMNotificationToken *)notificationTokenForAlfrescoNode:(AlfrescoNode *)node notificationBlock:(void (^)(RLMResults<RealmSyncNodeInfo *> *results, RLMCollectionChange *change, NSError *error))block;

/**
 * Sync Obstacles
 */
- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document;
- (void)presentSyncObstaclesIfNeeded;

@end
