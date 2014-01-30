//
//  CommentCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CommentCell.h"

static CGFloat const kMaxiPhoneSpeechBubbleWidth = 200.0f;
static CGFloat const kMaxiPadSpeechBubbleWidth = 350.0f;

@implementation CommentCell

- (void)awakeFromNib
{
    self.contentTextLabel.preferredMaxLayoutWidth = (IS_IPAD) ? kMaxiPadSpeechBubbleWidth : kMaxiPhoneSpeechBubbleWidth;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
    self.avatarImageView.clipsToBounds = YES;
}

@end
