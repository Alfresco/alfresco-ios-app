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
 
#import "TasksCell.h"

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
