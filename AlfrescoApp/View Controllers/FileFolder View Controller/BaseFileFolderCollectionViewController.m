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

#import "BaseFileFolderCollectionViewController+Internal.h"

@implementation BaseFileFolderCollectionViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //Swipe to Delete Gestures
    self.swipeToDeleteGestureRecognizer = [[ALFSwipeToDeleteGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToDeletePanGestureHandler:)];
    self.swipeToDeleteGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.swipeToDeleteGestureRecognizer];
    
    self.tapToDismissDeleteAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDismissDeleteGestureHandler:)];
    self.tapToDismissDeleteAction.numberOfTapsRequired = 1;
    self.tapToDismissDeleteAction.delegate = self;
    [self.collectionView addGestureRecognizer:self.tapToDismissDeleteAction];
    
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FileFolderCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    
    self.collectionView.delegate = self;
    self.listLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:1 itemHeight:kCellHeight shouldSwipeToDelete:YES hasHeader:NO];
    self.listLayout.dataSourceInfoDelegate = self.dataSource;
    self.listLayout.collectionViewMultiSelectDelegate = self;
    self.gridLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:3 itemHeight:-1 shouldSwipeToDelete:NO hasHeader:NO];
    self.gridLayout.dataSourceInfoDelegate = self.dataSource;
    self.gridLayout.collectionViewMultiSelectDelegate = self;
}

- (void)dealloc
{
    [_searchController.view removeFromSuperview];
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
//    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
//    self.searchService = [[AlfrescoSearchService alloc] initWithSession:session];
}

#pragma mark - Custom getters and setters

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = [self.dataSource numberOfNodesInCollection] - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.item == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.dataSource.numberOfNodesInCollection) intValue]];
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            self.isLoadingAnotherPage = YES;
            [self.dataSource retreiveNextItems:moreListingContext];
        }
    }
    
    if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
    {
        BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        BaseLayoutAttributes *attributes = (BaseLayoutAttributes *)[properLayout layoutAttributesForItemAtIndexPath:indexPath];
        attributes.editing = self.isEditing;
        attributes.animated = NO;
        [cell applyLayoutAttributes:attributes];
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
//    [self.searchService searchWithKeywords:stringToSearch options:options completionBlock:^(NSArray *array, NSError *error) {
//        [self hideHUD];
//        if (array)
//        {
//            self.isOnSearchResults = isFromSearchBar;
//            if(isFromSearchBar)
//            {
//                self.searchResults = [array mutableCopy];
//            }
//            else
//            {
//                self.collectionViewData = [array mutableCopy];
//            }
//            [self reloadCollectionView];
//        }
//        else
//        {
//            // display error
//            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
//            [Notifier notifyWithAlfrescoError:error];
//        }
//    }];
}

#pragma mark - Gesture Recognizers methods

- (void) tapToDismissDeleteGestureHandler:(UIGestureRecognizer *)gestureReconizer
{
    if(gestureReconizer.state == UIGestureRecognizerStateEnded)
    {
        CGPoint touchPoint = [gestureReconizer locationInView:self.collectionView];
        if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
        {
            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            UICollectionViewCell *cell = [self.collectionView cellForItemAtIndexPath:properLayout.selectedIndexPathForSwipeToDelete];
            if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
            {
                FileFolderCollectionViewCell *properCell = (FileFolderCollectionViewCell *)cell;
                CGPoint touchPointInButton = [gestureReconizer locationInView:properCell.deleteButton];
                
                if((CGRectContainsPoint(self.collectionView.bounds, touchPoint)) && (!CGRectContainsPoint(properCell.deleteButton.bounds, touchPointInButton)))
                {
                    properLayout.selectedIndexPathForSwipeToDelete = nil;
                }
                else if(CGRectContainsPoint(properCell.deleteButton.bounds, touchPointInButton))
                {
                    [self collectionView:self.collectionView didSwipeToDeleteItemAtIndex:properLayout.selectedIndexPathForSwipeToDelete];
                }
            }
        }
    }
}

