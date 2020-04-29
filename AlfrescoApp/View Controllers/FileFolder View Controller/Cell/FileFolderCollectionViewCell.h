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

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"
#import "CollectionViewProtocols.h"

@class SyncNodeStatus;

@interface FileFolderCollectionViewCell : UICollectionViewCell

@property (nonatomic, weak) IBOutlet UILabel *filename;
@property (nonatomic, weak) IBOutlet UILabel *details;
@property (nonatomic, weak) IBOutlet ThumbnailImageView *image;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;
@property (nonatomic, weak) IBOutlet UIView *accessoryView;
@property (nonatomic, weak) IBOutlet UIView *actionsView;
@property (nonatomic, weak) IBOutlet UIView *editView;
@property (weak, nonatomic) IBOutlet UIButton *deleteButton;
@property (weak, nonatomic) IBOutlet UIImageView *editImageView;
@property (weak, nonatomic) IBOutlet UIView *content;
@property (weak, nonatomic) IBOutlet UIView *separatorView;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *separatorHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *actionsViewWidthContraint;

@property (nonatomic, strong) AlfrescoNode *node;

@property (nonatomic, weak) id<CollectionViewCellAccessoryViewDelegate> accessoryViewDelegate;

+ (NSString *)cellIdentifier;
- (void)registerForNotifications;
- (void)removeNotifications;
- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsFavoriteNode:(BOOL)isFavorite isSyncNode:(BOOL)isSyncNode isTopLevelSyncNode:(BOOL)isTopLevelSyncNode animate:(BOOL)animate;

- (void) showDeleteAction:(BOOL)showDelete animated:(BOOL)animated;
- (void) revealActionViewWithAmount:(CGFloat)amount;
- (void) resetView;
- (void) showEditMode:(BOOL)showEdit animated:(BOOL)animated;
- (void) showEditMode:(BOOL)showEdit selected:(BOOL)isSelected animated:(BOOL)animated;
- (void) wasSelectedInEditMode:(BOOL)wasSelected;

@end
