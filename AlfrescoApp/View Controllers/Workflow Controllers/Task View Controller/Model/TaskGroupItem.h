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
  
@interface TaskGroupItem : NSObject

@property (nonatomic, copy) NSString *title;
@property (nonatomic, strong) NSMutableArray *tasksBeforeFiltering;
@property (nonatomic, strong) NSMutableArray *tasksAfterFiltering;
@property (nonatomic, assign) BOOL hasMoreItems;
@property (nonatomic, strong) NSPredicate *filteringPredicate;

- (instancetype)initWithTitle:(NSString *)title filteringPredicate:(NSPredicate *)predicate;

- (void)addAndApplyFilteringToTasks:(NSArray *)tasks;
- (void)removeTasks:(NSArray *)tasks;
- (BOOL)hasDisplayableTasks;

- (NSInteger)numberOfTasksBeforeFiltering;
- (NSInteger)numberOfTasksAfterFiltering;

- (void)clearAllTasks;

@end
