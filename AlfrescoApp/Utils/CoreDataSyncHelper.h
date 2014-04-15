//
//  CoreDataSyncHelper.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
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

// Retrieve ManagedObjects
- (SyncAccount *)accountObjectForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId inAccountWithId:(NSString *)accountId ifNotExistsCreateNew:(BOOL)createNew inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)topLevelSyncNodesInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (BOOL)isTopLevelSyncNode:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (AlfrescoDocument *)retrieveSyncedAlfrescoDocumentForIdentifier:(NSString *)documentIdentifier managedObjectContext:(NSManagedObjectContext *)managedContext;

@end
