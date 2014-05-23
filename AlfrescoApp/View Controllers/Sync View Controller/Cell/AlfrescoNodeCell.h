//
//  AlfrescoNodeCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@class SyncNodeStatus;

@interface AlfrescoNodeCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *filename;
@property (nonatomic, weak) IBOutlet UILabel *details;
@property (nonatomic, weak) IBOutlet ThumbnailImageView *image;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;

+ (NSString *)cellIdentifier;
- (void)registerForNotifications;
- (void)removeNotifications;
- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite animate:(BOOL)animate;

@end
