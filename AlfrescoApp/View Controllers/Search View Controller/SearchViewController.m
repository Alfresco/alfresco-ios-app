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
#import "SearchTableViewCell.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "SearchViewControllerDataSource.h"
#import "SearchResultsTableViewController.h"
#import "FileFolderCollectionViewController.h"


static CGFloat const kHeaderHeight = 40.0f;

@interface SearchViewController () < UISearchResultsUpdating, UISearchBarDelegate >

@property (nonatomic, strong) SearchViewControllerDataSource *dataSource;
@property (nonatomic) SearchViewControllerDataSourceType dataSourceType;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) CGRect searchBarOriginalFrame;
// Searvices
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) AlfrescoPersonService *personService;
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
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
    self.personService = [[AlfrescoPersonService alloc] initWithSession:self.session];
    
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
    
    if(self.dataSource.showsSearchBar)
    {
        SearchResultsTableViewController *resultsController = [[SearchResultsTableViewController alloc] init];
        resultsController.dataType = self.dataSourceType;
        resultsController.session = self.session;
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:resultsController];
        self.searchController.searchResultsUpdater = self;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.searchController.searchBar sizeToFit];
        self.tableView.tableHeaderView = self.searchController.searchBar;
        self.definesPresentationContext = YES;
    }
    
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([SearchTableViewCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:NSStringFromClass([SearchTableViewCell class])];
    
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (self.dataSourceType)
    {
        case SearchViewControllerDataSourceTypeLandingPage:
        {
            SearchTableViewCell *specificCell = [tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchTableViewCell class]) forIndexPath:indexPath];
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSDictionary *cellDataSource = array[indexPath.row];
            specificCell.searchItemText.text = [cellDataSource objectForKey:kCellTextKey];
            if([cellDataSource objectForKey:kCellImageKey])
            {
                [specificCell.searchItemImage setImage:[UIImage imageNamed:[cellDataSource objectForKey:kCellImageKey]]];
                specificCell.searchItemImageWidthConstraint.constant = kSearchItemImageWidthConstraint;
            }
            else
            {
                specificCell.searchItemImageWidthConstraint.constant = 0.0f;
            }
            cell = specificCell;
            
            break;
        }
        default:
        {
            if(indexPath.section > 0)
            {
                cell = [self configureCellForIndexPath:indexPath];
            }
            break;
        }
    }
    
    return cell;
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
            SearchViewController *newVC = [[SearchViewController alloc] initWithDataSourceType:selectedType session:self.session];
            [UniversalDevice pushToDisplayViewController:newVC usingNavigationController:self.navigationController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            FileFolderCollectionViewController *vc = [[FileFolderCollectionViewController alloc] initWithPreviousSearchString:selectedString session:self.session searchOptions:[self searchOptionsForSearchType:self.dataSourceType] emptyMessage:NSLocalizedString(@"No Files", @"No Files")];
            [UniversalDevice pushToDisplayViewController:vc usingNavigationController:self.navigationController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
            NSString *selectedString = [array objectAtIndex:indexPath.row];
            FileFolderCollectionViewController *vc = [[FileFolderCollectionViewController alloc] initWithPreviousSearchString:selectedString session:self.session searchOptions:[self searchOptionsForSearchType:self.dataSourceType] emptyMessage:NSLocalizedString(@"No Folders", @"No Folders")];
            [UniversalDevice pushToDisplayViewController:vc usingNavigationController:self.navigationController animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            break;
        }
    }
}

#pragma mark - Private methods

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (SearchTableViewCell *) configureCellForIndexPath:(NSIndexPath *)indexPath
{
    SearchTableViewCell *specificCell = [self.tableView dequeueReusableCellWithIdentifier:NSStringFromClass([SearchTableViewCell class]) forIndexPath:indexPath];
    NSArray *array = (NSArray *)[self.dataSource.dataSourceArrays objectAtIndex:indexPath.section];
    specificCell.searchItemText.text = array[indexPath.row];
    specificCell.searchItemImageWidthConstraint.constant = 0.0f;
    return specificCell;
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
            [self.searchService searchWithKeywords:searchString options:[self searchOptionsForSearchType:self.dataSourceType] completionBlock:^(NSArray *array, NSError *error) {
                if (array)
                {
                    if([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
                    {
                        SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
                        resultsController.results = [array mutableCopy];
                    }
                }
                else
                {
                    // display error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            [self.personService searchWithKeywords:searchString completionBlock:^(NSArray *array, NSError *error) {
                if (error)
                {
                    // display error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"people.picker.search.no.results", @"No Search Results"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    if([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
                    {
                        SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
                        resultsController.results = [array mutableCopy];
                    }
                }
            }];
            break;
        }
        default:
        {
            break;
        }
    }
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
    
    if(strippedString.length > 0)
    {
        [self.dataSource saveSearchString:strippedString forSearchType:self.dataSourceType];
        [self searchFor:strippedString];
        [self.tableView reloadData];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    if([self.searchController.searchResultsController isKindOfClass:[SearchResultsTableViewController class]])
    {
        SearchResultsTableViewController *resultsController = (SearchResultsTableViewController *)self.searchController.searchResultsController;
        resultsController.results = [NSMutableArray new];
    }
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
    [UniversalDevice pushToDisplayViewController:browserViewController usingNavigationController:self.navigationController animated:YES];
}
@end
