//
//  CoreDataHelper.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "CoreDataHelper.h"

@interface CoreDataHelper ()

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;

@end

@implementation CoreDataHelper

#pragma mark - Fetch Methods

- (NSArray *)retrieveRecordsForTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
	return [self retrieveRecordsForTable:table withPredicate:nil sortDescriptors:nil inManagedObjectContext:managedContext];
}

- (NSArray *)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    return [self retrieveRecordsForTable:table withPredicate:predicate sortDescriptors:nil inManagedObjectContext:managedContext];
}

- (NSArray *)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:managedContext];
	
	NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
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

- (NSManagedObjectContext *)createPrivateManagedObjectContext
{
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = self.managedObjectContext;
    return privateContext;
}

#pragma mark - Delete Records Methods

- (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (managedObject)
    {
        [managedContext deleteObject:managedObject];
        [self saveContextForManagedObjectContext:managedContext];
    }
}

- (void)deleteAllRecordsInTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext
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

- (void)saveContextForManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    NSManagedObjectContext *mainManagedObjectContext = managedContext.parentContext;
    
    if (managedContext == self.managedObjectContext)
    {
        NSError *error = nil;
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

@end
