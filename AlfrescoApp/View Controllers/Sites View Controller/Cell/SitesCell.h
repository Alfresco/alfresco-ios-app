/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
  
@class SitesCell;
@class AlfrescoSite;

extern const CGFloat SitesCellDefaultHeight;
extern const CGFloat SitesCellExpandedHeight;

@protocol SiteCellDelegate <NSObject>

@optional
- (void)siteCell:(SitesCell *)siteCell didPressExpandButton:(UIButton *)expandButton;
- (void)siteCell:(SitesCell *)siteCell didPressFavoriteButton:(UIButton *)favoriteButton;
- (void)siteCell:(SitesCell *)siteCell didPressJoinButton:(UIButton *)joinButton;
- (void)siteCell:(SitesCell *)siteCell didPressMembersButton:(UIButton *)membersButton;

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
@property (weak, nonatomic) IBOutlet UIButton *membersButton;
@property (weak, nonatomic) IBOutlet UILabel *membersLabel;

// Public Functions
- (void)updateCellStateWithSite:(AlfrescoSite *)site;

// IBActions
- (IBAction)expandButtonPressed:(id)sender;
- (IBAction)favoriteButtonPressed:(id)sender;
- (IBAction)joinButtonPressed:(id)sender;
- (IBAction)membersButtonPressed:(id)sender;

@end
