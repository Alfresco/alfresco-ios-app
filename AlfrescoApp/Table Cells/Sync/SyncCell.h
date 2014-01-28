//
//  SyncCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 30/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"
@class SyncNodeStatus;

extern NSString * const kSyncTableCellIdentifier;

@interface SyncCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *filename;
@property (nonatomic, strong) IBOutlet UILabel *details;
@property (nonatomic, strong) IBOutlet ThumbnailImageView *image;
@property (nonatomic, strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic, strong) IBOutlet UIImageView *infoIcon1;
@property (nonatomic, strong) IBOutlet UIImageView *infoIcon2;

- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite;

@end
