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

#import "SitesViewController.h"
#import "SitesTableListViewController.h"
#import "AccountManager.h"
#import "SearchViewController.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "UIBarButtonItem+MainMenu.h"

static CGFloat const kSegmentToSearchControlPadding = 8.0f;

@interface SitesViewController ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *favoritesContainerView;
@property (nonatomic, strong) UIView *mySitesContainerView;
@property (nonatomic, strong) UIView *siteFinderContainerView;
@property (nonatomic, assign) SitesListViewFilter sitesFilter;
@property (nonatomic, assign) SiteListTypeSelection selectedListType;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;
@property (nonatomic, assign, getter=isActiveAccountOnPremise) BOOL activeAccountOnPremise;

@property (nonatomic, strong) SitesTableListViewController *favoritesVC;
@property (nonatomic, strong) SitesTableListViewController *mySitesVC;
@property (nonatomic, strong) SitesTableListViewController *allSitesVC;
@property (nonatomic, strong) SearchViewController *searchVC;

@end

@implementation SitesViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.title = NSLocalizedString(@"sites.title", @"Sites Title");
        self.activeAccountOnPremise = [AccountManager sharedManager].selectedAccount.accountType == UserAccountTypeOnPremise;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionRefreshed:)
                                                     name:kAlfrescoSessionRefreshedNotification
                                                   object:nil];
    }
    return self;
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session listingContext:(AlfrescoListingContext *)listingContext
{
    self = [self initWithSession:session];
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    return self;
}

- (instancetype)initWithSitesListFilter:(SitesListViewFilter)filter title:(NSString *)title session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.sitesFilter = filter;
        self.selectedListType = [self selectionTypeForFilter:filter];
        if (title)
        {
            self.title = title;
        }
    }
    return self;
}

- (instancetype)initWithSitesListFilter:(SitesListViewFilter)filter title:(NSString *)title session:(id<AlfrescoSession>)session listingContext:(AlfrescoListingContext *)listingContext
{
    self = [self initWithSitesListFilter:filter title:title session:session];
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    
    NSString *thirdSegmentLabel = self.isActiveAccountOnPremise ? NSLocalizedString(@"sites.segmentControl.sitefinder", @"Site Finder") : NSLocalizedString(@"sites.segmentControl.allsites", @"All Sites");
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[
                                                                              NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites"),
                                                                              NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites"),
                                                                              thirdSegmentLabel]];
    segment.frame = CGRectMake((view.frame.origin.x + (kUISegmentControlHorizontalPadding / 2)),
                               (view.frame.origin.y + kUISegmentControlVerticalPadding),
                               view.frame.size.width - kUISegmentControlVerticalPadding,
                               kUISegmentControllerHeight - kUISegmentControlVerticalPadding);
    [segment addTarget:self action:@selector(loadSitesForSelectedSegment:) forControlEvents:UIControlEventValueChanged];
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segment.selectedSegmentIndex = [self selectionTypeForFilter:self.sitesFilter];
    self.selectedListType = segment.selectedSegmentIndex;
    self.segmentedControl = segment;
    [view addSubview:self.segmentedControl];
    
    // Create and configure the table view
    BOOL shouldHideSegmentControl = (self.sitesFilter != SitesListViewFilterNoFilter);
    CGFloat containerOrigin = view.frame.origin.y + kUISegmentControllerHeight;
    CGFloat containerHeight = view.frame.size.height - kUISegmentControllerHeight;
    
    if (shouldHideSegmentControl)
    {
        containerOrigin = view.frame.origin.y;
        containerHeight = view.frame.size.height;
    }
    
    CGRect containerViewFrame = CGRectMake(view.frame.origin.x, containerOrigin, view.frame.size.width, containerHeight);
    
    self.favoritesContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    self.favoritesContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self.favoritesContainerView];
    
    self.mySitesContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    self.mySitesContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self.mySitesContainerView];
    
    self.siteFinderContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    self.siteFinderContainerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self.siteFinderContainerView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.favoritesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionFavouriteSites session:self.session pushHandler:self listingContext:self.defaultListingContext];
    self.favoritesVC.view.frame = self.favoritesContainerView.bounds;
    [self.favoritesContainerView addSubview:self.favoritesVC.view];
    [self addChildViewController:self.favoritesVC];
    [self.favoritesVC didMoveToParentViewController:self];
    
    self.mySitesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionMySites session:self.session pushHandler:self listingContext:self.defaultListingContext];
    self.mySitesVC.view.frame = self.mySitesContainerView.bounds;
    [self.mySitesContainerView addSubview:self.mySitesVC.view];
    [self addChildViewController:self.mySitesVC];
    [self.mySitesVC didMoveToParentViewController:self];
    
    if (self.isActiveAccountOnPremise)
    {
        self.searchVC = [[SearchViewController alloc] initWithDataSourceType:SearchViewControllerDataSourceTypeSearchSites listingContext:nil session:self.session];
        self.searchVC.sitesPushHandler = self;
        self.searchVC.shouldHideNavigationBarOnSearchControllerPresentation = NO;
        
        // Add some spacing between UISegmentControl and search control
        CGRect siteFinderRect = CGRectInset(self.siteFinderContainerView.bounds, 0, kSegmentToSearchControlPadding);
        self.searchVC.view.frame = siteFinderRect;
        
        [self.siteFinderContainerView addSubview:self.searchVC.view];
        [self addChildViewController:self.searchVC];
        [self.searchVC didMoveToParentViewController:self];
    }
    else
    {
        self.allSitesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionAllSites session:self.session pushHandler:self listingContext:self.defaultListingContext];
        self.allSitesVC.view.frame = self.siteFinderContainerView.bounds;
        [self.siteFinderContainerView addSubview:self.allSitesVC.view];
        [self addChildViewController:self.allSitesVC];
        [self.allSitesVC didMoveToParentViewController:self];
    }
    
    [self setAccessibilityIdentifiers];
    
    [self loadSitesForSelectedSegment:self.segmentedControl];
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        [UIBarButtonItem setupMainMenuButtonOnViewController:self withHandler:@selector(expandRootRevealController)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewMenuSites];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kSitesVCViewIdentifier;
    self.segmentedControl.accessibilityIdentifier = kSitesVCSegmentedControlIdentifier;
}

