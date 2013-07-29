//
//  CustomEGORefreshTableHeaderView.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CustomEGORefreshTableHeaderView.h"
#import "ConnectivityManager.h"

@interface CustomEGORefreshTableHeaderView ()

@property (nonatomic, assign) BOOL shouldDisplay;

@end

@implementation CustomEGORefreshTableHeaderView

- (id)initWithFrame:(CGRect)frame arrowImageName:(NSString *)arrow textColor:(UIColor *)textColor
{
    self = [super initWithFrame:frame arrowImageName:arrow textColor:textColor];
    if (self)
    {
        // register for connectivity changed notifications
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(determineShouldPullToRefresh:) name:kAlfrescoConnectivityChangedNotification object:nil];
        
        [self determineShouldPullToRefresh:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Custom Setters

- (void)setShouldDisplay:(BOOL)shouldDisplay
{
    _shouldDisplay = shouldDisplay;
    self.hidden = !shouldDisplay;
}

#pragma mark - Private Functions

- (void)determineShouldPullToRefresh:(NSNotification *)note
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        self.shouldDisplay = YES;
    }
    else
    {
        self.shouldDisplay = NO;
    }
}

#pragma EGORefreshTableHeaderView Functions

- (void)egoRefreshScrollViewDidScroll:(UIScrollView *)scrollView
{
    if (self.shouldDisplay)
    {
        [super egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)egoRefreshScrollViewDidEndDragging:(UIScrollView *)scrollView
{
    if (self.shouldDisplay)
    {
        [super egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

- (void)egoRefreshScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView
{
	[super egoRefreshScrollViewDataSourceDidFinishedLoading:scrollView];
}

@end
