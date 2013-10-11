//
//  SyncManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncNodeStatus.h"

extern NSString * const kDocumentsUnfavoritedOnServerWithLocalChanges;
extern NSString * const kDocumentsDeletedOnServerWithLocalChanges;

@interface SyncManager : NSObject

/**
 * Returns the shared singleton
 */
+ (SyncManager *)sharedManager;

/*
 * Sync Methods
 */
- (NSString *)contentPathForNode:(AlfrescoDocument *)document;
- (SyncNodeStatus *)syncStatusForNode:(AlfrescoNode *)node;
- (NSMutableArray *)topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)folder;
- (NSString *)syncErrorDescriptionForNode:(AlfrescoNode *)node;
- (NSArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSArray *syncedNodes))completionBlock;

- (void)cancelSyncForDocument:(AlfrescoDocument *)document;
- (void)retrySyncForDocument: (AlfrescoDocument *)document;
/*
 * Sync Obstacle Methods
 */
- (BOOL)didEncounterObstaclesDuringSync;
- (void)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node completionBlock:(void (^)(BOOL encounteredObstacle))completionBlock;
- (void)syncUnfavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer;
- (void)saveDeletedFavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document;

/*
 * Sync Utilities
 */
- (BOOL)isNodeInSyncList:(AlfrescoNode *)node;
- (BOOL)isFirstUse;
- (BOOL)isSyncEnabled;

/* 
 * Favorites Methods - these are placed here since we dont have Favorites Manager
 */
- (void)addFavorite:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL succeeded))completionBlock;
- (void)removeFavorite:(AlfrescoNode *)node withCompletionBlock:(void (^)(BOOL succeeded))completionBlock;

@end
