//
//  FileFolderCollectionViewCell.h
//  AlfrescoApp
//
//  Created by Silviu Odobescu on 26/05/15.
//  Copyright (c) 2015 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

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
@property (weak, nonatomic) IBOutlet UIButton *editButton;

+ (NSString *)cellIdentifier;
- (void)registerForNotifications;
- (void)removeNotifications;
- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite animate:(BOOL)animate;

- (void) showDeleteAction:(BOOL) showDelete animated:(BOOL)animated;

@end
