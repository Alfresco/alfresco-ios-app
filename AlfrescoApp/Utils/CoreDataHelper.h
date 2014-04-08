//
//  CoreDataHelper.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface CoreDataHelper : NSObject

@property (nonatomic, strong, readonly) NSManagedObjectContext *managedObjectContext;

- (NSArray *)retrieveRecordsForTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSArray *)retrieveRecordsForTable:(NSString *)table withPredicate:(NSPredicate *)predicate sortDescriptors:(NSArray *)sortDescriptors inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)deleteRecordsWithPredicate:(NSPredicate *)predicate inTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)deleteRecordForManagedObject:(NSManagedObject *)managedObject inManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (void)deleteAllRecordsInTable:(NSString *)table inManagedObjectContext:(NSManagedObjectContext *)managedContext;

- (void)saveContextForManagedObjectContext:(NSManagedObjectContext *)managedContext;
- (NSManagedObjectContext *)createChildManagedObjectContext;

@end
