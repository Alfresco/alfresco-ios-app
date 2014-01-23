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
}

#pragma mark - IBOutlets

- (IBAction)didPressExpandButton:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cell:didPressExpandButton:)])
    {
        [self.delegate cell:self didPressExpandButton:(UIButton *)sender];
    }
}

@end
