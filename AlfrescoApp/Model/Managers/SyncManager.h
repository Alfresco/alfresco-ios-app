//
//  SyncManager.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SyncManager : NSObject

/**
 * Returns the shared singleton
 */
+ (SyncManager *)sharedManager;

/*
 * Sync Methods
 */
- (NSString *)contentPathForNode:(AlfrescoDocument *)document;
- (NSMutableArray *)topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)folder;
- (NSArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSArray *syncedNodes))completionBlock;

/*
 * Sync Obstacle Methods
 */
- (BOOL)didEncounterObstaclesDuringSync;
- (BOOL)checkForObstaclesInRemovingDownloadForNode:(AlfrescoNode *)node;
- (void)syncUnfavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document syncToServer:(BOOL)syncToServer;
- (void)saveDeletedFavoriteFileBeforeRemovingFromSync:(AlfrescoDocument *)document;

/*
 * Sync Utilities
 */
- (BOOL)isNodeInSyncList:(AlfrescoNode *)node;
- (BOOL)isFirstUse;
- (BOOL)isSyncEnabled;


@end
