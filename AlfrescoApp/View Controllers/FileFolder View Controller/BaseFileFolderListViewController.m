//
//  BaseFileFolderListViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 17/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "BaseFileFolderListViewController.h"

@interface BaseFileFolderListViewController ()

@end

@implementation BaseFileFolderListViewController

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:session];
}

- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder
            usingListingContext:(AlfrescoListingContext *)listingContext
                completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    AlfrescoLogDebug(@"should be implemented by subclasses");
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Custom getters and setters

- (void)setDisplayFolder:(AlfrescoFolder *)displayFolder
{
    _displayFolder = displayFolder;
    
    if (_displayFolder)
    {
        [self showHUD];
        [self retrieveContentOfFolder:_displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            if (pagingResult)
            {
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtoretrieve", @"Retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
}

#pragma mark TableView Delegate and Datasource Methods

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = [tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    // config the cell here...
    AlfrescoNode *currentNode = nil;
    if (tableView == self.searchController.searchResultsTableView)
    {
        currentNode = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        currentNode = [self.tableViewData objectAtIndex:indexPath.row];
    }
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    BOOL isSyncNode = [syncManager isNodeInSyncList:currentNode];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
    [cell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus];
    [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
    
    [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
    }];
    
    if ([currentNode isKindOfClass:[AlfrescoFolder class]])
    {
        [cell.image setImage:smallImageForType(@"folder") withFade:NO];
    }
    else
    {
        AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
        
        UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
        if (thumbnail)
        {
            [cell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            [cell.image setImage:smallImageForType([documentNode.name pathExtension]) withFade:NO];
            
            [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    AlfrescoNodeCell *updateCell = (AlfrescoNodeCell *)[tableView cellForRowAtIndexPath:indexPath];
                    if (updateCell)
                    {
                        [updateCell.image setImage:image withFade:YES];
                    }
                }
            }];
        }
    }
    
    return cell;
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

#pragma mark - UISearchBarDelegate Functions

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithFolder:self.displayFolder includeDescendants:YES];
    
    __block MBProgressHUD *searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchController.searchResultsTableView];
    [self.searchController.searchResultsTableView addSubview:searchProgressHUD];
    [searchProgressHUD show:YES];
    
    [self.searchService searchWithKeywords:searchBar.text options:searchOptions completionBlock:^(NSArray *array, NSError *error) {
        [searchProgressHUD hide:YES];
        searchProgressHUD = nil;
        if (array)
        {
            self.searchResults = [array mutableCopy];
            [self.searchController.searchResultsTableView reloadData];
        }
        else
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
}

@end
