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
@property (nonatomic, weak) IBOutlet UIImageView *siteImageView;
@property (nonatomic, weak) IBOutlet UILabel *siteNameLabelView;
@property (nonatomic, weak) IBOutlet UIButton *expandButton;
@property (nonatomic, weak) IBOutlet UIButton *favoriteButton;
@property (nonatomic, weak) IBOutlet UIButton *joinButton;
@property (nonatomic, weak) IBOutlet UIView *siteOptionsContainerView;
@property (nonatomic, weak) IBOutlet UILabel *favoriteLabel;
@property (nonatomic, weak) IBOutlet UILabel *joinLabel;

// Public Functions
- (void)updateCellStateWithSite:(AlfrescoSite *)site;

// IBActions
- (IBAction)expandButtonPressed:(id)sender;
- (IBAction)favoriteButtonPressed:(id)sender;
- (IBAction)joinButtonPressed:(id)sender;

@end
