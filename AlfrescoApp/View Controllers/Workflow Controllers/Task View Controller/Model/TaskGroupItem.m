//
//  TaskGroupItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 21/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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
