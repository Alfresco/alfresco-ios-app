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

- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountId;
- (NSString *)syncNameForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)deleteNodeFromSync:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)deleteNodesFromSync:(NSArray *)array inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)removeSyncContentAndInfoInManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId inSyncNodesStatus:(NSDictionary *)syncStatuses;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)updateLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo
                         forAccountWithId:(NSString *)accountId
                             preserveInfo:(NSDictionary *)info
                 refreshExistingSyncNodes:(BOOL)refreshExisting
                   inManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (SyncHelper *)sharedHelper;

@end
