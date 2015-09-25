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

CGFloat kSegmentHorizontalPadding = 10.0f;
CGFloat kSegmentVerticalPadding = 10.0f;
CGFloat kSegmentControllerHeight = 40.0f;

typedef NS_ENUM(NSInteger, SiteListTypeSelection)
{
    SiteListTypeSelectionFavouriteSites = 0,
    SiteListTypeSelectionMySites,
    SiteListTypeSelectionAllSites
};

@interface SitesViewController ()

@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UIView *containerView;
@property (nonatomic, assign) SitesListViewFilter sitesFilter;
@property (nonatomic, assign) SiteListTypeSelection selectedListType;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;

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
    segment.frame = CGRectMake((view.frame.origin.x + (kSegmentHorizontalPadding / 2)),
                               (view.frame.origin.y + kSegmentVerticalPadding),
                               view.frame.size.width - kSegmentVerticalPadding,
                               kSegmentControllerHeight - kSegmentVerticalPadding);
    [segment addTarget:self action:@selector(loadSitesForSelectedSegment:) forControlEvents:UIControlEventValueChanged];
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segment.selectedSegmentIndex = [self selectionTypeForFilter:self.sitesFilter];
    self.selectedListType = segment.selectedSegmentIndex;
    self.segmentedControl = segment;
    [view addSubview:self.segmentedControl];
    
    // create and configure the table view
    BOOL shouldHideSegmentControl = (self.sitesFilter != SitesListViewFilterNoFilter);
    CGFloat containerOrigin = view.frame.origin.y + kSegmentControllerHeight;
    CGFloat containerHeight = view.frame.size.height - kSegmentControllerHeight;
    
    if (shouldHideSegmentControl)
    {
        containerOrigin = view.frame.origin.y;
        containerHeight = view.frame.size.height;
    }
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(view.frame.origin.x, containerOrigin, view.frame.size.width, containerHeight)];
    self.containerView = containerView;
    [view addSubview:self.containerView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.session)
    {
        //load data
//        [self showHUD];
//        [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error)
//         {
//             [self hideHUD];
//             [self reloadTableViewWithPagingResult:pagingResult error:error];
//         }];
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

@end
