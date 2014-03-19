//
//  SyncManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncNodeStatus.h"

extern NSString * const kDocumentsRemovedFromSyncOnServerWithLocalChanges;
extern NSString * const kDocumentsDeletedOnServerWithLocalChanges;

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
- (void)retrySyncForDocument: (AlfrescoDocument *)document;
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
- (BOOL)isNodeInSyncList:(AlfrescoNode *)node;
- (BOOL)isFirstUse;
/*
 * shows if sync is enabled based on cellular / wifi preference
 */
- (BOOL)isSyncEnabled;

/*
 * shows if sync is on in settings
 */
- (BOOL)isSyncPreferenceOn;

@end
