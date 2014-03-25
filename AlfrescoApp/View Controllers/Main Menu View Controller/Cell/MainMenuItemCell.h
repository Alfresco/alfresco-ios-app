//
//  MainMenuItemCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 14/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ThumbnailImageView.h"

@interface MainMenuItemCell : UITableViewCell

@property (nonatomic, weak) IBOutlet ThumbnailImageView *menuImageView;
@property (nonatomic, weak) IBOutlet UILabel *menuTextLabel;
@property (nonatomic, weak) IBOutlet UILabel *menuAccountNameLabel;

+ (NSString *)cellIdentifier;
+ (CGFloat)minimumCellHeight;

@end
