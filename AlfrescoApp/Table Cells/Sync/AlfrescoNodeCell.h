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

@property (nonatomic, strong) IBOutlet UILabel *filename;
@property (nonatomic, strong) IBOutlet UILabel *details;
@property (nonatomic, strong) IBOutlet ThumbnailImageView *image;
@property (nonatomic, strong) IBOutlet UIProgressView *progressBar;

- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus;
- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite;

@end
