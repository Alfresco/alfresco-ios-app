//
//  TaskGroupItem.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 21/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

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
