//
//  TasksCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TasksCell.h"
#import "Utility.h"


@interface TasksCell ()
@property (nonatomic, weak) IBOutlet UIImageView *taskPriorityImageView;
@property (nonatomic, weak) IBOutlet UILabel *taskNameTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *taskDueDateTextLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *dueDateHeightConstraint;
@end

@implementation TasksCell

#pragma mark - Public Functions

- (void)setPriorityLevel:(NSNumber *)priority
{
    TaskPriority *taskPriority = [Utility taskPriorityForPriority:priority];
    self.taskPriorityImageView.image = taskPriority.image;
}

- (void)setTaskName:(NSString *)taskName
{
    self.taskNameTextLabel.text = taskName;
}

- (void)setDueDate:(NSDate *)dueDate
{
    NSString *dateString = relativeDateFromDate(dueDate);
    
    self.taskDueDateTextLabel.text = dateString;
    [self.dueDateHeightConstraint setConstant:(dateString.length == 0 ? 0 : 16.0f)];
}

- (void)setTaskOverdue:(BOOL)overdue
{
    self.taskDueDateTextLabel.textColor = overdue ? [UIColor taskOverdueLabelColor] : [UIColor textDimmedColor];
}

@end
