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
 
#import "SitesCell.h"

const CGFloat SitesCellDefaultHeight = 64.0f;
const CGFloat SitesCellExpandedHeight = 134.0f;

@implementation SitesCell

- (void)awakeFromNib
{
    [super awakeFromNib];

    CGRect siteOptionViewFrame = self.siteOptionsContainerView.frame;
    siteOptionViewFrame.origin.y = self.contentView.frame.size.height;
    self.siteOptionsContainerView.frame = siteOptionViewFrame;
    
    self.siteOptionsContainerView.backgroundColor = [UIColor siteActionsBackgroundColor];
    [self.contentView addSubview:self.siteOptionsContainerView];
}

- (void)setAccessibilityIdentifiers
{
    self.favoriteButton.accessibilityIdentifier = kSitesCellFavoriteActionButtonIdentifier;
    self.joinButton.accessibilityIdentifier = kSitesCellMembershipActionButtonIdentifier;
    self.membersButton.accessibilityIdentifier = kSitesCellMembersButtonIdentifiers;
    self.expandButton.accessibilityIdentifier = kSitesCellDisclosureButtonIdentifier;
}

#pragma mark - Public Functions

- (void)updateCellStateWithSite:(AlfrescoSite *)site
{
    UIImage *favoriteButtonImage = nil;
    NSString *favoriteLabelText = nil;
    UIImage *joinButtonImage = nil;
    NSString *joinLabelText = nil;
    UIImage *membersButtonImage = nil;
    NSString *membersLabelText = nil;
    
    if (site.isFavorite)
    {
        favoriteButtonImage = [UIImage imageNamed:@"site-action-unfavorite.png"];
        favoriteLabelText = NSLocalizedString(@"sites.siteCell.unfavorite", @"Unfavorite");
    }
    else
    {
        favoriteButtonImage = [UIImage imageNamed:@"site-action-favorite.png"];
        favoriteLabelText = NSLocalizedString(@"sites.siteCell.favorite", @"Favorite");
    }
    
    [self.favoriteButton setImage:favoriteButtonImage forState:UIControlStateNormal];
    self.favoriteLabel.text = favoriteLabelText;
    
    if (site.isMember)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-leave.png"];
        joinLabelText = NSLocalizedString(@"sites.siteCell.leave", @"Leave");
    }
    else if (site.isPendingMember)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-cancelrequest.png"];
        joinLabelText = NSLocalizedString(@"sites.siteCell.cancel.request", @"Cancel Request");
    }
    else if (site.visibility == AlfrescoSiteVisibilityModerated)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-requesttojoin.png"];
        joinLabelText = NSLocalizedString(@"sites.siteCell.request.to.join", @"Request To Join");
    }
    else
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-join.png"];
        joinLabelText = NSLocalizedString(@"sites.siteCell.join", @"Join");
    }
    
    [self.joinButton setImage:joinButtonImage forState:UIControlStateNormal];
    self.joinLabel.text = joinLabelText;
    
    membersButtonImage = [UIImage imageNamed:@"site-action-members.png"];
    membersLabelText = NSLocalizedString(@"sites.siteCell.members", @"Members");
    
    [self.membersButton setImage:membersButtonImage forState:UIControlStateNormal];
    self.membersLabel.text = membersLabelText;
    
    [self setAccessibilityIdentifiers];
}

#pragma mark - IBActions Functions

- (IBAction)expandButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(siteCell:didPressExpandButton:)])
    {
        [self.delegate siteCell:self didPressExpandButton:(UIButton *)sender];
    }
}

- (IBAction)favoriteButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(siteCell:didPressFavoriteButton:)])
    {
        [self.delegate siteCell:self didPressFavoriteButton:(UIButton *)sender];
    }
}

- (IBAction)joinButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(siteCell:didPressJoinButton:)])
    {
        [self.delegate siteCell:self didPressJoinButton:(UIButton *)sender];
    }
}

- (IBAction)membersButtonPressed:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(siteCell:didPressMembersButton:)])
    {
        [self.delegate siteCell:self didPressMembersButton:(UIButton *)sender];
    }
}

@end
