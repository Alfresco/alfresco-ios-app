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
