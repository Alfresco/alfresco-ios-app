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
  
#import "SyncNodeStatus.h"

@protocol SyncManagerProgressDelegate <NSObject>

@optional
- (void)numberOfSyncOperationsInProgress:(NSInteger)numberOfOperations;
- (void)totalSizeToSync:(unsigned long long)totalSize syncedSize:(unsigned long long)syncedSize;

@end

@interface SyncManager : NSObject

@property (nonatomic, weak) id<SyncManagerProgressDelegate> progressDelegate;

/**
 * Returns the shared singleton
 */
+ (SyncManager *)sharedManager;

/*
 * Sync Methods
 */
- (NSString *)contentPathForNode:(AlfrescoDocument *)document;
- (SyncNodeStatus *)syncStatusForNodeWithId:(NSString *)nodeId;
- (AlfrescoNode *)alfrescoNodeForIdentifier:(NSString *)nodeId;
- (AlfrescoPermissions *)permissionsForSyncNode:(AlfrescoNode *)node;
- (NSMutableArray *)topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)folder;
- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node;
- (NSMutableArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSMutableArray *syncedNodes))completionBlock;
- (void)addNodeToSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock;
/*
 * removes node from sync without deleting its content
 */
- (void)removeNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL completed))completionBlock;
/*
 * deletes node from sync completely including its content
 */
- (void)deleteNodeFromSync:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL savedLocally))completionBlock;

- (void)cancelSyncForDocumentWithIdentifier:(NSString *)documentIdentifier;
- (void)cancelAllSyncOperations;
- (void)retrySyncForDocument:(AlfrescoDocument *)document completionBlock:(void (^)(void))completionBlock;

- (void)updateSessionIfNeeded:(id<AlfrescoSession>)session;
/*
 * Sync Obstacle Methods
 */
- (BOOL)didEncounterObstaclesDuringSync;
- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock;
- (void)syncFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer;
- (void)saveDeletedFileBeforeRemovingFromSync:(AlfrescoDocument *)document;

/*
 * Sync Utilities
 */
- (BOOL)isCurrentlySyncing;
- (BOOL)isNodeInSyncList:(AlfrescoNode *)node;
- (BOOL)isFirstUse;
/*
 * shows if sync is on in settings
 */
- (BOOL)isSyncPreferenceOn;

@end
