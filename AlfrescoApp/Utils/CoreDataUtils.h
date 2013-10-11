//
//  CoreDataUtils.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SyncRepository.h"
#import "SyncNodeInfo.h"
#import "SyncError.h"

extern NSString * const kSyncRepoManagedObject;
extern NSString * const kSyncNodeInfoManagedObject;
extern NSString * const kSyncErrorManagedObject;

@interface CoreDataUtils : NSObject

+ (SyncRepository *)createSyncRepoMangedObject;
+ (SyncNodeInfo *)createSyncNodeInfoMangedObject;
+ (SyncError *)createSyncErrorMangedObject;

+ (NSArray*)retrieveRecordsForTable:(NSString *)table;
+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate;
+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors;

+ (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject;
+ (void)deleteAllRecordsInTable:(NSString*)table;

+ (void)logAllData;

+ (void)saveContext;
+ (NSManagedObjectContext *)managedObjectContext;

// Retrieve ManagedObjects
+ (SyncRepository *)repositoryObjectForRepositoryWithId:(NSString *)repositoryId;
+ (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId;
+ (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId ifNotExistsCreateNew:(BOOL)createNew;
+ (NSArray *)topLevelSyncNodesInfoForRepositoryWithId:(NSString *)repositoryId;
+ (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId;

@end
