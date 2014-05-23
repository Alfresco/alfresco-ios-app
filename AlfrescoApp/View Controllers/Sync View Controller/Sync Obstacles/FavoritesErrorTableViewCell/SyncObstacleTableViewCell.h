//
//  SyncObstacleTableViewCellDelegate.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 04/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailImageView.h"

@protocol SyncObstacleTableViewCellDelegate;

@interface SyncObstacleTableViewCell : UITableViewCell

@property (nonatomic, weak) IBOutlet UILabel *fileNameTextLabel;
@property (nonatomic, weak) IBOutlet UIButton *syncButton;
@property (nonatomic, weak) IBOutlet UIButton *saveButton;
@property (nonatomic, weak) IBOutlet ThumbnailImageView *thumbnail;
@property (nonatomic, assign) id<SyncObstacleTableViewCellDelegate> delegate;

- (IBAction)pressedSyncButton:(id)sender;
- (IBAction)pressedSaveToDownloads:(id)sender;

@end

@protocol SyncObstacleTableViewCellDelegate <NSObject>

- (void)didPressSyncButton:(UIButton *)syncButton;
- (void)didPressSaveToDownloadsButton:(UIButton *)saveButton;

@end
