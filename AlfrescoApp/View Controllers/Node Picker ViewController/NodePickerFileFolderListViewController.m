//
//  NodePickerFileFolderListViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSInteger const kFolderSelectionButtonWidth = 32;
static NSInteger const kFolderSelectionButtongHeight = 32;

static CGFloat const kCellHeight = 64.0f;

#import "NodePickerFileFolderListViewController.h"
#import "ConnectivityManager.h"
#import "SyncManager.h"
#import "ThumbnailDownloader.h"
#import "FavouriteManager.h"
#import "AlfrescoNodeCell.h"
#import "Utility.h"

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
        self.displayFolder = folder;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self createAlfrescoServicesWithSession:self.session];
    [self loadContentOfFolder];
    self.searchController = self.searchDisplayController;
    
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
    self.searchDisplayController.searchResultsTableView.contentInset = edgeInset;
    
    [self.searchDisplayController.searchResultsTableView setEditing:YES];
    [self.searchDisplayController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        if (self.displayFolder)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.displayFolder]];
        }
    }
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.nodePicker updateMultiSelectToolBarActions];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
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
                    self.displayFolder = folder;
                    self.navigationItem.title = folder.name;
                    
                    [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                        [self hideHUD];
                        [self reloadTableViewWithPagingResult:pagingResult error:error];
                    }];
                }
            }];
        }
        else
        {
            [self showHUD];
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self hideHUD];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
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

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.tableView reloadData];
    [self.searchDisplayController.searchResultsTableView reloadData];
}

#pragma mark - TableView Delegates and Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (tableView == self.searchDisplayController.searchResultsTableView) ? self.searchResults.count : self.tableViewData.count;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.nodePicker isSelectionEnabledForNode:self.tableViewData[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = (AlfrescoNodeCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    AlfrescoNode *currentNode = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
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
    
    if ([self.nodePicker isNodeSelected:currentNode])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    if (selectedNode.isFolder)
    {
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
    if (tableView == self.searchDisplayController.searchResultsTableView)
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

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
    [self.tableView reloadData];
}

@end
