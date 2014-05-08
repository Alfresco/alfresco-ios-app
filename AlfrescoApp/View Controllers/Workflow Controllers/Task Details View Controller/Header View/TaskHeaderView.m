//
//  TaskHeaderView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TaskHeaderView.h"
#import "Utility.h"

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
    self.taskTypeLabel.text = [Utility displayNameForProcessDefinition:task.processDefinitionIdentifier];
    // Need to request the process details to see who initiated this task
    self.taskInitiatorLabel.text = [NSString stringWithFormat:NSLocalizedString(@"tasks.initiated-by", @"Initiated by"), @""];
    [self setPriorityLevel:task.priority];
}

@end
