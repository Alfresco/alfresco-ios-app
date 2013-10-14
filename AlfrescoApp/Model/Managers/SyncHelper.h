//
//  SyncHelper.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
@class SyncNodeStatus;

extern NSString * const kLastDownloadedDateKey;
extern NSString * const kSyncNodeKey;
extern NSString * const kSyncContentPathKey;
extern NSString * const kSyncReloadContentKey;

@interface SyncHelper : NSObject

- (NSString *)syncContentDirectoryPathForRepository:(NSString *)repositoryId;
- (NSString *)syncNameForNode:(AlfrescoNode *)node;

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId;
- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node;

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRepitory:(NSString *)repositoryId;
- (void)deleteNodesFromSync:(NSArray *)array inRepitory:(NSString *)repositoryId;
- (void)removeSyncContentAndInfo;

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId inSyncNodesStatus:(NSDictionary *)syncStatuses;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document;

- (void)updateLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo forRepositoryWithId:(NSString *)repositoryId preserveInfo:(NSDictionary *)info refreshExistingSyncNodes:(BOOL)refreshExisting;

+ (SyncHelper *)sharedHelper;

@end
