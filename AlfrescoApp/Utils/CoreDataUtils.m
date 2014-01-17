//
//  CoreDataUtils.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 20/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CoreDataUtils.h"
#import "AppDelegate.h"

static NSManagedObjectContext *managedObjectContext;

NSString * const kSyncAccountManagedObject = @"SyncAccount";
NSString * const kSyncNodeInfoManagedObject = @"SyncNodeInfo";
NSString * const kSyncErrorManagedObject = @"SyncError";


@implementation CoreDataUtils

#pragma mark - Fetch Methods

+ (NSArray*)retrieveRecordsForTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
	return [CoreDataUtils retrieveRecordsForTable:table withPredicate:nil sortDescriptors:nil inManagedObjectContext:managedContext];
}

+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    return [CoreDataUtils retrieveRecordsForTable:table withPredicate:predicate sortDescriptors:nil inManagedObjectContext:managedContext];
}

+ (NSArray*)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:managedContext];
	
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
    
	NSArray *records = [managedContext executeFetchRequest:fetchRequest error:nil];
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

+ (NSManagedObjectContext *)createPrivateManagedObjectContext
{
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = [CoreDataUtils managedObjectContext];
    return privateContext;
}

#pragma mark - Delete Records Methods

+ (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (managedObject)
    {
        [managedContext deleteObject:managedObject];
        [self saveContextForManagedObjectContext:managedContext];
    }
}

+ (void)deleteAllRecordsInTable:(NSString*)table inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
	NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:managedContext];
    
	NSFetchRequest* fetchRequest = [[NSFetchRequest alloc] init];
	
	// needed to prevent faults being returned
	[fetchRequest setReturnsObjectsAsFaults:NO];
	
	[fetchRequest setEntity:entity];
	
	NSArray* resultsArray = [managedContext executeFetchRequest:fetchRequest error:nil];
    
	for (NSManagedObject *managedObject in resultsArray)
    {
        [managedContext deleteObject:managedObject];
    }
	[self saveContextForManagedObjectContext:managedContext];
}

#pragma mark - Save context methods

+ (void)saveContextForManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSManagedObjectContext *mainManagedObjectContext = [CoreDataUtils managedObjectContext];
    
    if (managedContext == managedObjectContext)
    {
        NSError* error = nil;
        if (![managedContext save:&error])
        {
            AlfrescoLogDebug(@"Error with database transaction Main MOC: %@", error);
        }
    }
    else
    {
        [managedContext performBlockAndWait:^{
            NSError *secondaryMOCError = nil;
            if ([managedContext save:&secondaryMOCError])
            {
                [mainManagedObjectContext performBlockAndWait:^{
                    NSError *mainMOCError = nil;
                    if (![mainManagedObjectContext save:&mainMOCError])
                    {
                        AlfrescoLogDebug(@"Error with database transaction Main MOC: %@", mainMOCError);
                    }
                }];
            }
            else
            {
                AlfrescoLogDebug(@"Error with database transaction secondary MOC: %@", secondaryMOCError);
            }
        }];
    }
}

#pragma mark - Create ManagedObject Methods

+ (SyncAccount *)createSyncAccountMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncAccount *syncAccount = (SyncAccount *)[NSEntityDescription insertNewObjectForEntityForName:kSyncAccountManagedObject inManagedObjectContext:managedContext];
    return syncAccount;
}

+ (SyncNodeInfo *)createSyncNodeInfoMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncNodeInfo *syncNodeInfo = (SyncNodeInfo *)[NSEntityDescription insertNewObjectForEntityForName:kSyncNodeInfoManagedObject inManagedObjectContext:managedContext];
    return syncNodeInfo;
}

+ (SyncError *)createSyncErrorMangedObjectInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncError *syncError = (SyncError *)[NSEntityDescription insertNewObjectForEntityForName:kSyncErrorManagedObject inManagedObjectContext:managedContext];
    return syncError;
}

#pragma mark - Retrieve ManagedObjects

+ (SyncNodeInfo *)nodeInfoForObjectWithNodeId:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && syncNodeInfoId == %@", accountId, nodeId];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

+ (SyncAccount *)accountObjectForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncAccountManagedObject withPredicate:[NSPredicate predicateWithFormat:@"accountId == %@", accountId] inManagedObjectContext:managedContext];
    if (nodes.count > 0)
    {
        return nodes[0];
    }
    return nil;
}

+ (SyncError *)errorObjectForNodeWithId:(NSString *)nodeId inAccountWithId:(NSString *)accountId ifNotExistsCreateNew:(BOOL)createNew inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    SyncError *syncError = nil;
    
    if (nodeId)
    {
        SyncNodeInfo *nodeInfo = [CoreDataUtils nodeInfoForObjectWithNodeId:nodeId inAccountWithId:accountId inManagedObjectContext:managedContext];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [CoreDataUtils createSyncErrorMangedObjectInManagedObjectContext:managedContext];
            syncError.errorId = nodeId;
        }
    }
    return syncError;
}

+ (NSArray *)topLevelSyncNodesInfoForAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && isTopLevelSyncNode == YES", accountId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor] inManagedObjectContext:managedContext];
    return nodes;
}

+ (NSArray *)syncNodesInfoForFolderWithId:(NSString *)folderId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && parentNode.syncNodeInfoId == %@", accountId, folderId];
    NSSortDescriptor *titleSortDescriptor = [[NSSortDescriptor alloc] initWithKey:@"title" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate sortDescriptors:@[titleSortDescriptor] inManagedObjectContext:managedContext];
    return nodes;
}

+ (BOOL)isTopLevelSyncNode:(NSString *)nodeId inAccountWithId:(NSString *)accountId inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"account.accountId == %@ && syncNodeInfoId == %@ && isTopLevelSyncNode == YES", accountId, nodeId];
    NSArray *nodes = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject withPredicate:predicate inManagedObjectContext:managedContext];
    return nodes.count > 0;
}

#pragma mark - Debugging Dump Methods

+ (void)logAllDataInManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSArray *syncAccounts = [CoreDataUtils retrieveRecordsForTable:kSyncAccountManagedObject inManagedObjectContext:managedContext];
    for (SyncAccount *account in syncAccounts)
    {
        AlfrescoLogDebug(@"Sync Account : %@", account.accountId);
    }
    
    NSArray *nodesInfo = [CoreDataUtils retrieveRecordsForTable:kSyncNodeInfoManagedObject inManagedObjectContext:managedContext];
    
    for (SyncNodeInfo *nodeInfo in nodesInfo)
    {
        AlfrescoNode *node = [NSKeyedUnarchiver unarchiveObjectWithData:nodeInfo.node];
        AlfrescoLogDebug(@"Node Info : %@ ---  total count: %d ------- id: %@", node.name, nodesInfo.count, nodeInfo.syncNodeInfoId);
    }
}

@end
