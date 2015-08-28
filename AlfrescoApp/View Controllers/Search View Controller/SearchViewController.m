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
#import "SearchTableViewHeader.h"

static CGFloat const kHeaderHeight = 40.0f;

@interface SearchViewController () < UISearchResultsUpdating, UISearchBarDelegate >

@property (nonatomic, strong) SearchViewControllerDataSource *dataSource;
@property (nonatomic) SearchViewControllerDataSourceType dataSourceType;
@property (nonatomic, strong) UISearchController *searchController;
@property (nonatomic) CGRect searchBarOriginalFrame;

@end

@implementation SearchViewController

- (instancetype)initWithDataSourceType:(SearchViewControllerDataSourceType)dataSourceType
{
    self = [super init];
    if(self)
    {
        self.dataSourceType = dataSourceType;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.dataSource = [[SearchViewControllerDataSource alloc] initWithDataSourceType:self.dataSourceType];
    
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
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
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
            SearchViewController *newVC = [[SearchViewController alloc] initWithDataSourceType:selectedType];
            [self.navigationController pushViewController:newVC animated:YES];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
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
        
        [self.tableView reloadData];
    }
}
@end
