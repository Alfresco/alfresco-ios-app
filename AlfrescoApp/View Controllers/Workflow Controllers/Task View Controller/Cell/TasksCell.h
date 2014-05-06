//
//  TasksCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TasksCell : UITableViewCell

- (void)setPriorityLevel:(NSNumber *)priority;
- (void)setTaskName:(NSString *)taskName;
- (void)setDueDate:(NSDate *)dueDate;
- (void)setTaskOverdue:(BOOL)overdue;

@end
