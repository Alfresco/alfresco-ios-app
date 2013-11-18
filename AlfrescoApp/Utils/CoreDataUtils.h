//
//  CoreDataUtils.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncAccount.h"
#import "SyncNodeInfo.h"
#import "SyncError.h"

extern NSString * const kSyncAccountManagedObject;
extern NSString * const kSyncNodeInfoManagedObject;
extern NSString * const kSyncErrorManagedObject;

@interface CoreDataUtils : NSObject

+ (SyncAccount *)createSyncAccountMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (SyncNodeInfo *)createSyncNodeInfoMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (SyncError *)createSyncErrorMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (NSArray*)retrieveRecordsForTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors inManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (void)deleteAllRecordsInTable:(NSString*)table inManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (void)logAllDataInManagedObjectContext:(NSManagedObjectContext *)managedContext;

+ (void)saveContextForManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (NSManagedObjectContext *)managedObjectContext;
+ (NSManagedObjectContext *)createPrivateManagedObjectContext;

// Retrieve ManagedObjects
+ (SyncAccount *)accountObjectForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId inAccountWithId:(NSString *)accountId ifNotExistsCreateNew:(BOOL)createNew inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (NSArray *)topLevelSyncNodesInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;
+ (BOOL)isTopLevelSyncNode:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext;

@end
