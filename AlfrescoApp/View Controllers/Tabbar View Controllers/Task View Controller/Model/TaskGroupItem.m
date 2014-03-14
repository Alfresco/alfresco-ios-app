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
    self.tasksAfterFiltering = [[self.tasksBeforeFiltering filteredArrayUsingPredicate:self.filteringPredicate] mutableCopy];
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
