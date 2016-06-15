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

#import "BaseFileFolderCollectionViewController.h"
#import "PreferenceManager.h"

@interface BaseFileFolderCollectionViewController () <UISearchControllerDelegate>
@end

@implementation BaseFileFolderCollectionViewController

- (void)dealloc
{
    [_searchController.view removeFromSuperview];
}

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

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.collectionViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.item == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.collectionViewData.count) intValue]];
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            self.isLoadingAnotherPage = YES;
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self.collectionView performBatchUpdates:^{
                    [self addMoreToCollectionViewWithPagingResult:pagingResult error:error];
                } completion:^(BOOL finished) {
                    self.isLoadingAnotherPage = NO;
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
    [self searchString:searchBar.text isFromSearchBar:YES searchOptions:searchOptions];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
    self.isOnSearchResults = NO;
    [self reloadCollectionView];
}

- (void)didPresentSearchController:(UISearchController *)searchController
{
    self.collectionViewTopConstraint.constant = 20;
    [self.view layoutIfNeeded];
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    self.collectionViewTopConstraint.constant = 0;
    [self.view layoutIfNeeded];
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    
}

#pragma mark - Public methods
- (void)searchString:(NSString *)stringToSearch isFromSearchBar:(BOOL)isFromSearchBar searchOptions:(AlfrescoKeywordSearchOptions *)options
{
    [self showHUD];
    [self.searchService searchWithKeywords:stringToSearch options:options completionBlock:^(NSArray *array, NSError *error) {
        [self hideHUD];
        if (array)
        {
            self.isOnSearchResults = isFromSearchBar;
            if(isFromSearchBar)
            {
                self.searchResults = [array mutableCopy];
            }
            else
            {
                self.collectionViewData = [array mutableCopy];
            }
            [self reloadCollectionView];
        }
        else
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

@end
