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
    
    self.syncButton.tintColor = [UIColor appTintColor];
    self.syncButton.titleEdgeInsets = UIEdgeInsetsMake(2.0f, 0, 0, 0);
    self.syncButton.layer.cornerRadius = 4.0f;
    self.syncButton.layer.borderWidth = 1.0f;
    self.syncButton.layer.borderColor = self.syncButton.tintColor.CGColor;
    [self.syncButton setTitleColor:self.syncButton.tintColor forState:UIControlStateNormal];
    
    self.saveButton.tintColor = [UIColor appTintColor];
    self.saveButton.titleEdgeInsets = UIEdgeInsetsMake(2.0f, 0, 0, 0);
    self.saveButton.layer.cornerRadius = 4.0f;
    self.saveButton.layer.borderWidth = 1.0f;
    self.saveButton.layer.borderColor = self.saveButton.tintColor.CGColor;
    [self.saveButton setTitleColor:self.saveButton.tintColor forState:UIControlStateNormal];
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