- (SiteListTypeSelection)selectionTypeForFilter:(SitesListViewFilter)filter
{
    SiteListTypeSelection returnSelectionType;
    
    switch (filter)
    {
        case SitesListViewFilterNoFilter:
            returnSelectionType = self.selectedListType;
            break;
            
        case SitesListViewFilterFavouriteSites:
            returnSelectionType = SiteListTypeSelectionFavouriteSites;
            break;
            
        case SitesListViewFilterMySites:
            returnSelectionType = SiteListTypeSelectionMySites;
            break;
            
        case SitesListViewFilterAllSites:
            returnSelectionType = SiteListTypeSelectionAllSites;
            break;
    }
    
    return returnSelectionType;
}

- (void)loadSitesForSelectedSegment:(id)sender
{
    self.selectedListType = (SiteListTypeSelection)self.segmentedControl.selectedSegmentIndex;
    
    switch (self.segmentedControl.selectedSegmentIndex)
    {
        case 0:
        {
            self.favoritesContainerView.hidden = NO;
            self.mySitesContainerView.hidden = YES;
            self.siteFinderContainerView.hidden = YES;
            [self.view bringSubviewToFront:self.favoritesContainerView];
            
            [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSiteListingFavorites];
            
            break;
        }
        case 1:
        {
            self.favoritesContainerView.hidden = YES;
            self.mySitesContainerView.hidden = NO;
            self.siteFinderContainerView.hidden = YES;
            [self.view bringSubviewToFront:self.mySitesContainerView];
            
            [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSiteListingMy];
            
            break;
        }
        case 2:
        {
            self.favoritesContainerView.hidden = YES;
            self.mySitesContainerView.hidden = YES;
            self.siteFinderContainerView.hidden = NO;
            [self.view bringSubviewToFront:self.siteFinderContainerView];
            
            [[AnalyticsManager sharedManager] trackScreenWithName:self.isActiveAccountOnPremise ? kAnalyticsViewSiteListingSearch : kAnalyticsViewSiteListingAll];
            
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    [self.favoritesVC updateSession:self.session];
    [self.mySitesVC updateSession:self.session];
    [self.allSitesVC updateSession:self.session];
}

@end
