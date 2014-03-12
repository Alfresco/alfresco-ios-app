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

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, weak) NodePicker *nodePicker;
@property (nonatomic, strong) AlfrescoFolder *displayFolder;
@property (nonatomic, strong) NSArray *searchResults;

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
        _nodePicker = nodePicker;
        _displayFolder = folder;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:self.session];
    [self loadContentOfFolder];
    
    if (self.displayFolder)
    {
        self.title = self.displayFolder.name;
    }
    
    if (self.nodePicker.nodePickerMode == NodePickerModeMultiSelect)
    {
        [self.tableView setEditing:YES];
        [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
    self.searchDisplayController.searchResultsTableView.contentInset = edgeInset;
    
    [self.searchDisplayController.searchResultsTableView setEditing:YES];
    [self.searchDisplayController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    
    if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
    {
        if (self.displayFolder)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.displayFolder]];
        }
    }
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kAlfrescoNodeCellIdentifier];
    [self.searchDisplayController.searchResultsTableView registerNib:nib forCellReuseIdentifier:kAlfrescoNodeCellIdentifier];
    
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
    [self.nodePicker cancelNodePicker];
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
    
    if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
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
    AlfrescoNodeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kAlfrescoNodeCellIdentifier];
    
    AlfrescoNode *currentNode = nil;
    if (tableView == self.searchDisplayController.searchResultsTableView)
    {
        currentNode = self.searchResults[indexPath.row];
    }
    else
    {
        currentNode = self.tableViewData[indexPath.row];
    }
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    BOOL isSyncNode = [syncManager isNodeInSyncList:currentNode];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
    [cell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus registerForNotifications:NO];
    [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
    
    [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
    }];
    
    if (currentNode.isFolder)
    {
        cell.image.image = smallImageForType(@"folder");
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
        AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
        
        UIImage *thumbnail = [[ThumbnailDownloader sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
        if (thumbnail)
        {
            [cell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            UIImage *placeholderImage = smallImageForType([documentNode.name pathExtension]);
            cell.image.image = placeholderImage;
            [[ThumbnailDownloader sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    [cell.image setImage:image withFade:YES];
                }
            }];
        }
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
        if (self.nodePicker.nodePickerType == NodePickerTypeDocuments && self.nodePicker.nodePickerMode == NodePickerModeSingleSelect)
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.tableViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.tableViewData.count) intValue]];
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

#pragma mark - Searchbar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithFolder:self.displayFolder includeDescendants:YES];
    
    __block MBProgressHUD *searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchDisplayController.searchResultsTableView];
    [self.searchDisplayController.searchResultsTableView addSubview:searchProgressHUD];
    [searchProgressHUD show:YES];
    
    [self.searchService searchWithKeywords:searchBar.text options:searchOptions completionBlock:^(NSArray *array, NSError *error) {
        [searchProgressHUD hide:YES];
        searchProgressHUD = nil;
        if (array)
        {
            self.searchResults = [array mutableCopy];
            [self.searchDisplayController.searchResultsTableView reloadData];
        }
    }];
}

@end
