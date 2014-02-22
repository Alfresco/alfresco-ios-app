//
//  TaskGroupItem.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 21/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TaskGroupItem.h"

@implementation TaskGroupItem

- (instancetype)initWithTitle:(NSString *)title
{
    self = [self init];
    if (self)
    {
        self.title = title;
        self.tasks = [NSMutableArray array];
        self.hasMoreItems = NO;
    }
    return self;
}

- (BOOL)hasTasks
{
    return ([self numberOfTasks] > 0);
}

- (NSInteger)numberOfTasks
{
    return self.tasks.count;
}

- (void)clearAllTasks
{
    [self.tasks removeAllObjects];
}

- (void)addTasks:(NSArray *)tasks
{
    [self.tasks addObjectsFromArray:tasks];
}
- (void)removeTasks:(NSArray *)tasks
{
    [self.tasks removeObjectsInArray:tasks];
}

@end
