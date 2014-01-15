//
//  CommentCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CommentCell.h"

@implementation CommentCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.contentView layoutSubviews];
    self.contentTextLabel.preferredMaxLayoutWidth = CGRectGetWidth(self.contentTextLabel.frame);
    self.avatarImageView.layer.cornerRadius = self.avatarImageView.frame.size.width/2;
    self.avatarImageView.clipsToBounds = YES;
}

@end
