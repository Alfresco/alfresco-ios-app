//
//  SyncHelper.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kLastDownloadedDateKey;
extern NSString * const kSyncNodeKey;

@interface SyncHelper : NSObject

- (NSString *)syncContentDirectoryPathForRepository:(NSString *)repositoryId;
- (NSString *)syncNameForNode:(AlfrescoNode *)node;

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId;
- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node;

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRepitory:(NSString *)repositoryId;
- (void)deleteNodesFromSync:(NSArray *)array inRepitory:(NSString *)repositoryId;
- (void)removeSyncContentAndInfo;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document;

- (void)resetLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo forRepositoryWithId:(NSString *)repositoryId preserveInfo:(NSDictionary *)info;

+ (SyncHelper *)sharedHelper;

@end
