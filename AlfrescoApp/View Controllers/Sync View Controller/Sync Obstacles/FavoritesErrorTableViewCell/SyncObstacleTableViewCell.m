//
//  SyncObstacleTableViewCell.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 04/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncObstacleTableViewCell.h"

@implementation SyncObstacleTableViewCell

- (void)layoutSubviews
{
    [super layoutSubviews];
    if (!IS_IPAD)
    {
        // Manually override to get better button layout on iPhone, which autosizing doesn't get quite right
        CGFloat midpointX = (self.contentView.frame.size.width / 2);
        CGRect buttonFrame = self.syncButton.frame;
        buttonFrame.origin.x = midpointX - buttonFrame.size.width - 10.0f;
        [self.syncButton setFrame:buttonFrame];
        
        buttonFrame = self.saveButton.frame;
        buttonFrame.origin.x = midpointX + 10.0f;
        [self.saveButton setFrame:buttonFrame];
    }
}

#pragma mark - Button event handlers

- (IBAction)pressedSyncButton:(id)sender;
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressSyncButton:)])
    {
        [self.delegate didPressSyncButton:(UIButton *)sender];
    }
}

- (IBAction)pressedSaveToDownloads:(id)sender
{
    if (self.delegate && [self.delegate respondsToSelector:@selector(didPressSaveToDownloadsButton:)])
    {
        [self.delegate didPressSaveToDownloadsButton:(UIButton *)sender];
    }
}

@end
