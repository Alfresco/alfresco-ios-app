/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
#import "SyncManager.h"
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "AlfrescoNodeCell.h"
#import "AccountManager.h"
#import "LoginManager.h"

static CGFloat const kCellHeight = 64.0f;
static NSString * const kFolderSearchCMISQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('cmis:name:%@') AND IN_TREE('%@')";

@interface NodePickerFileFolderListViewController ()

@property (nonatomic, weak) NodePicker *nodePicker;

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
    self.searchController = self.searchController;
    
    if (self.displayFolder)
    {
        self.title = self.displayFolder.name;
    }
    
    if (self.nodePicker.mode == NodePickerModeMultiSelect)
    {
        [self.tableView setEditing:YES];
        [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kPickerMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
//    self.searchDisplayController.searchResultsTableView.contentInset = edgeInset;
    
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
//    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
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

- (void)cancelButtonPressed:(id)sender
{
    [self.nodePicker cancel];
}

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

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.tableView reloadData];
//    [self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark - TableView Delegates and Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.isDisplayingSearch) ? self.searchResults.count : self.tableViewData.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.nodePicker isSelectionEnabledForNode:self.tableViewData[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = (AlfrescoNodeCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    AlfrescoNode *currentNode = nil;
    if (self.isDisplayingSearch)
    {
        currentNode = self.searchResults[indexPath.row];
    }
    else
    {
        currentNode = self.tableViewData[indexPath.row];
    }
    
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    [cell updateStatusIconsIsSyncNode:NO isFavoriteNode:NO animate:NO];
    [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [cell updateStatusIconsIsSyncNode:NO isFavoriteNode:isFavorite animate:NO];
    }];
    
    cell.progressBar.hidden = YES;
    [cell removeNotifications];
    
    if (currentNode.isFolder)
    {
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    if ([self.nodePicker isNodeSelected:currentNode])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (self.isDisplayingSearch)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    if (selectedNode.isFolder)
    {
        if (self.nodePicker.type == NodePickerTypeFolders && self.nodePicker.mode == NodePickerModeSingleSelect)
        {
            [self.nodePicker selectNode:selectedNode];
        }

        NodePickerFileFolderListViewController *browserViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode
                                                                                                                     folderDisplayName:selectedNode.title
                                                                                                                               session:self.session
                                                                                                                  nodePickerController:self.nodePicker];
        [self.navigationController pushViewController:browserViewController animated:YES];
    }
    else
    {
        if (self.nodePicker.type == NodePickerTypeDocuments && self.nodePicker.mode == NodePickerModeSingleSelect)
        {
            [self.nodePicker deselectAllNodes];
            [self.nodePicker selectNode:selectedNode];
            [self.nodePicker pickingNodesComplete];
        }
        else
        {
            [self.nodePicker selectNode:selectedNode];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (self.isDisplayingSearch)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    [self.nodePicker deselectNode:selectedNode];
    [self.tableView reloadData];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
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
    [self.tableView reloadData];
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
