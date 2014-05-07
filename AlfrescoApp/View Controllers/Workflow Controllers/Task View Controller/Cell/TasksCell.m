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
@property (nonatomic, weak) IBOutlet UILabel *processTypeTextLabel;
@end

@implementation TasksCell

#pragma mark - Public Functions

- (void)setPriority:(NSNumber *)priority
{
    _priority = priority;
    TaskPriority *taskPriority = [Utility taskPriorityForPriority:priority];
    self.taskPriorityImageView.image = taskPriority.image;
}

- (void)setTitle:(NSString *)title
{
    _title = title;
    self.taskNameTextLabel.text = title ?: NSLocalizedString(@"tasks.process.unnamed", @"Unnamed process");
}

- (void)setDueDate:(NSDate *)dueDate
{
    _dueDate = dueDate;
    NSString *dateString = relativeDateFromDate(dueDate);
    BOOL overdue = [dueDate timeIntervalSinceNow] < 0;
    
    self.taskDueDateTextLabel.text = dateString.length == 0 ? NSLocalizedString(@"tasks.list.no-due-date", @"No due date") : dateString;
    self.taskDueDateTextLabel.textColor = overdue ? [UIColor taskOverdueLabelColor] : [UIColor textDimmedColor];
}

- (void)setProcessType:(NSString *)processType
{
    _processType = processType;
    self.processTypeTextLabel.text = processType;
    self.processTypeTextLabel.textColor = [UIColor textDimmedColor];
}

@end