- (void) swipeToDeletePanGestureHandler:(ALFSwipeToDeleteGestureRecognizer *)gestureRecognizer
{
    if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
    {
        BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        if(properLayout.selectedIndexPathForSwipeToDelete)
        {
            if(gestureRecognizer.state == UIGestureRecognizerStateBegan)
            {
                [gestureRecognizer alf_endGestureHandling];
            }
            else if(gestureRecognizer.state == UIGestureRecognizerStateEnded)
            {
                properLayout.selectedIndexPathForSwipeToDelete = nil;
            }
        }
        else
        {
            if (gestureRecognizer.state == UIGestureRecognizerStateBegan)
            {
                CGPoint startingPoint = [gestureRecognizer locationInView:self.collectionView];
                if (CGRectContainsPoint(self.collectionView.bounds, startingPoint))
                {
                    NSIndexPath *indexPath = [self.collectionView indexPathForItemAtPoint:startingPoint];
                    if(indexPath && indexPath.item < self.dataSource.numberOfNodesInCollection)
                    {
                        self.initialCellForSwipeToDelete = indexPath;
                    }
                }
            }
            else if (gestureRecognizer.state == UIGestureRecognizerStateChanged)
            {
                if(self.initialCellForSwipeToDelete)
                {
                    CGPoint translation = [gestureRecognizer translationInView:self.view];
                    if (translation.x < 0)
                    {
                        self.shouldShowOrHideDelete = (translation.x * -1) > self.cellActionViewWidth / 2;
                    }
                    else
                    {
                        self.shouldShowOrHideDelete = translation.x > self.cellActionViewWidth / 2;
                    }
                    
                    FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.initialCellForSwipeToDelete];
                    [cell revealActionViewWithAmount:translation.x];
                }
            }
            else if (gestureRecognizer.state == UIGestureRecognizerStateEnded)
            {
                if(self.initialCellForSwipeToDelete)
                {
                    if(self.shouldShowOrHideDelete)
                    {
                        if(properLayout.selectedIndexPathForSwipeToDelete)
                        {
                            properLayout.selectedIndexPathForSwipeToDelete = nil;
                        }
                        else
                        {
                            properLayout.selectedIndexPathForSwipeToDelete = self.initialCellForSwipeToDelete;
                        }
                    }
                    else
                    {
                        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:self.initialCellForSwipeToDelete];
                        [cell resetView];
                        properLayout.selectedIndexPathForSwipeToDelete = nil;
                    }
                }
            }
        }
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    if(gestureRecognizer == self.tapToDismissDeleteAction)
    {
        if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
        {
            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            if((properLayout.selectedIndexPathForSwipeToDelete != nil) && (!self.editing))
            {
                return YES;
            }
        }
    }
    else if (gestureRecognizer == self.swipeToDeleteGestureRecognizer)
    {
        return YES;
    }
    return NO;
}

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    BOOL shouldBegin = NO;
    if(gestureRecognizer == self.swipeToDeleteGestureRecognizer)
    {
        if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
        {
            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            CGPoint translation = [self.swipeToDeleteGestureRecognizer translationInView:self.collectionView];
            if((translation.x < 0 && !properLayout.selectedIndexPathForSwipeToDelete) || (properLayout.selectedIndexPathForSwipeToDelete))
            {
                shouldBegin = YES;
            }
        }
    }
    else if (gestureRecognizer == self.tapToDismissDeleteAction)
    {
        if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
        {
            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            if((properLayout.selectedIndexPathForSwipeToDelete != nil) && (!self.editing))
            {
                shouldBegin = YES;
            }
        }
    }
    
    return shouldBegin;
}

#pragma mark - SwipeToDeleteDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSwipeToDeleteItemAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *nodeToDelete = (self.isOnSearchResults) ? self.searchResults[indexPath.item] : self.collectionViewData[indexPath.item];
    AlfrescoPermissions *permissionsForNodeToDelete = self.dataSource.nodesPermissions[nodeToDelete.identifier];
    
    if (permissionsForNodeToDelete.canDelete)
    {
        [self deleteNode:nodeToDelete completionBlock:^(BOOL success) {
            if(success)
            {
                if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
                {
                    BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
                    [properLayout setSelectedIndexPathForSwipeToDelete:nil];
                }
            }
        }];
    }
}

