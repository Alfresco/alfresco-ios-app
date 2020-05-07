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
  
#import "CoreDataHelper.h"
#import "SyncAccount.h"
#import "SyncNodeInfo.h"
#import "SyncError.h"

extern NSString * const kSyncAccountManagedObject;
extern NSString * const kSyncNodeInfoManagedObject;
extern NSString * const kSyncErrorManagedObject;

@interface CoreDataSyncHelper : CoreDataHelper

- (SyncAccount *)createSyncAccountMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncNodeInfo *)createSyncNodeInfoMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncError *)createSyncErrorMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSPersistentStoreCoordinator *)syncPersistenceStoreCoordinator;

// Retrieve ManagedObjects
- (SyncAccount *)accountObjectForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId inAccountWithId:(NSString *)accountId ifNotExistsCreateNew:(BOOL)createNew inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)topLevelSyncNodesInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (BOOL)isTopLevelSyncNode:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (AlfrescoDocument *)retrieveSyncedAlfrescoDocumentForIdentifier:(NSString *)documentIdentifier managedObjectContext:(NSManagedObjectContext *)managedContext;

- (NSArray *)retrieveSyncFileNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)retrieveSyncFolderNodesForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

@end
