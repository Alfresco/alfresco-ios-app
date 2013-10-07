//
//  SyncObstacleTableViewCellDelegate.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 04/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SyncObstacleTableViewCellDelegate;

@interface SyncObstacleTableViewCell : UITableViewCell

@property (nonatomic, strong) IBOutlet UILabel *fileNameTextLabel;
@property (nonatomic, strong) IBOutlet UIButton *syncButton;
@property (nonatomic, strong) IBOutlet UIButton *saveButton;
@property (nonatomic, strong) IBOutlet UIImageView *imageView;
@property (nonatomic, assign) id<SyncObstacleTableViewCellDelegate> delegate;

- (IBAction)pressedSyncButton:(id)sender;
- (IBAction)pressedSaveToDownloads:(id)sender;

@end

@protocol SyncObstacleTableViewCellDelegate <NSObject>

- (void)didPressSyncButton:(UIButton *)syncButton;
- (void)didPressSaveToDownloadsButton:(UIButton *)saveButton;

@end