#pragma mark - Internal methods
- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    [self.dataSource deleteNode:nodeToDelete completionBlock:^(BOOL success) {
        if(completionBlock != NULL)
        {
            completionBlock(success);
        }
    }];
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    NSUInteger item = [self.dataSource indexOfNode:node];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    
    if (node.isFolder)
    {
        [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        
        [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)node
                                                                     permissions:nil
                                                                         session:self.session
                                                            navigationController:self.navigationController
                                                                        animated:YES];
    }
    else
    {
        RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
        SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
        
        switch (nodeStatus.status)
        {
            case SyncStatusLoading:
            {
                [syncManager cancelSyncForDocumentWithIdentifier:node.identifier];
                break;
            }
            case SyncStatusFailed:
            {
                self.retrySyncNode = node;
                [self showPopoverForFailedSyncNodeAtIndexPath:selectedIndexPath];
                break;
            }
            default:
            {
                break;
            }
        }
    }
}

#pragma mark - Retrying Failed Sync Methods
- (void)showPopoverForFailedSyncNodeAtIndexPath:(NSIndexPath *)indexPath
{
    RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
    AlfrescoNode *node = self.collectionViewData[indexPath.row];
    NSString *errorDescription = [syncManager syncErrorDescriptionForNode:node];
    
    if (IS_IPAD)
    {
        FailedTransferDetailViewController *syncFailedDetailController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload failed popover title")
                                                                                                                           message:errorDescription retryCompletionBlock:^() {
                                                                                                                               [self retrySyncAndCloseRetryPopover];
                                                                                                                           }];
        
        if (self.retrySyncPopover)
        {
            [self.retrySyncPopover dismissPopoverAnimated:YES];
        }
        self.retrySyncPopover = [[UIPopoverController alloc] initWithContentViewController:syncFailedDetailController];
        self.retrySyncPopover.popoverContentSize = syncFailedDetailController.view.frame.size;
        
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        if(cell.accessoryView.window != nil)
        {
            [self.retrySyncPopover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        }
    }
    else
    {
        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload Failed")
                                    message:errorDescription
                                   delegate:self
                          cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
                          otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil] show];
    }
}

- (void)retrySyncAndCloseRetryPopover
{
    [[RealmSyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
    [self.retrySyncPopover dismissPopoverAnimated:YES];
    self.retrySyncNode = nil;
    self.retrySyncPopover = nil;
}

- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated
{
    if (IS_IPAD)
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        popoverController.delegate = self;
        self.popover = popoverController;
        self.popover.contentViewController = controller;
        [self.popover presentPopoverFromBarButtonItem:self.alertControllerSender permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
    }
    else
    {
        [UniversalDevice displayModalViewController:controller onController:self.navigationController withCompletionBlock:nil];
    }
}

- (void)dismissPopoverOrModalWithAnimation:(BOOL)animated withCompletionBlock:(void (^)(void))completionBlock
{
    if (IS_IPAD)
    {
        if ([self.popover isPopoverVisible])
        {
            [self.popover dismissPopoverAnimated:YES];
        }
        self.popover = nil;
        if (completionBlock != NULL)
        {
            completionBlock();
        }
    }
    else
    {
        [self dismissViewControllerAnimated:animated completion:completionBlock];
    }
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration
{
    CGRect screenRect = [[UIScreen mainScreen] bounds];
    // if going to landscape, use the screen height as the popover width and screen width as the popover height
    if (UIInterfaceOrientationIsLandscape(toInterfaceOrientation))
    {
        self.popover.contentViewController.preferredContentSize = CGSizeMake(screenRect.size.height, screenRect.size.width);
    }
    else
    {
        self.popover.contentViewController.preferredContentSize = CGSizeMake(screenRect.size.width, screenRect.size.height);
    }
}

#pragma mark - UIAdaptivePresentationControllerDelegate methods
- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (UIViewController *)presentationController:(UIPresentationController *)controller viewControllerForAdaptivePresentationStyle:(UIModalPresentationStyle)style
{
    return self.actionsAlertController;
}

@end
