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

#import "BaseFileFolderCollectionViewController.h"
#import "PreferenceManager.h"

@interface BaseFileFolderCollectionViewController ()

@end

@implementation BaseFileFolderCollectionViewController

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

- (void)showSearchProgressHUD
{
//    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchController.searchResultsTableView];
//    [self.searchController.searchResultsTableView addSubview:self.searchProgressHUD];
//    [self.searchProgressHUD show:YES];
}

- (void)hideSearchProgressHUD
{
//    [self.searchProgressHUD hide:YES];
//    self.searchProgressHUD = nil;
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
                [self reloadCollectionViewWithPagingResult:pagingResult error:error];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtoretrieve", @"Retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
}

#pragma mark CollectionView Delegate and Datasource Methods

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
//    if(indexPath.item == self.collectionViewData.count)
//    {
//        LoadingCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier] forIndexPath:indexPath];
//        
//        return cell;
//    }
    
    FileFolderCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier] forIndexPath:indexPath];
    
    // config the cell here...
    AlfrescoNode *currentNode = nil;
//    if (collectionView == self.searchController.searchResultsTableView)
//    {
//        currentNode = [self.searchResults objectAtIndex:indexPath.row];
//    }
//    else
//    {
        currentNode = [self.collectionViewData objectAtIndex:indexPath.row];
//    }
    
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
                @try
                {
                    if (image)
                    {
                        // MOBILE-2991, check the tableView and indexPath objects are still valid as there is a chance
                        // by the time completion block is called the table view could have been unloaded.
                        if (collectionView && indexPath)
                        {
                            FileFolderCollectionViewCell *updateCell = (FileFolderCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                            [updateCell.image setImage:image withFade:YES];
                        }
                    }
                }
                @catch (NSException *exception)
                {
                    AlfrescoLogError(@"Exception thrown is %@", exception);
                }
            }];
        }
    }
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    //the last cell index of the table data
    NSUInteger lastSiteCellIndex = self.collectionViewData.count - 1;
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastSiteCellIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.collectionViewData.count) intValue]];
        if (self.moreItemsAvailable)
        {
            self.isLoadingAnotherPage = YES;
            [self.collectionView performBatchUpdates:^{
                [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:self.collectionViewData.count inSection:0]]];
            } completion:^(BOOL finished) {
                [self retrieveContentOfFolder:self.displayFolder usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self.collectionView performBatchUpdates:^{
                        self.isLoadingAnotherPage = NO;
                        [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:self.collectionViewData.count inSection:0]]];
                    } completion:^(BOOL finished) {
                        [self addMoreToCollectionViewWithPagingResult:pagingResult error:error];
                    }];
                }];
            }];
        }
    }
}

#pragma mark - UISearchBarDelegate Functions

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    BOOL shouldSearchContent = [[PreferenceManager sharedManager] shouldCarryOutFullSearch];
    
    AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithExactMatch:NO includeContent:shouldSearchContent folder:self.displayFolder includeDescendants:YES];
    
    [self showSearchProgressHUD];
    [self.searchService searchWithKeywords:searchBar.text options:searchOptions completionBlock:^(NSArray *array, NSError *error) {
        [self hideSearchProgressHUD];
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
    [self.collectionView reloadData];
}

@end
