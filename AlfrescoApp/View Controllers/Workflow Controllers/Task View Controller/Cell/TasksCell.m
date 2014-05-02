//
//  TasksCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TasksCell.h"
#import "Utility.h"


static CGFloat const kMinimumCellHeight = 70.0f;

@interface TasksCell ()

@property (nonatomic, weak) IBOutlet UIImageView *taskPriorityImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenContentViewAndPriorityIndicator;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *priorityIndicatiorWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenPriorityIndicatorAndTextLabel;

@end

@implementation TasksCell

#pragma mark - Private Functions

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    
    CGFloat horizonalPaddingBetweenContentViewAndPriorityIndicator = self.horizonalPaddingBetweenContentViewAndPriorityIndicator.constant;
    CGFloat priorityIndicatorWidth = self.priorityIndicatiorWidth.constant;
    CGFloat horizonalPaddingBetweenPriorityIndicatorAndTextLabel = self.horizonalPaddingBetweenPriorityIndicatorAndTextLabel.constant;
    
    CGFloat leftPadding = horizonalPaddingBetweenContentViewAndPriorityIndicator + priorityIndicatorWidth + horizonalPaddingBetweenPriorityIndicatorAndTextLabel;
    CGFloat rightPadding = horizonalPaddingBetweenContentViewAndPriorityIndicator;
    
    self.taskNameTextLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - (leftPadding + rightPadding);
}

#pragma mark - Public Functions

+ (CGFloat)minimumCellHeight
{
    return kMinimumCellHeight;
}

- (void)setPriorityLevel:(NSNumber *)priority
{
    TaskPriority *taskPriority = [Utility taskPriorityForPriority:priority];
    self.taskPriorityImageView.image = [taskPriority.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.taskPriorityImageView.tintColor = taskPriority.tintColor;
}

- (void)setTaskOverdue:(BOOL)overdue
{
    self.taskDueDateTextLabel.textColor = overdue ? [UIColor taskOverdueColor] : [UIColor blackColor];
}

@end
