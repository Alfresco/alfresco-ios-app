//
//  SitesCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SitesCell.h"

const CGFloat SitesCellDefaultHeight = 46.0f;
const CGFloat SitesCellExpandedHeight = 86.0f;

@implementation SitesCell

- (void)awakeFromNib
{
    CGRect siteOptionViewFrame = self.siteOptionsContainerView.frame;
    siteOptionViewFrame.origin.y = self.contentView.frame.size.height;
    self.siteOptionsContainerView.frame = siteOptionViewFrame;
    
    UIImage *blackButtonImage = [[UIImage imageNamed:@"black-cell-action-button.png"] stretchableImageWithLeftCapWidth:5 topCapHeight:5];
    [self.favoriteButton setBackgroundImage:blackButtonImage forState:UIControlStateNormal];
    [self.joinButton setBackgroundImage:blackButtonImage forState:UIControlStateNormal];
    
    UIImage *backgroundImage = [[UIImage imageNamed:@"cell-actions-inner-shadow.png"] stretchableImageWithLeftCapWidth:0 topCapHeight:0];
    UIImageView *backgroundView = [[UIImageView alloc] initWithImage:backgroundImage];
    backgroundView.alpha = 0.6;
    backgroundView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    backgroundView.frame = CGRectMake(0, 0, self.siteOptionsContainerView.frame.size.width, self.siteOptionsContainerView.frame.size.height);
    [self.siteOptionsContainerView addSubview:backgroundView];
    [self.siteOptionsContainerView sendSubviewToBack:backgroundView];
    
    [self.contentView addSubview:self.siteOptionsContainerView];
}

#pragma mark - Public Functions

- (void)updateCellStateWithSite:(AlfrescoSite *)site
{
    UIImage *favoriteButtonImage = nil;
    NSString *favoriteButtonText = nil;
    UIImage *joinButtonImage = nil;
    NSString *joinButtonText = nil;
    
    if (site.isFavorite)
    {
        favoriteButtonImage = [UIImage imageNamed:@"site-action-unfavorite.png"];
        favoriteButtonText = NSLocalizedString(@"sites.siteCell.unfavorite", @"Unfavorite");
    }
    else
    {
        favoriteButtonImage = [UIImage imageNamed:@"site-action-favorite.png"];
        favoriteButtonText = NSLocalizedString(@"sites.siteCell.favorite", @"Favorite");
    }
    
    [self.favoriteButton setImage:favoriteButtonImage forState:UIControlStateNormal];
    [self.favoriteButton setTitle:favoriteButtonText forState:UIControlStateNormal];
    
    if (site.isMember)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-leave.png"];
        joinButtonText = NSLocalizedString(@"sites.siteCell.leave", @"Leave");
    }
    else if (site.isPendingMember)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-cancelrequest.png"];
        joinButtonText = NSLocalizedString(@"sites.siteCell.cancel.request", @"Cancel Request");
    }
    else if (site.visibility == AlfrescoSiteVisibilityModerated)
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-requesttojoin.png"];
        joinButtonText = NSLocalizedString(@"sites.siteCell.request.to.join", @"Request To Join");
    }
    else
    {
        joinButtonImage = [UIImage imageNamed:@"site-action-join.png"];
        joinButtonText = NSLocalizedString(@"sites.siteCell.join", @"Join");
    }
    
    [self.joinButton setImage:joinButtonImage forState:UIControlStateNormal];
    [self.joinButton setTitle:joinButtonText forState:UIControlStateNormal];
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
