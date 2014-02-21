//
//  TasksCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 17/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TasksCell.h"
#import "UIColor+Custom.h"

static CGFloat const kMinimumCellHeight = 70.0f;

@interface TasksCell ()

@property (nonatomic, weak) IBOutlet UIView *taskPriorityView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenContentViewAndPriorityIndicator;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *priorityIndicatiorWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenPriorityIndicatorAndTextLabel;

@end

@implementation TasksCell

#pragma mark - Private Functions

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    UIColor *test = self.taskPriorityView.backgroundColor;
    
    [super setSelected:selected animated:animated];
    
    self.taskPriorityView.backgroundColor = test;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    self.taskPriorityView.layer.cornerRadius = self.taskPriorityView.frame.size.width/2;
    
    CGFloat horizonalPaddingBetweenContentViewAndPriorityIndicator = self.horizonalPaddingBetweenContentViewAndPriorityIndicator.constant;
    CGFloat priorityIndicatiorWidth = self.priorityIndicatiorWidth.constant;
    CGFloat horizonalPaddingBetweenPriorityIndicatorAndTextLabel = self.horizonalPaddingBetweenPriorityIndicatorAndTextLabel.constant;
    
    CGFloat leftPadding = horizonalPaddingBetweenContentViewAndPriorityIndicator + priorityIndicatiorWidth + horizonalPaddingBetweenPriorityIndicatorAndTextLabel;
    CGFloat rightPadding = horizonalPaddingBetweenContentViewAndPriorityIndicator;
    
    self.taskNameTextLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - (leftPadding + rightPadding);
}

#pragma mark - Public Functions

+ (CGFloat)minimumCellHeight
{
    return kMinimumCellHeight;
}

- (void)setPriorityLevel:(NSNumber *)priorty
{
    NSInteger priorityValue = priorty.integerValue;
    
    UIColor *priortyColour = nil;
    
    switch (priorityValue) {
        case 1:
            priortyColour = [UIColor highWorkflowPriorityColor];
            break;
            
        case 2:
            priortyColour = [UIColor mediumWorkflowPriorityColor];
            break;
        case 3:
            priortyColour = [UIColor lowWorkflowPriorityColor];
            break;
            
        default:
            break;
    }
    
    self.taskPriorityView.backgroundColor = priortyColour;
}

@end
