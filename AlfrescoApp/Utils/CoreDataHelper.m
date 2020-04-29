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

- (NSManagedObjectContext *)createChildManagedObjectContext
{
    NSManagedObjectContext *privateContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    privateContext.parentContext = self.managedObjectContext;
    return privateContext;
}

#pragma mark - Delete Records Methods

- (void)deleteRecordsWithPredicate:(NSPredicate *)predicate inTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (predicate && table)
    {
        if (!managedContext)
        {
            managedContext = self.managedObjectContext;
        }
        
        NSEntityDescription *entity = [NSEntityDescription entityForName:table inManagedObjectContext:managedContext];
        
        NSFetchRequest *fetchRequest = [[NSFetchRequest alloc] init];
        fetchRequest.entity = entity;
        fetchRequest.predicate = predicate;
        
        NSError *fetchRequestError = nil;
        NSArray *records = [managedContext executeFetchRequest:fetchRequest error:&fetchRequestError];
        
        if (fetchRequestError)
        {
            AlfrescoLogError(@"Unable to complete the fetch request for entity: %@, predicate: %@", table, predicate);
        }
        
        for (id returnedResultObject in records)
        {
            [managedContext deleteObject:returnedResultObject];
        }
        
        [self saveContextForManagedObjectContext:managedContext];
    }
}

- (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject inManagedObjectContext:(NSManagedObjectContext *)managedContext
{
    if (managedObject)
    {
        if (!managedContext)
        {
            managedContext = self.managedObjectContext;
        }
        
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
