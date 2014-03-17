//
//  AlfrescoNodeCell.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"
@class SyncNodeStatus;

extern NSString * const kAlfrescoNodeCellIdentifier;

@interface AlfrescoNodeCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *filename;
@property (nonatomic, weak) IBOutlet UILabel *details;
@property (nonatomic, weak) IBOutlet ThumbnailImageView *image;
@property (nonatomic, weak) IBOutlet UIProgressView *progressBar;

- (void)registerForNotifications;
- (void)removeNotifications;
- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite animate:(BOOL)animate;

@end
