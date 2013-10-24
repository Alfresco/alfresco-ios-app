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

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) NSString *nodeDetails;
@property (nonatomic, assign) BOOL isFavorite;

@property (nonatomic, strong) IBOutlet UILabel *filename;
@property (nonatomic, strong) IBOutlet UIView *detailsView;
@property (nonatomic, strong) IBOutlet UILabel *details;
@property (nonatomic, strong) IBOutlet UILabel *serverName;
@property (nonatomic, strong) IBOutlet ThumbnailImageView *image;
@property (nonatomic, strong) IBOutlet UIProgressView *progressBar;
@property (nonatomic, strong) IBOutlet UIImageView *status;
@property (nonatomic, strong) IBOutlet UIImageView *favoriteIcon;

- (void)updateFavoriteState:(BOOL)isFavorite;
- (void)updateNodeDetails:(SyncNodeStatus *)nodeStatus;
- (void)updateCellWithNodeStatus:(SyncNodeStatus *)nodeStatus propertyChanged:(NSString *)propertyChanged;

@end
