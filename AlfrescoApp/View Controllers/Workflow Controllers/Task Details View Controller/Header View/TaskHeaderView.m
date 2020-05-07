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
 
#import "TaskHeaderView.h"

static CGFloat const kCalendarCornerRadius = 10.0f;
static CGFloat const kCalendarStrokeWidth = 0.5f;

typedef NS_ENUM(NSUInteger, WorkflowPriorityType)
{
    WorkflowPriorityTypeHigh = 1,
    WorkflowPriorityTypeMedium,
    WorkflowPriorityTypeLow
};

@interface TaskHeaderView ()

@property (nonatomic, strong) NSDateFormatter *dateFormatter;

@property (nonatomic, weak) IBOutlet UIView *calendarBackgroundView;
@property (nonatomic, weak) IBOutlet UILabel *calendarMonthLabel;
@property (nonatomic, weak) IBOutlet UILabel *calendarDateLabel;
@property (nonatomic, weak) IBOutlet UILabel *taskTypeLabel;
@property (nonatomic, weak) IBOutlet UILabel *taskInitiatorLabel;
@property (nonatomic, weak) IBOutlet UIImageView *taskPriorityImageView;
@property (nonatomic, weak) IBOutlet UILabel *taskPriorityLabel;

@end

@implementation TaskHeaderView

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self commonInit];
}

#pragma mark - Private Functions

- (void)commonInit
{
    self.translatesAutoresizingMaskIntoConstraints = NO;
    self.dateFormatter = [[NSDateFormatter alloc] init];
    [self setupCalendarBackgroundView];
}

- (void)setupCalendarBackgroundView
{
    self.calendarBackgroundView.layer.cornerRadius = kCalendarCornerRadius;
    self.calendarBackgroundView.layer.borderWidth = kCalendarStrokeWidth;
    self.calendarBackgroundView.layer.borderColor = [[UIColor blackColor] CGColor];
    self.calendarBackgroundView.backgroundColor = [UIColor whiteColor];
}

- (void)setPriorityLevel:(NSNumber *)priority
{
    TaskPriority *taskPriority = [Utility taskPriorityForPriority:priority];
    self.taskPriorityImageView.image = taskPriority.image;
    self.taskPriorityLabel.text = taskPriority.summary;
}

#pragma mark - Public Functions

- (void)setTaskInitiator:(NSString *)taskInitiator
{
    _taskInitiator = taskInitiator;

    CATransition *animation = [CATransition animation];
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = kCATransitionFade;
    animation.duration = 0.3;
    [self.taskInitiatorLabel.layer addAnimation:animation forKey:@"kCATransitionFade"];
    
    self.taskInitiatorLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tasks.initiated-by", @"Initiated by"), taskInitiator];
}

- (void)updateTaskFilterLabelToString:(NSString *)taskTypeString
{
    self.taskTypeLabel.text = taskTypeString;
}

- (void)configureViewForProcess:(AlfrescoWorkflowProcess *)process
{
    if (process.dueAt)
    {
        [self.dateFormatter setDateFormat:@"MMMM"];
        self.calendarMonthLabel.text = [self.dateFormatter stringFromDate:process.dueAt];
        [self.dateFormatter setDateFormat:@"dd"];
        self.calendarDateLabel.text = [self.dateFormatter stringFromDate:process.dueAt];
    }
    else
    {
        self.calendarMonthLabel.text = NSLocalizedString(@"tasks.calendar.no-due-date", @"No Date");
        self.calendarDateLabel.text = @"";
    }
    self.taskTypeLabel.text = [Utility displayNameForProcessDefinition:process.processDefinitionIdentifier];
    // Currently no value in displaying this - it's always the current user
    self.taskInitiatorLabel.text = @"";
    [self setPriorityLevel:process.priority];
}

- (void)configureViewForTask:(AlfrescoWorkflowTask *)task
{
    if (task.dueAt)
    {
        [self.dateFormatter setDateFormat:@"MMMM"];
        self.calendarMonthLabel.text = [self.dateFormatter stringFromDate:task.dueAt];
        [self.dateFormatter setDateFormat:@"dd"];
        self.calendarDateLabel.text = [self.dateFormatter stringFromDate:task.dueAt];
    }
    else
    {
        self.calendarMonthLabel.text = NSLocalizedString(@"tasks.calendar.no-due-date", @"No Date");
        self.calendarDateLabel.text = @"";
    }
    self.taskTypeLabel.text = task.name;
    // Need to request the process details to see who initiated this task
    self.taskInitiatorLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tasks.initiated-by", @"Initiated by"), @""];
    [self setPriorityLevel:task.priority];
}

@end
