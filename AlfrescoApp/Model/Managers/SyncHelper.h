//
//  SyncHelper.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@class SyncNodeStatus;

extern NSString * const kLastDownloadedDateKey;
extern NSString * const kSyncNodeKey;
extern NSString * const kSyncContentPathKey;
extern NSString * const kSyncReloadContentKey;

@interface SyncHelper : NSObject

- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountId;
- (void)populateNodes:(NSArray *)nodes
       inParentFolder:(NSString *)folderId
     forAccountWithId:(NSString *)accountId
         preserveInfo:(NSDictionary *)info
          permissions:(NSDictionary *)permissions inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (NSString *)syncNameForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSString *)syncIdentifierForNode:(AlfrescoNode *)node;
- (NSMutableArray *)syncIdentifiersForNodes:(NSArray *)nodes;

- (AlfrescoNode *)localNodeForNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSDate *)lastDownloadedDateForNode:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)deleteNodeFromSync:(AlfrescoNode *)node inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)deleteNodesFromSync:(NSArray *)array inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)removeSyncContentAndInfoInManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)removeSyncContentAndInfoForAccountWithId:(NSString *)accountId syncNodeStatuses:(NSDictionary *)nodeStatuses inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (SyncNodeStatus *)syncNodeStatusObjectForNodeWithId:(NSString *)nodeId inSyncNodesStatus:(NSDictionary *)syncStatuses;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)updateLocalSyncInfoWithRemoteInfo:(NSDictionary *)syncNodesInfo
                         forAccountWithId:(NSString *)accountId
                             preserveInfo:(NSDictionary *)info
                              permissions:(NSDictionary *)permissions
                 refreshExistingSyncNodes:(BOOL)refreshExisting
                   inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (AlfrescoDocument *)syncDocumentFromDocumentIdentifier:(NSString *)documentRef;

+ (SyncHelper *)sharedHelper;

@end
