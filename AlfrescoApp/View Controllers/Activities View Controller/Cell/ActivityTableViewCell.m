//
//  ActivityTableViewCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivityTableViewCell.h"

@implementation ActivityTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.activityImage.layer.cornerRadius = self.activityImage.frame.size.width / 2;

    // Circular clipping mask for avatar?
    self.activityImage.clipsToBounds = self.activityImageIsAvatar;
}

@end
