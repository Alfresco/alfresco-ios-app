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

#import "SearchViewController.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "SearchViewControllerDataSource.h"
#import "SearchResultsTableViewController.h"
#import "FileFolderCollectionViewController.h"
#import "PersonProfileViewController.h"
#import "AccountManager.h"
#import "SitesTableListViewController.h"

static CGFloat const kHeaderHeight = 40.0f;
static CGFloat const kCellHeightSearchScope = 64.0f;
static CGFloat const kCellHeightPreviousSearches = 44.0f;

@interface SearchViewController () < UISearchResultsUpdating, UISearchBarDelegate >

@property (nonatomic, strong) SearchViewControllerDataSource *dataSource;
@property (nonatomic) SearchViewControllerDataSourceType dataSourceType;
@property (nonatomic, strong) UISearchController *searchController;

// Services
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation SearchViewController

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType session:(id<AlfrescoSession>)session
{
    self = [super init];
    if(self)
    {
        self.dataSourceType = dataSourceType;
        self.session = session;
        self.sitesPushHandler = self;
        self.shouldHideNavigationBarOnSearchControllerPresentation = YES;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType account:[AccountManager sharedManager].selectedAccount];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:self.session];
    
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
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
        if (self.navigationController.viewControllers.firstObject == self)
        {
            self.navigationItem.leftBarButtonItem = hamburgerButtom;
        }
    }
    
    if (self.dataSource.showsSearchBar)
    {
        UIViewController *resultsController = nil;
        switch (self.dataSourceType)
        {
            case SearchViewControllerDataSourceTypeSearchSites:
            {
                resultsController = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionSearch session:self.session pushHandler:self.sitesPushHandler];
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
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;

        self.navigationController.navigationBar.translucent = YES;
        
        self.searchController.hidesNavigationBarDuringPresentation = self.shouldHideNavigationBarOnSearchControllerPresentation;
    }
}

- (void)dealloc
{
    [_searchController.view removeFromSuperview];
}

- (void)viewWillAppear:(BOOL)animated
{
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType account:[AccountManager sharedManager].selectedAccount];
    [self.tableView reloadData];
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
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            SearchViewControllerDataSourceType selectedType = indexPath.row + 1;
            SearchViewController *resultsController = [[SearchViewController alloc] initWithDataSourceType:selectedType session:self.session];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            FileFolderCollectionViewController *resultsController = [[FileFolderCollectionViewController alloc] initWithPreviousSearchString:selectedString session:self.session searchOptions:[self searchOptionsForSearchType:self.dataSourceType] emptyMessage:NSLocalizedString(@"No Files", @"No Files")];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            FileFolderCollectionViewController *resultsController = [[FileFolderCollectionViewController alloc] initWithPreviousSearchString:selectedString session:self.session searchOptions:[self searchOptionsForSearchType:self.dataSourceType] emptyMessage:NSLocalizedString(@"No Folders", @"No Folders")];
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            SitesTableListViewController *resultsController = [[SitesTableListViewController alloc] initWithType:SiteListTypeSelectionSearch session:self.session pushHandler:self.sitesPushHandler];
            [self searchSiteForString:selectedString showOnController:resultsController];
            resultsController.title = selectedString;
            [self.sitesPushHandler.navigationController pushViewController:resultsController animated:YES];
            
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            SearchResultsTableViewController *resultsController = [[SearchResultsTableViewController alloc] initWithDataType:self.dataSourceType session:self.session pushesSelection:YES];
            [self searchUserForString:selectedString showOnController:resultsController];
            resultsController.title = selectedString;
            [self.navigationController pushViewController:resultsController animated:YES];
            break;
        }
    }
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

#pragma mark - Private methods

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (AlfrescoKeywordSearchOptions *)searchOptionsForSearchType:(SearchViewControllerDataSourceType)searchType
{
    AlfrescoKeywordSearchOptions *searchOptions;
    switch (searchType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithTypeName:kAlfrescoModelTypeContent];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithTypeName:kAlfrescoModelTypeFolder];
            break;
        }
        default:
        {
            searchOptions = nil;
            break;
        }
    }
    
    return searchOptions;
}

- (void)searchFor:(NSString *)searchString
{
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            if ([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
            {
                SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
                [resultsController showHUD];

                [self.searchService searchWithKeywords:searchString options:[self searchOptionsForSearchType:self.dataSourceType] completionBlock:^(NSArray *array, NSError *error) {
                    [resultsController hideHUD];
                    
                    if (array)
                    {
                        resultsController.results = [array mutableCopy];
                    }
                    else
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
            break;
        }
        
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            if ([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
            {
                SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
                [self searchUserForString:searchString showOnController:resultsController];
            }
            break;
        }
        
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            if ([self.searchController.searchResultsController isKindOfClass:[SitesTableListViewController class]])
            {
                SitesTableListViewController *resultsController = (SitesTableListViewController *)self.searchController.searchResultsController;
                [self searchSiteForString:searchString showOnController:resultsController];
            }
            break;
        }
        
        default:
        {
            break;
        }
    }
}

- (void)searchUserForString:(NSString *)username showOnController:(SearchResultsTableViewController *)controller
{
    [controller showHUD];
    [self.personService searchWithKeywords:username completionBlock:^(NSArray *array, NSError *error) {
        [controller hideHUD];
        if (error)
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"people.picker.search.no.results", @"No Search Results"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
        else
        {
            controller.results = [array mutableCopy];
        }
    }];
}

- (void)searchSiteForString:(NSString *)searchString showOnController:(SitesTableListViewController *)controller
{
    [controller showHUD];
    [self.siteService searchWithKeywords:searchString completionBlock:^(NSArray *array, NSError *error) {
        [controller hideHUD];
        if (error)
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
        else
        {
            [controller reloadTableViewWithSearchResults:[array mutableCopy]];
        }
    }];
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
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if ([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
    {
        SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
        resultsController.results = [NSMutableArray new];
    }
    else if ([self.searchController.searchResultsController isKindOfClass:[SitesTableListViewController class]])
    {
        SitesTableListViewController *resultsController = (SitesTableListViewController *)self.searchController.searchResultsController;
        resultsController.tableViewData = [NSMutableArray new];
    }
}

- (BOOL)searchBarShouldBeginEditing:(UISearchBar *)searchBar
{
    return YES;
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
