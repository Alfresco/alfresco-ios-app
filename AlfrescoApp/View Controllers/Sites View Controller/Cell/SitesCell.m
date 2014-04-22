//
//  SitesCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SitesCell.h"

const CGFloat SitesCellDefaultHeight = 64.0f;
const CGFloat SitesCellExpandedHeight = 134.0f;

@implementation SitesCell

- (void)awakeFromNib
{
    CGRect siteOptionViewFrame = self.siteOptionsContainerView.frame;
    siteOptionViewFrame.origin.y = self.contentView.frame.size.height;
    self.siteOptionsContainerView.frame = siteOptionViewFrame;
    
    self.siteOptionsContainerView.backgroundColor = [UIColor colorWithRed:234/255.0f green:235/255.0f blue:237/255.0f alpha:1.0f];
    [self.contentView addSubview:self.siteOptionsContainerView];
}

#pragma mark - Public Functions

- (void)updateCellStateWithSite:(AlfrescoSite *)site
{
    UIImage *favoriteButtonImage = nil;
    NSString *favoriteLabelText = nil;
    UIImage *joinButtonImage = nil;
    NSString *joinLabelText = nil;
    
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

@end
