//
//  ProcessTasksCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ProcessTasksCell.h"
#import "Utility.h"

static NSString * const kProcessTasksCellIdentifier = @"ProcessTasksCellIdentifier";

@interface ProcessTasksCell ()

@property (nonatomic, weak) IBOutlet UILabel *taskStatusTextLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenContentViewAndAvatarImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageViewWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenAvatarImageViewAndTextLabel;

@end

@implementation ProcessTasksCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    
    CGFloat horizonalPaddingBetweenContentViewAndAvatarImageView = self.horizonalPaddingBetweenContentViewAndAvatarImageView.constant;
    CGFloat avatarImageViewWidth = self.avatarImageViewWidth.constant;
    CGFloat horizonalPaddingBetweenAvatarImageViewAndTextLabel = self.horizonalPaddingBetweenAvatarImageViewAndTextLabel.constant;
    
    CGFloat leftPadding = horizonalPaddingBetweenContentViewAndAvatarImageView + avatarImageViewWidth + horizonalPaddingBetweenAvatarImageViewAndTextLabel;
    CGFloat rightPadding = horizonalPaddingBetweenContentViewAndAvatarImageView;
    
    self.taskStatusTextLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - (leftPadding + rightPadding);
}

#pragma mark - Public Functions

+ (NSString *)cellIdentifier
{
    return kProcessTasksCellIdentifier;
}

- (void)updateStatusLabelUsingTask:(AlfrescoWorkflowTask *)task
{
    NSString *statusString = nil;
    
    if (task.endedAt)
    {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"tasks.cell.taskcompleted", @"Task Completed"), task.assigneeIdentifier, relativeDateFromDate(task.endedAt)];
    }
    else
    {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"tasks.cell.tasknotcompleted", @"Task Not Completed"), task.assigneeIdentifier];
    }
    
    NSDictionary *attributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:self.taskStatusTextLabel.font.pointSize]};
    NSRange usernameRange = [statusString rangeOfString:task.assigneeIdentifier];
    NSRange boldRange = NSMakeRange(usernameRange.length, statusString.length - usernameRange.length);
    
    NSMutableAttributedString *test = [[NSMutableAttributedString alloc] initWithString:statusString];
    [test addAttributes:attributes range:boldRange];
    self.taskStatusTextLabel.attributedText = test;
}

@end
