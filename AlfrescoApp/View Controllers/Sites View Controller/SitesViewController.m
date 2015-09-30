/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

CGFloat kSegmentHorizontalPaddingDuplicate = 10.0f;
CGFloat kSegmentVerticalPaddingDuplicate = 10.0f;
CGFloat kSegmentControllerHeightDuplicate = 40.0f;

@interface SitesViewController ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *favoritesContainerView;
@property (nonatomic, strong) UIView *mySitesContainerView;
@property (nonatomic, strong) UIView *siteFinderContainerView;
@property (nonatomic, assign) SitesListViewFilter sitesFilter;
@property (nonatomic, assign) SiteListTypeSelection selectedListType;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;

@property (nonatomic, strong) SitesTableListViewController *favoritesVC;
@property (nonatomic, strong) SitesTableListViewController *mySitesVC;
@property (nonatomic, strong) SitesTableListViewController *allSitesVC;
@property (nonatomic, strong) SearchViewController *searchVC;

@end

@implementation SitesViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.title = NSLocalizedString(@"sites.title", @"Sites Title");
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

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[
                                                                              NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites"),
                                                                              NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites"),
                                                                              NSLocalizedString(@"sites.segmentControl.allsites", @"All Sites")]];
    segment.frame = CGRectMake((view.frame.origin.x + (kSegmentHorizontalPaddingDuplicate / 2)),
                               (view.frame.origin.y + kSegmentVerticalPaddingDuplicate),
                               view.frame.size.width - kSegmentVerticalPaddingDuplicate,
                               kSegmentControllerHeightDuplicate - kSegmentVerticalPaddingDuplicate);
    [segment addTarget:self action:@selector(loadSitesForSelectedSegment:) forControlEvents:UIControlEventValueChanged];
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segment.selectedSegmentIndex = [self selectionTypeForFilter:self.sitesFilter];
    self.selectedListType = segment.selectedSegmentIndex;
    self.segmentedControl = segment;
    [view addSubview:self.segmentedControl];
    
    // create and configure the table view
    BOOL shouldHideSegmentControl = (self.sitesFilter != SitesListViewFilterNoFilter);
    CGFloat containerOrigin = view.frame.origin.y + kSegmentControllerHeightDuplicate;
    CGFloat containerHeight = view.frame.size.height - kSegmentControllerHeightDuplicate;
    
    if (shouldHideSegmentControl)
    {
        containerOrigin = view.frame.origin.y;
        containerHeight = view.frame.size.height;
    }
    
    CGRect containerViewFrame = CGRectMake(view.frame.origin.x, containerOrigin, view.frame.size.width, containerHeight);
    
    self.favoritesContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    [view addSubview:self.favoritesContainerView];
    
    self.mySitesContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    [view addSubview:self.mySitesContainerView];
    
    self.siteFinderContainerView = [[UIView alloc] initWithFrame:containerViewFrame];
    [view addSubview:self.siteFinderContainerView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.favoritesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionFavouriteSites session:self.session pushHandler:self];
    [self.favoritesContainerView addSubview:self.favoritesVC.view];
    [self addChildViewController:self.favoritesVC];
    [self.favoritesVC didMoveToParentViewController:self];
    
    self.mySitesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionMySites session:self.session pushHandler:self];
    [self.mySitesContainerView addSubview:self.mySitesVC.view];
    [self addChildViewController:self.mySitesVC];
    [self.mySitesVC didMoveToParentViewController:self];
    
    if([AccountManager sharedManager].selectedAccount.accountType == UserAccountTypeCloud)
    {
        self.allSitesVC = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionAllSites session:self.session pushHandler:self];
        [self.siteFinderContainerView addSubview:self.allSitesVC.view];
        [self addChildViewController:self.allSitesVC];
        [self.allSitesVC didMoveToParentViewController:self];
    }
    else
    {
        self.searchVC = [[SearchViewController alloc] initWithDataSourceType:SearchViewControllerDataSourceTypeSearchSites session:self.session];
        self.searchVC.sitesPushHandler = self;
        self.searchVC.shouldHideNavigationBarOnSearchControllerPresentation = NO;
        self.searchVC.view.frame = self.siteFinderContainerView.bounds;
        [self.siteFinderContainerView addSubview:self.searchVC.view];
        [self addChildViewController:self.searchVC];
        [self.searchVC didMoveToParentViewController:self];
    }
    
    if (self.session)
    {
        [self loadSitesForSelectedSegment:self.segmentedControl];
    }
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
        if (self.navigationController.viewControllers.firstObject == self)
        {
            self.navigationItem.leftBarButtonItem = hamburgerButtom;
        }
    }
}

#pragma mark - Private methods
- (SiteListTypeSelection)selectionTypeForFilter:(SitesListViewFilter)filter
{
    SiteListTypeSelection returnSelectionType;
    
    switch (filter)
    {
        case SitesListViewFilterNoFilter:
        {
            returnSelectionType = self.selectedListType;
        }
            break;
            
        case SitesListViewFilterFavouriteSites:
        {
            returnSelectionType = SiteListTypeSelectionFavouriteSites;
        }
            break;
            
        case SitesListViewFilterMySites:
        {
            returnSelectionType = SiteListTypeSelectionMySites;
        }
            break;
            
        case SitesListViewFilterAllSites:
        {
            returnSelectionType = SiteListTypeSelectionAllSites;
        }
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
            break;
        }
        case 1:
        {
            self.favoritesContainerView.hidden = YES;
            self.mySitesContainerView.hidden = NO;
            self.siteFinderContainerView.hidden = YES;
            [self.view bringSubviewToFront:self.mySitesContainerView];
            break;
        }
        case 2:
        {
            self.favoritesContainerView.hidden = YES;
            self.mySitesContainerView.hidden = YES;
            self.siteFinderContainerView.hidden = NO;
            [self.view bringSubviewToFront:self.siteFinderContainerView];
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

@end
