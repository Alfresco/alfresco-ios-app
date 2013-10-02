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


@implementation CoreDataUtils

#pragma mark - Fetch Methods

+ (NSArray*)retrieveRecordsForTable:(NSString *)table
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:[CoreDataUtils managedObjectContext]];
	
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	
	NSArray *records = [[CoreDataUtils managedObjectContext] executeFetchRequest:fetchRequest error:nil];
	return records;
}

+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:[CoreDataUtils managedObjectContext]];
	
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	[fetchRequest setEntity:entity];
	[fetchRequest setPredicate:predicate];
	
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
	[[CoreDataUtils managedObjectContext] deleteObject:managedObject];
	
	[self saveContext];
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

+ (NSArray *)topLevelSyncNodesInfoForRepositoryWithId:(NSString *)repositoryId
{
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:[NSPredicate predicateWithFormat:@"repository.repositoryId == %@ && isTopLevelSyncNode == YES", repositoryId]];
    return nodes;
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
