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
 
#import "ProcessTasksCell.h"

static NSString * const kProcessTasksCellIdentifier = @"ProcessTasksCellIdentifier";

@interface ProcessTasksCell ()

@property (nonatomic, weak) IBOutlet UILabel *taskStatusTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *taskEndedAtTextLabel;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenContentViewAndAvatarImageView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *avatarImageViewWidth;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizonalPaddingBetweenAvatarImageViewAndTextLabel;

@end

@implementation ProcessTasksCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    self.taskStatusTextLabel.text = @"";
    self.taskEndedAtTextLabel.text = @"";
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView setNeedsLayout];
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width / 2;
    self.avatarImageView.clipsToBounds = YES;
    
    CGFloat horizonalPaddingBetweenContentViewAndAvatarImageView = self.horizonalPaddingBetweenContentViewAndAvatarImageView.constant;
    CGFloat avatarImageViewWidth = self.avatarImageViewWidth.constant;
    CGFloat horizonalPaddingBetweenAvatarImageViewAndTextLabel = self.horizonalPaddingBetweenAvatarImageViewAndTextLabel.constant;
    
    CGFloat leftPadding = horizonalPaddingBetweenContentViewAndAvatarImageView + avatarImageViewWidth + horizonalPaddingBetweenAvatarImageViewAndTextLabel;
    CGFloat rightPadding = horizonalPaddingBetweenContentViewAndAvatarImageView;
    
    self.taskStatusTextLabel.preferredMaxLayoutWidth = self.contentView.frame.size.width - (leftPadding + rightPadding);
    self.taskEndedAtTextLabel.textColor = [UIColor textDimmedColor];
}

#pragma mark - Public Functions

+ (NSString *)cellIdentifier
{
    return kProcessTasksCellIdentifier;
}

- (void)updateStatusLabelUsingTask:(AlfrescoWorkflowTask *)task
{
    NSString *statusString = @"";
    
    if (task.endedAt)
    {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"tasks.cell.taskcompleted", @"Task Completed"), task.assigneeIdentifier];
        self.taskEndedAtTextLabel.text = relativeDateFromDate(task.endedAt);
    }
    else
    {
        statusString = [NSString stringWithFormat:NSLocalizedString(@"tasks.cell.tasknotcompleted", @"Task Not Completed"), task.assigneeIdentifier];
        self.taskEndedAtTextLabel.text = @"";
    }
    
    NSMutableAttributedString *test = [[NSMutableAttributedString alloc] initWithString:statusString];
    
    if (task.assigneeIdentifier != nil)
    {
        NSDictionary *attributes = @{NSFontAttributeName : [UIFont boldSystemFontOfSize:self.taskStatusTextLabel.font.pointSize]};
        NSRange usernameRange = [statusString rangeOfString:task.assigneeIdentifier];
        NSRange boldRange = NSMakeRange(usernameRange.length, statusString.length - usernameRange.length);
        [test addAttributes:attributes range:boldRange];
    }
    
    self.taskStatusTextLabel.attributedText = test;
}

@end
