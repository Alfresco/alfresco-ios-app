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

#import "SyncConstants.h"

@class SyncNodeStatus;

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

- (NSArray *)retrieveSyncFileNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)retrieveSyncFolderNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (SyncHelper *)sharedHelper;

@end
