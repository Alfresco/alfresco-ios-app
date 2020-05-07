/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
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
