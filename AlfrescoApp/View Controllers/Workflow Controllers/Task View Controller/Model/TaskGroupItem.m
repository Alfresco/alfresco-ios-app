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
 
#import "TaskGroupItem.h"

@implementation TaskGroupItem

- (instancetype)initWithTitle:(NSString *)title filteringPredicate:(NSPredicate *)predicate
{
    self = [self init];
    if (self)
    {
        self.title = title;
        self.tasksBeforeFiltering = [NSMutableArray array];
        self.tasksAfterFiltering = [NSMutableArray array];
        self.hasMoreItems = NO;
        self.filteringPredicate = predicate;
    }
    return self;
}

- (void)addAndApplyFilteringToTasks:(NSArray *)tasks;
{
    [self.tasksBeforeFiltering addObjectsFromArray:tasks];

    NSArray *filteredTasks = [self.tasksBeforeFiltering filteredArrayUsingPredicate:self.filteringPredicate];
    
    // Primary sort: priority
    NSSortDescriptor *prioritySortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"priority" ascending:YES];
    
    // Seconday sort: due date
    NSSortDescriptor *dueDateSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"dueAt" ascending:NO comparator:^NSComparisonResult(NSDate *obj1, NSDate *obj2) {
        // Note reversed logic here along with "ascending:NO" to get nil dates sorted to the bottom
        return [obj2 compare:obj1];
    }];
    
    self.tasksAfterFiltering = [[filteredTasks sortedArrayUsingDescriptors:@[prioritySortDescriptor, dueDateSortDescriptor]] mutableCopy];
}

- (void)removeTasks:(NSArray *)tasks
{
    [self.tasksBeforeFiltering removeObjectsInArray:tasks];
    [self.tasksAfterFiltering removeObjectsInArray:tasks];
}

- (BOOL)hasDisplayableTasks
{
    return (self.tasksAfterFiltering.count > 0);
}

- (NSInteger)numberOfTasksBeforeFiltering
{
    return self.tasksBeforeFiltering.count;
}

- (NSInteger)numberOfTasksAfterFiltering
{
    return self.tasksAfterFiltering.count;
}

- (void)clearAllTasks
{
    [self.tasksBeforeFiltering removeAllObjects];
    [self.tasksAfterFiltering removeAllObjects];
}

@end
