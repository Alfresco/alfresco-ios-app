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

#import "SearchViewController.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "SearchViewControllerDataSource.h"
#import "SearchResultsTableViewController.h"
#import "FileFolderCollectionViewController.h"
#import "PersonProfileViewController.h"
#import "AccountManager.h"
#import "SitesTableListViewController.h"
#import "PreferenceManager.h"
#import "UISearchBar+Paste.h"
#import "SearchResultsTableViewDataSource.h"
#import "UIBarButtonItem+MainMenu.h"

static CGFloat const kHeaderHeight = 40.0f;
static CGFloat const kCellHeightSearchScope = 64.0f;
static CGFloat const kCellHeightPreviousSearches = 44.0f;

@interface SearchViewController () < UISearchResultsUpdating, UISearchBarDelegate, UISearchControllerDelegate>

@property (nonatomic, strong) SearchViewControllerDataSource *dataSource;
@property (nonatomic) SearchViewControllerDataSourceType dataSourceType;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic, strong) AlfrescoListingContext *listingContext;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation SearchViewController
{
    BOOL _searchResultsAreDisplayed;
}

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super init];
    if(self)
    {
        self.dataSourceType = dataSourceType;
        self.session = session;
        self.sitesPushHandler = self;
        self.shouldHideNavigationBarOnSearchControllerPresentation = YES;
        self.listingContext = listingContext;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType account:[AccountManager sharedManager].selectedAccount];
    
    [self setupScreenTitle];
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        [UIBarButtonItem setupMainMenuButtonOnViewController:self withHandler:@selector(expandRootRevealController)];
    }
    
    [self setAccessibilityIdentifiers];
    
    if (self.dataSource.showsSearchBar)
    {
        [self setupSearchController];
    }
}

- (void)dealloc
{
    [_searchController.view removeFromSuperview];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self setupDataSource];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self trackScreen];
}

#pragma mark - Analytics

- (void)trackScreen
{
    NSString *screenName = nil;
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
            screenName = kAnalyticsViewMenuSearch;
            break;
            
        case SearchViewControllerDataSourceTypeSearchFiles:
            screenName = _searchResultsAreDisplayed ? kAnalyticsViewSearchResultFiles : kAnalyticsViewSearchFiles;
            break;
            
        case SearchViewControllerDataSourceTypeSearchFolders:
            screenName = _searchResultsAreDisplayed ? kAnalyticsViewSearchResultFolders : kAnalyticsViewSearchFolders;
            break;
            
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            if ([self.sitesPushHandler isKindOfClass:[SearchViewController class]]) // Menu -> Search -> Sites
            {
                screenName = _searchResultsAreDisplayed ? kAnalyticsViewSearchResultSites : kAnalyticsViewSearchSites;
            }
        }
            break;
            
        case SearchViewControllerDataSourceTypeSearchUsers:
            screenName = _searchResultsAreDisplayed ? kAnalyticsViewSearchResultPeople : kAnalyticsViewSearchPeople;
            break;
            
        default:
            break;
    }
    
    if (screenName)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
    }
}

