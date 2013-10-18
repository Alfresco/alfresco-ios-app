//
//  CoreDataUtils.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CoreDataUtils.h"
#import "AlfrescoLog.h"
#import "AppDelegate.h"

static NSManagedObjectContext *managedObjectContext;

NSString * const kSyncRepoManagedObject = @"SyncRepository";
NSString * const kSyncNodeInfoManagedObject = @"SyncNodeInfo";
NSString * const kSyncErrorManagedObject = @"SyncError";


@implementation CoreDataUtils

#pragma mark - Fetch Methods

+ (NSArray*)retrieveRecordsForTable:(NSString *)table
{
	return [CoreDataUtils retrieveRecordsForTable:table withPredicate:nil sortDescriptors:nil];
}

+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate
{
    return [CoreDataUtils retrieveRecordsForTable:table withPredicate:predicate sortDescriptors:nil];
}

+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:[CoreDataUtils managedObjectContext]];
	
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
    
    if (predicate)
    {
        [fetchRequest setPredicate:predicate];
    }
	if (sortDescriptors)
    {
        [fetchRequest setSortDescriptors:sortDescriptors];
    }
    
	NSArray *records = [[CoreDataUtils managedObjectContext] executeFetchRequest:fetchRequest error:nil];
	return records;
}

+ (NSManagedObjectContext *)managedObjectContext
{
    if (!managedObjectContext)
    {
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        managedObjectContext = appDelegate.managedObjectContext;
    }
    return managedObjectContext;
}

#pragma mark - Delete Records Methods

+ (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject
{
    if (managedObject)
    {
        [[CoreDataUtils managedObjectContext] deleteObject:managedObject];
        [self saveContext];
    }
}

+ (void)deleteAllRecordsInTable:(NSString*)table
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	// needed to prevent faults being returned
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	[fetchRequest setEntity:entity];
	
	NSArray* resultsArray = [[CoreDataUtils managedObjectContext] executeFetchRequest:fetchRequest error:nil];
    
	for (NSManagedObject *managedObject in resultsArray)
    {
        [[CoreDataUtils managedObjectContext] deleteObject:managedObject];
    }
	[self saveContext];
}

#pragma mark - Save context methods

+ (void)saveContext
{
	NSError* error = nil;
	if (![[CoreDataUtils managedObjectContext] save:&error])
    {
		AlfrescoLogDebug(@"Error with database transaction: %@", error);
	}
}

#pragma mark - Create ManagedObject Methods

+ (SyncRepository *)createSyncRepoMangedObject
{
    SyncRepository *syncRepo = (SyncRepository *)[NSEntityDescription insertNewObjectForEntityForName:kSyncRepoManagedObject inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    return syncRepo;
}

+ (SyncNodeInfo *)createSyncNodeInfoMangedObject
{
    SyncNodeInfo *syncNodeInfo = (SyncNodeInfo *)[NSEntityDescription insertNewObjectForEntityForName:kSyncNodeInfoManagedObject inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    return syncNodeInfo;
}

+ (SyncError *)createSyncErrorMangedObject
{
    SyncError *syncError = (SyncError *)[NSEntityDescription insertNewObjectForEntityForName:kSyncErrorManagedObject inManagedObjectContext:[CoreDataUtils managedObjectContext]];
    return syncError;
}

#pragma mark - Retrieve ManagedObjects

+ (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId
{
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:[NSPredicate predicateWithFormat:@"syncNodeInfoId == %@", nodeId]];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

+ (SyncRepository *)repositoryObjectForRepositoryWithId:(NSString *)repositoryId
{
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncRepoManagedObject withPredicate:[NSPredicate predicateWithFormat:@"repositoryId == %@", repositoryId]];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

+ (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId ifNotExistsCreateNew:(BOOL)createNew
{
    SyncError *syncError = nil;
    
    if (nodeId)
    {
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeId];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [CoreDataUtils createSyncErrorMangedObject];
            syncError.errorId = nodeId;
        }
    }
    return syncError;
}

+ (NSArray *)topLevelSyncNodesInfoForRepositoryWithId:(NSString *)repositoryId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"repository.repositoryId == %@ && isTopLevelSyncNode == YES", repositoryId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor]];
    return nodes;
}

+ (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"parentNode.syncNodeInfoId == %@", folderId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor]];
    return nodes;
}

+ (BOOL)isTopLevelSyncNode:(NSString *)nodeId
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"syncNodeInfoId == %@ && isTopLevelSyncNode == YES", nodeId];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate];
    return nodes.count > 0;
}

#pragma mark - Debugging Dump Methods

+ (void)logAllData
{
    NSArray *syncRepositories = [CoreDataUtils retrieveRecordsForTable:kSyncRepoManagedObject];
    for (SyncRepository *repo in syncRepositories)
    {
        AlfrescoLogDebug(@"Sync Repository : %@", repo.repositoryId);
    }
    
    NSArray *nodesInfo = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject];
    
    for (SyncNodeInfo *nodeInfo in nodesInfo)
    {
        AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
        AlfrescoLogDebug(@"Node Info : %@ ---  total count: %d ------- id: %@", node.name, nodesInfo.count, nodeInfo.syncNodeInfoId);
    }
}

@end
