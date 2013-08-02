//
//  SitesCell.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SitesCell;
@class AlfrescoSite;

extern const CGFloat SitesCellDefaultHeight;
extern const CGFloat SitesCellExpandedHeight;

@protocol SiteCellDelegate <NSObject>

@optional
- (void)siteCell:(SitesCell *)siteCell didPressExpandButton:(UIButton *)expandButton;
- (void)siteCell:(SitesCell *)siteCell didPressFavoriteButton:(UIButton *)favoriteButton;
- (void)siteCell:(SitesCell *)siteCell didPressJoinButton:(UIButton *)joinButton;

@end

@interface SitesCell : UITableViewCell

@property (nonatomic, weak) id<SiteCellDelegate> delegate;
@property (nonatomic, strong) IBOutlet UIImageView *siteImageView;
@property (nonatomic, strong) IBOutlet UILabel *siteNameLabelView;
@property (nonatomic, strong) IBOutlet UIButton *expandButton;
@property (nonatomic, strong) IBOutlet UIButton *favoriteButton;
@property (nonatomic, strong) IBOutlet UIButton *joinButton;
@property (nonatomic, strong) IBOutlet UIView *siteOptionsContainerView;

// Public Functions
- (void)updateCellStateWithSite:(AlfrescoSite *)site;

// IBActions
- (IBAction)expandButtonPressed:(id)sender;
- (IBAction)favoriteButtonPressed:(id)sender;
- (IBAction)joinButtonPressed:(id)sender;

@end