- (void)trackSearchEventWithAction:(NSString *)action
{
    NSString *analyticsLabel = nil;
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
            analyticsLabel = kAnalyticsEventLabelFiles;
            break;
        case SearchViewControllerDataSourceTypeSearchFolders:
            analyticsLabel = kAnalyticsEventLabelFolders;
            break;
        case SearchViewControllerDataSourceTypeSearchSites:
            analyticsLabel = kAnalyticsEventLabelSites;
            break;
        case SearchViewControllerDataSourceTypeSearchUsers:
            analyticsLabel = kAnalyticsEventLabelPeople;
            break;
        default:
            break;
    }
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySearch
                                                      action:action
                                                       label:analyticsLabel
                                                       value:@1];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.dataSource.numberOfSections;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *array = [NSArray new];
    if([[self.dataSource.dataSourceArrays objectAtIndex:section] isKindOfClass:[NSArray class]])
    {
        array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:section];
    }
    return array.count;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setSeparatorInset:UIEdgeInsetsZero];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:NSStringFromClass([self class])];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;

    NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            NSDictionary *cellDataSource = array[indexPath.row];
            cell.textLabel.text = [cellDataSource objectForKey:kCellTextKey];
            if ([cellDataSource objectForKey:kCellImageKey])
            {
                [cell.imageView setImage:[UIImage imageNamed:[cellDataSource objectForKey:kCellImageKey]]];
            }
            break;
        }
        default:
        {
            if (indexPath.section > 0)
            {
                NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
                cell.textLabel.text = array[indexPath.row];
            }
            break;
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (self.dataSourceType == SearchViewControllerDataSourceTypeLandingPage) ? kCellHeightSearchScope : kCellHeightPreviousSearches;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSString *title = self.dataSource.showsSearchBar ? ((section == 0) ? @"" : [self.dataSource.sectionHeaderStringsArray objectAtIndex:section]) : [self.dataSource.sectionHeaderStringsArray objectAtIndex:section];
    
    return title;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    CGFloat height = self.dataSource.showsSearchBar ? ((section == 0)? 0.0f : kHeaderHeight) : kHeaderHeight;
    return height;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.dataSourceType != SearchViewControllerDataSourceTypeLandingPage)
    {
        [self trackSearchEventWithAction:kAnalyticsEventActionHistory];
    }
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            SearchViewControllerDataSourceType selectedType = indexPath.row + 1;
            if(([AccountManager sharedManager].selectedAccount.accountType == UserAccountTypeCloud) && (selectedType == SearchViewControllerDataSourceTypeSearchSites))
            {
                selectedType = SearchViewControllerDataSourceTypeSearchUsers;
            }
            SearchViewController *resultsController = [[SearchViewController alloc] initWithDataSourceType:selectedType
                                                                                            listingContext:self.listingContext
                                                                                                   session:self.session];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            AlfrescoKeywordSearchOptions *options = [SearchResultsTableViewDataSource searchOptionsForSearchType:self.dataSourceType];
            FileFolderCollectionViewController *resultsController = [[FileFolderCollectionViewController alloc] initWithSearchString:selectedString
                                                                                                                       searchOptions:options
                                                                                                                        emptyMessage:NSLocalizedString(@"No Files", @"No Files")
                                                                                                                      listingContext:self.listingContext
                                                                                                                             session:self.session];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            AlfrescoKeywordSearchOptions *options = [SearchResultsTableViewDataSource searchOptionsForSearchType:self.dataSourceType];
            FileFolderCollectionViewController *resultsController = [[FileFolderCollectionViewController alloc] initWithSearchString:selectedString
                                                                                                                       searchOptions:options
                                                                                                                        emptyMessage:NSLocalizedString(@"No Folders", @"No Folders")
                                                                                                                      listingContext:self.listingContext
                                                                                                                             session:self.session];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            SitesTableListViewController *resultsController = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionSearch
                                                                                                         session:self.session
                                                                                                     pushHandler:self.sitesPushHandler
                                                                                                  listingContext:self.listingContext];
            [resultsController search:selectedString listingContext:self.listingContext];
            resultsController.title = selectedString;
            [self.sitesPushHandler.navigationController pushViewController:resultsController animated:YES];
            
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            SearchResultsTableViewController *resultsController = [[SearchResultsTableViewController alloc] initWithDataType:self.dataSourceType
                                                                                                                     session:self.session
                                                                                                             pushesSelection:YES];
            
            [resultsController search:selectedString listingContext:self.listingContext];
            resultsController.title = selectedString;
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private methods

- (void)setAccessibilityIdentifiers
{
    switch (self.dataSourceType) {
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            self.view.accessibilityIdentifier = kSearchVCSiteViewIdentifier;
            break;
        }
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            self.view.accessibilityIdentifier = kSearchVCLandingViewIdentifier;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            self.view.accessibilityIdentifier = kSearchVCFileViewIdentifier;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            self.view.accessibilityIdentifier = kSearchVCUserViewIdentifier;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            self.view.accessibilityIdentifier = kSearchVCFolderViewIdentifier;
            break;
        }
            
        default:
            break;
    }
}

- (void)setupScreenTitle
{
    NSString *title = nil;
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            title = NSLocalizedString(@"view-search-default", @"Search");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            title = NSLocalizedString(@"search.files", @"Files");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            title = NSLocalizedString(@"search.folders", @"Folders");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            title = NSLocalizedString(@"search.sites", @"Sites");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            title = NSLocalizedString(@"search.people", @"People");
            break;
        }
    }
    
    self.title = title;
}

