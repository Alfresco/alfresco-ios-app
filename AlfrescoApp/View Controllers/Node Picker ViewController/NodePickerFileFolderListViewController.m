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

#import "NodePickerFileFolderListViewController.h"
#import "ConnectivityManager.h"
#import "AlfrescoNodeCell.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "NodePickerScopeViewController.h"
#import "UISearchBar+Paste.h"

static NSString * const kFolderSearchCMISQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('cmis:name:%@') AND IN_TREE('%@')";

@interface NodePickerFileFolderListViewController () <UISearchControllerDelegate>

@property (nonatomic, strong) UISearchBar *searchBar;

@end

@implementation NodePickerFileFolderListViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder
             folderDisplayName:(NSString *)displayName
                       session:(id<AlfrescoSession>)session
          nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    if (self)
    {
        self.nodePicker = nodePicker;
        [self setDisplayFolder:folder];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createAlfrescoServicesWithSession:self.session];
    [self loadContentOfFolder];
    
    self.definesPresentationContext = YES;
    
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.searchBar.delegate = self;
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = YES;
    searchController.delegate = self;
    self.searchController = searchController;
    
    // search bar
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    self.searchBar = searchController.searchBar;
    self.searchBar.frame = CGRectMake(view.frame.origin.x, view.frame.origin.y, view.frame.size.width, 44.0f);
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor whiteColor];
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    self.tableView.tableHeaderView = self.searchBar;
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    if (self.displayFolder)
    {
        self.title = self.displayFolder.name;
    }
        
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deselectAllSelectedNodes:) name:kAlfrescoPickerDeselectAllNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.nodePicker updateMultiSelectToolBarActions];
    [self updateSelectFolderButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods

- (void)loadContentOfFolder
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        // if the display folder is not set, retrieve Root Folder content
        if (!self.displayFolder)
        {
            [self showHUD];
            [self.documentService retrieveRootFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                if (folder)
                {
                    [self setDisplayFolder:folder];
                    self.navigationItem.title = folder.name;
                    
                    [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                        [self hideHUD];
                        [self reloadTableViewWithPagingResult:pagingResult error:error];
                        [self hidePullToRefreshView];
                    }];
                    
                    [self updateSelectFolderButton];
                }
            }];
        }
        else
        {
            [self showHUD];
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self hideHUD];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
                [self hidePullToRefreshView];
            }];
        }
    }
}

- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder usingListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        [self.documentService retrieveFoldersInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            
            if (completionBlock != NULL)
            {
                completionBlock(pagingResult, error);
            }
        }];
    }
    else
    {
        [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            
            if (completionBlock != NULL)
            {
                completionBlock(pagingResult, error);
            }
        }];
    }
}

- (void)updateSelectFolderButton
{
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        if (self.displayFolder)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.displayFolder]];
        }
    }
}

- (AlfrescoNode *)nodeForIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *currentNode = self.isDisplayingSearch ? self.searchResults[indexPath.row] : self.tableViewData[indexPath.row];
    return currentNode;
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
}

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.tableView reloadData];
}

#pragma mark - TableView Delegates and Datasource

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *currentNode = [self nodeForIndexPath:indexPath];
    return [self.nodePicker isSelectionEnabledForNode:currentNode];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = (AlfrescoNodeCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    AlfrescoNode *currentNode = [self nodeForIndexPath:indexPath];
    [cell setupCellWithNode:currentNode session:self.session hideAccessoryView:YES];
    
    cell.progressBar.hidden = YES;
    
    if ([self.nodePicker isNodeSelected:currentNode])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

#pragma mark - Searchbar Delegate

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        [self showSearchProgressHUD];
        NSString *searchQuery = [NSString stringWithFormat:kFolderSearchCMISQuery, searchBar.text, self.displayFolder.identifier];
        [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
            [self hideSearchProgressHUD];
            if (array)
            {
                self.searchResults = [array mutableCopy];
                [self.tableView reloadData];
            }
            else
            {
                // display error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.search.failed", @"Site Search failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [super searchBarSearchButtonClicked:searchBar];
    }
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
    self.isDisplayingSearch = NO;
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [searchBar enableReturnKeyForPastedText:text range:range];
    
    return YES;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadContentOfFolder];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadContentOfFolder];
            }
        }];
    }
}

@end
