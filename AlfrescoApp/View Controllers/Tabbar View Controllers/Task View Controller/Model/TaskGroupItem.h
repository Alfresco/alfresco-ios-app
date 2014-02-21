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
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, assign) BOOL hasMoreItems;

- (instancetype)initWithTitle:(NSString *)title;

- (void)addTasks:(NSArray *)tasks;
- (void)removeTasks:(NSArray *)tasks;

- (BOOL)hasTasks;
- (NSInteger)numberOfTasks;

- (void)clearAllTasks;


@end
