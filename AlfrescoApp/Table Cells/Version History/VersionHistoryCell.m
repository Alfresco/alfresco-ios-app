//
//  VersionHistoryCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "VersionHistoryCell.h"

@implementation VersionHistoryCell

- (void)awakeFromNib
{
    [self setup];
}

- (void)setup
{
    self.metadataTableview.tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
    [self.metadataTableview layoutSubviews];
    self.disclosureImageView.image = [self.disclosureImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
}

@end
