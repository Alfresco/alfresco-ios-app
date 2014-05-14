//
//  ActivityTableViewCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@interface ActivityTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *activityImage;
@property (nonatomic, weak) IBOutlet UILabel *detailsLabel;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, assign) BOOL activityImageIsAvatar;

@end