- (void)setupSearchController
{
    UIViewController *resultsController = nil;
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            resultsController = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionSearch session:self.session pushHandler:self.sitesPushHandler listingContext:nil];
            break;
        }
        default:
        {
            resultsController = [[SearchResultsTableViewController alloc] initWithDataType:self.dataSourceType session:self.session pushesSelection:NO];
            break;
        }
    }
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
    self.searchController.searchResultsUpdater = self;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    [self.searchController.searchBar sizeToFit];
    self.searchController.delegate = self;
    self.searchController.hidesNavigationBarDuringPresentation = self.shouldHideNavigationBarOnSearchControllerPresentation;
    
    self.tableView.tableHeaderView = self.searchController.searchBar;
    self.definesPresentationContext = YES;
    self.navigationController.navigationBar.translucent = YES;
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (void)searchFor:(NSString *)searchString
{
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        case SearchViewControllerDataSourceTypeSearchFolders:
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            if ([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
            {
                SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
                resultsController.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                [resultsController search:searchString listingContext:self.listingContext];
            }
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            if ([self.searchController.searchResultsController isKindOfClass:[SitesTableListViewController class]])
            {
                SitesTableListViewController *resultsController = (SitesTableListViewController *)self.searchController.searchResultsController;
                resultsController.tableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                [resultsController search:searchString listingContext:self.listingContext];
            }
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)setupDataSource
{
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType account:[AccountManager sharedManager].selectedAccount];
    [self.tableView reloadData];
    
    if (self.dataSource.showsSearchBar && self.shouldHideNavigationBarOnSearchControllerPresentation)
    {
        self.navigationController.navigationBar.translucent = YES;
    }
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

#pragma mark - UISearchBarDelegate and UISearchResultsUpdating methods

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    /* handling of search is done in the delegate method from the search bar because this method is called for every caracter that the user types;
    see searchBarSearchButtonClicked method for implementation */
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    NSString *searchText = searchBar.text;
    NSString *strippedString = [searchText stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (strippedString.length > 0)
    {
        [self.dataSource saveSearchString:strippedString forSearchType:self.dataSourceType];
        [self searchFor:strippedString];
        [self.tableView reloadData];
    }
    
    [self trackSearchEventWithAction:kAnalyticsEventActionRunSimple];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
    {
        SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
        [resultsController clearDataSource];
    }
    else if ([self.searchController.searchResultsController isKindOfClass:[SitesTableListViewController class]])
    {
        SitesTableListViewController *resultsController = (SitesTableListViewController *)self.searchController.searchResultsController;
        [resultsController clearDataSource];
    }
    
    [self setupDataSource];
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [searchBar enableReturnKeyForPastedText:text range:range];
    
    return YES;
}

#pragma mark - UISearchControllerDelegate

- (void) willPresentSearchController:(UISearchController *)searchController
{
    _searchResultsAreDisplayed = YES;
}

- (void) willDismissSearchController:(UISearchController *)searchController
{
    _searchResultsAreDisplayed = NO;
    [self trackScreen];
}

#pragma mark - Public methods

- (void)pushDocument:(AlfrescoNode *)node contentPath:(NSString *)contentPath permissions:(AlfrescoPermissions *)permissions
{
    [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)node
                                                                   permissions:permissions
                                                                   contentFile:contentPath
                                                              documentLocation:InAppDocumentLocationFilesAndFolders
                                                                       session:self.session
                                                          navigationController:self.navigationController
                                                                      animated:YES];
}

- (void)pushFolder:(AlfrescoFolder *)node folderPermissions:(AlfrescoPermissions *)permissions
{
    // push again
    FileFolderCollectionViewController *browserViewController = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)node folderPermissions:permissions session:self.session];
    [self.navigationController pushViewController:browserViewController animated:YES];
}

- (void)pushFolderPreviewForAlfrescoFolder:(AlfrescoFolder *)node folderPermissions:(AlfrescoPermissions *)permissions
{
    [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:node
                                                                 permissions:permissions
                                                                     session:self.session
                                                        navigationController:self.navigationController
                                                                    animated:YES];
}

- (void)pushUser:(AlfrescoPerson *)person
{
    PersonProfileViewController *personProfileViewController = [[PersonProfileViewController alloc] initWithUsername:person.identifier session:self.session];
    [UniversalDevice pushToDisplayViewController:personProfileViewController usingNavigationController:self.navigationController animated:YES];
}

@end
