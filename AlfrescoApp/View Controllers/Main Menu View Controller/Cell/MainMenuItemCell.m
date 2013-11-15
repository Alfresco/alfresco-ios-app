//
//  MainMenuItemCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MainMenuItemCell.h"

@implementation MainMenuItemCell

- (void) layoutSubviews
{
    [super layoutSubviews];
    self.imageView.center = CGPointMake(25.0f, self.imageView.center.y);
}

@end
