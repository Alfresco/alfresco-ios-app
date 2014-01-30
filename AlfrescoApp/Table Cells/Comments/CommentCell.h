//
//  CommentCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

@interface CommentCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *avatarImageView;
@property (nonatomic, weak) IBOutlet UILabel *authorTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *contentTextLabel;
@property (nonatomic, weak) IBOutlet UIImageView *speechBubbleImageView;

@end
