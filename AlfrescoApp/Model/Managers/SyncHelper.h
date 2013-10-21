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
- (NSString *)syncNameForNode:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)deleteNodeFromSync:(AlfrescoNode *)node inRepitory:(NSString *)repositoryId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)deleteNodesFromSync:(NSArray *)array inRepitory:(NSString *)repositoryId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)removeSyncContentAndInfoInManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId inSyncNodesStatus:(NSDictionary *)syncStatuses;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)updateLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo
                      forRepositoryWithId:(NSString *)repositoryId
                             preserveInfo:(NSDictionary *)info
                 refreshExistingSyncNodes:(BOOL)refreshExisting
                   inManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (SyncHelper *)sharedHelper;

@end
