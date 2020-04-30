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

#import "BaseFileFolderCollectionViewController+Internal.h"
#import "SearchCollectionViewDataSource.h"
#import "PermissionChecker.h"
#import <Photos/Photos.h>
#import "UISearchBar+Paste.h"
#import "UIView+Orientation.h"
#import "AlfrescoApp-Swift.h"
#import "AccountManager.h"


static const CGSize kUploadPopoverPreferedSize = {320, 640};
@interface BaseFileFolderCollectionViewController() <MultiplePhotosUploadDelegate, CameraDelegate>

@end

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
    self.listLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:1 itemHeight:kCellHeight shouldSwipeToDelete:YES hasHeader:self.shouldIncludeSearchBar];
    self.listLayout.dataSourceInfoDelegate = self.inUseDataSource;
    self.listLayout.collectionViewMultiSelectDelegate = self;
    self.gridLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:3 itemHeight:-1 shouldSwipeToDelete:NO hasHeader:self.shouldIncludeSearchBar];
    self.gridLayout.dataSourceInfoDelegate = self.inUseDataSource;
    self.gridLayout.collectionViewMultiSelectDelegate = self;
    
    if(!self.hasRequestFinished)
    {
        [self showHUD];
    }
}

- (void)setHasRequestFinished:(BOOL)hasRequestFinished
{
    _hasRequestFinished = hasRequestFinished;
    if(hasRequestFinished)
    {
        [self hideHUD];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_searchController.view removeFromSuperview];
    _imagePickerController.delegate = nil;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.shouldDisplayErrorMessageForRequest)
    {
        [self displayError:self.requestError stringFormat:self.requestErrorStringFormat];
        self.shouldDisplayErrorMessageForRequest = NO;
    }
}

#pragma mark - Custom getters and setters

- (UIImagePickerController *)imagePickerController
{
    if (!_imagePickerController)
    {
        _imagePickerController = [[UIImagePickerController alloc] init];
        _imagePickerController.delegate = self;
    }
    
    return _imagePickerController;
}

#pragma mark - UICollectionViewDelegate methods

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = [self.inUseDataSource numberOfNodesInCollection] - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.item == lastSiteRowIndex)
    {
        int maxItems = self.inUseDataSource.defaultListingContext.maxItems;
        int skipCount = self.inUseDataSource.defaultListingContext.skipCount + (int)self.inUseDataSource.numberOfNodesInCollection;
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];

        if (self.inUseDataSource.moreItemsAvailable)
        {
            // show more items are loading ...
            self.isLoadingAnotherPage = YES;
            [self.inUseDataSource retrieveNextItems:moreListingContext];
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
    [self.multiSelectContainerView.toolbar userDidDeselectAllItems];
    BOOL shouldSearchContent = [[PreferenceManager sharedManager] shouldCarryOutFullSearch];
    
    AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithExactMatch:NO includeContent:shouldSearchContent folder:[self.inUseDataSource parentFolder] includeDescendants:YES];
    searchOptions.typeName = [self.inUseDataSource getSearchType];
    [self searchString:searchBar.text isFromSearchBar:YES searchOptions:searchOptions];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.multiSelectContainerView.toolbar userDidDeselectAllItems];
    self.searchResults = nil;
    self.isOnSearchResults = NO;
    [self.inUseDataSource reloadDataSource];
}

- (void)willDismissSearchController:(UISearchController *)searchController {
    dispatch_async(dispatch_get_main_queue(), ^{
        [searchController.transitionCoordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            searchController.searchBar.alpha = .0f;
            [self.collectionView setContentOffset:CGPointMake(0, kCollectionViewHeaderHight)
                                         animated:YES];
        } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
            searchController.searchBar.alpha = 1.0f;
        }];
    });
}

- (void)updateSearchResultsForSearchController:(UISearchController *)searchController
{
    // No customization available for this class
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [searchBar enableReturnKeyForPastedText:text range:range];
    
    return YES;
}

#pragma mark - Public methods
- (void)searchString:(NSString *)stringToSearch isFromSearchBar:(BOOL)isFromSearchBar searchOptions:(AlfrescoKeywordSearchOptions *)options
{
    [self showHUD];
    self.searchDataSource = [[SearchCollectionViewDataSource alloc] initWithSearchString:stringToSearch searchOptions:options emptyMessage:@"No search results" session:self.session delegate:self listingContext:nil];
    self.isOnSearchResults = isFromSearchBar;
    
}

#pragma mark - Gesture Recognizers methods

- (void)tapToDismissDeleteGestureHandler:(UIGestureRecognizer *)gestureReconizer
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
                    self.initialCellForSwipeToDelete = nil;
                }
                else if(CGRectContainsPoint(properCell.deleteButton.bounds, touchPointInButton))
                {
                    [self showHUD];
                    [self.inUseDataSource collectionView:self.collectionView didSwipeToDeleteItemAtIndex:properLayout.selectedIndexPathForSwipeToDelete completionBlock:^{
                        [self hideHUD];
                    }];
                }
            }
        }
    }
}

- (void)swipeToDeletePanGestureHandler:(ALFSwipeToDeleteGestureRecognizer *)gestureRecognizer
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
                    if(indexPath && indexPath.item < self.inUseDataSource.numberOfNodesInCollection)
                    {
                        self.initialCellForSwipeToDelete = indexPath;
                    }
                    else if(!indexPath)
                    {
                        self.initialCellForSwipeToDelete = nil;
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
    BOOL shouldReceiveTouch = NO;
    if(gestureRecognizer == self.tapToDismissDeleteAction)
    {
        if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
        {
            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
            if((properLayout.selectedIndexPathForSwipeToDelete != nil) && (!self.editing))
            {
                shouldReceiveTouch = YES;
            }
        }
    }
    else if (gestureRecognizer == self.swipeToDeleteGestureRecognizer)
    {
        shouldReceiveTouch = YES;
    }
    return shouldReceiveTouch;
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

#pragma mark - Internal methods
- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    [self.inUseDataSource deleteNode:nodeToDelete completionBlock:^(BOOL success) {
        if(completionBlock != NULL)
        {
            completionBlock(success);
        }
    }];
}

- (void)dismissPopoverOrModalWithAnimation:(BOOL)animated withCompletionBlock:(void (^)(void))completionBlock
{
    if (IS_IPAD)
    {
        if (self.popover)
        {
            [self.popover dismissViewControllerAnimated:YES completion:nil];
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

- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated
{
    if (IS_IPAD)
    {
        self.popover = controller;
        self.popover.preferredContentSize = kUploadPopoverPreferedSize;
        
        controller.modalPresentationStyle = UIModalPresentationPopover;
        controller.popoverPresentationController.delegate = self;
        controller.popoverPresentationController.barButtonItem = self.alertControllerSender;
        controller.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;
        
        [self presentViewController:controller animated:animated completion:nil];
    }
    else
    {
        [UniversalDevice displayModalViewController:controller onController:self.navigationController withCompletionBlock:nil];
    }
}

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated
{
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    
    if((self.inUseDataSource.parentFolderPermissions.canEdit && self.inUseDataSource.shouldAllowMultiselect) || self.inUseDataSource.shouldAllowLayoutChange)
    {
        // update the UI based on permissions
        if (!self.editing)
        {
            self.editBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dots-A"] style:UIBarButtonItemStylePlain target:self action:@selector(performEditBarButtonItemAction:)];
        }
        else
        {
            self.editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                                   target:self
                                                                                   action:@selector(performEditBarButtonItemAction:)];
        }
        
        self.editButtonItem.accessibilityIdentifier = kBaseCollectionVCDotsBarButtonIdentifier;
        
        [rightBarButtonItems addObject:self.editBarButtonItem];
    }
    
    if (!self.isEditing && (self.inUseDataSource.parentFolderPermissions.canAddChildren || self.inUseDataSource.parentFolderPermissions.canEdit))
    {
        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                   target:self
                                                                                   action:@selector(displayActionSheet:event:)];
        addButton.accessibilityIdentifier = kBaseCollectionVCAddButtonIdentifier;
        [rightBarButtonItems addObject:addButton];
    }
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:animated];
}

- (void)selectIndexPathForAlfrescoNodeInDetailView
{
    NSArray *collectionViewNodeIdentifiers = [self.inUseDataSource nodeIdentifiersOfCurrentCollection];
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:[UniversalDevice detailViewItemIdentifier] inNodeIdentifiers:collectionViewNodeIdentifiers];
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)performEditBarButtonItemAction:(UIBarButtonItem *)sender
{
    [self setupActionsAlertController];
    self.actionsAlertController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPC = [self.actionsAlertController popoverPresentationController];
    popPC.barButtonItem = sender;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.delegate = self;
    [self.actionsAlertController.view layoutIfNeeded];
    
    [self presentViewController:self.actionsAlertController animated:YES completion:nil];
}

- (void)displayError:(NSError *)error stringFormat:(NSString *)stringFormat
{
    if(stringFormat)
    {
        if(error)
        {
            displayErrorMessage([NSString stringWithFormat:stringFormat, [ErrorDescriptions descriptionForError:error]]);
        }
        else
        {
            displayErrorMessage(stringFormat);
        }
        [self hidePullToRefreshView];
    }
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    NSUInteger item = [self.inUseDataSource indexOfNode:node];
    NSIndexPath *selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    
    if (node.isFolder)
    {
        [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        
        AlfrescoPermissions *nodePermissions = [self.inUseDataSource permissionsForNode:node];
        [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)node
                                                                     permissions:nodePermissions
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
                [syncManager cancelSyncForDocumentWithIdentifier:node.identifier completionBlock:nil];
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
    AlfrescoNode *node = [self.inUseDataSource alfrescoNodeAtIndex:indexPath.item];
    NSString *errorDescription = [node syncErrorDescription];
    
    if (IS_IPAD)
    {
        if (self.syncFailedDetailController)
        {
            [self.syncFailedDetailController dismissViewControllerAnimated:YES completion:nil];
        }
        self.syncFailedDetailController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload failed popover title")
                                                                                            message:errorDescription retryCompletionBlock:^() {
                                                                                                [self retrySyncAndCloseRetryPopover];
                                                                                            }];
        
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        self.syncFailedDetailController.modalPresentationStyle = UIModalPresentationPopover;
        self.syncFailedDetailController.preferredContentSize = self.syncFailedDetailController.view.frame.size;
        self.syncFailedDetailController.popoverPresentationController.sourceView = cell;
        self.syncFailedDetailController.popoverPresentationController.sourceRect = cell.accessoryView.frame;
        self.syncFailedDetailController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;
        
        if(cell.accessoryView.window != nil)
        {
            [self presentViewController:self.syncFailedDetailController animated:YES completion:nil];
        }
    }
    else
    {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload Failed")
                                                                                 message:errorDescription
                                                                          preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *closeAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Close", @"Close")
                                                              style:UIAlertActionStyleCancel handler:nil];
        [alertController addAction:closeAction];
        UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Retry", @"Retry")
                                                              style:UIAlertActionStyleDefault
                                                            handler:^(UIAlertAction * _Nonnull action) {
                                                                [[RealmSyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
                                                            }];
        [alertController addAction:retryAction];
        
        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void)retrySyncAndCloseRetryPopover
{
    [[RealmSyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
    [self.syncFailedDetailController dismissViewControllerAnimated:YES completion:nil];
    self.syncFailedDetailController = nil;
    self.retrySyncNode = nil;
}

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    if (self.syncFailedDetailController && [self.view isViewOrientationPortrait])
    {
        [self.syncFailedDetailController dismissViewControllerAnimated:YES completion:nil];
        self.syncFailedDetailController = nil;
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

#pragma mark - RepositoryCollectionViewDataSource methods
- (BaseCollectionViewFlowLayout *)currentSelectedLayout
{
    return [self layoutForStyle:self.style];
}

- (id<CollectionViewCellAccessoryViewDelegate>)cellAccessoryViewDelegate
{
    return self;
}

- (void)dataSourceUpdated
{
    [self hidePullToRefreshView];
    [self reloadCollectionView];
    [self selectIndexPathForAlfrescoNodeInDetailView];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    self.isLoadingAnotherPage = NO;
    self.hasRequestFinished = YES;
    self.title = self.inUseDataSource.screenTitle;
    self.editBarButtonItem.enabled = YES;
}

- (void)requestFailedWithError:(NSError *)error stringFormat:(NSString *)stringFormat
{
    if (self.isViewLoaded && self.view.window)
    {
        [self displayError:error stringFormat:stringFormat];
        self.requestError = nil;
        self.requestErrorStringFormat = nil;
    }
    else
    {
        self.requestErrorStringFormat = stringFormat;
        self.requestError = error;
        self.shouldDisplayErrorMessageForRequest = YES;
    }
    
    [Notifier notifyWithAlfrescoError:error];
    self.hasRequestFinished = YES;
}

- (void)didDeleteItems:(NSArray *)items atIndexPaths:(NSArray *)indexPathsOfDeletedItems
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView deleteItemsAtIndexPaths:indexPathsOfDeletedItems];
    } completion:^(BOOL finished) {
        for(AlfrescoNode *deletedNode in items)
        {
            if ([[UniversalDevice detailViewItemIdentifier] isEqualToString:deletedNode.identifier])
            {
                [UniversalDevice clearDetailViewController];
            }
        }
    }];
}

- (void)failedToDeleteItems:(NSError *)error
{
    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.unable.to.delete", @"Unable to delete file/folder"), [ErrorDescriptions descriptionForError:error]]);
    [Notifier notifyWithAlfrescoError: error];
}

- (void)didAddNodes:(NSArray *)items atIndexPath:(NSArray *)indexPathsOfAddedItems
{
    [self.collectionView performBatchUpdates:^{
        [self.collectionView insertItemsAtIndexPaths:indexPathsOfAddedItems];
    } completion:^(BOOL finished) {
        [self updateEmptyView];
    }];
}

- (void)didRetrievePermissionsForParentNode
{
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
}

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [self collectionView:self.collectionView didSelectItemAtIndexPath:indexPath];
}

- (void)setNodeDataSource:(RepositoryCollectionViewDataSource *)dataSource
{
    self.dataSource = dataSource;
    self.collectionView.dataSource = dataSource;
    [self setupActionsAlertController];
}

- (UISearchBar *)searchBarForSupplimentaryHeaderView
{
    return self.searchController.searchBar;
}

- (void)reloadItemsAtIndexPaths:(NSArray *)indexPathsToReload reselectItems:(BOOL)reselectItems
{
    if(reselectItems)
    {
        NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
        } completion:^(BOOL finished) {
            // reselect the row after it has been updated
            for(NSIndexPath *indexPath in selectedIndexPaths)
            {
                for(NSIndexPath *reloadedIndexPath in indexPathsToReload)
                {
                    if (indexPath.row == reloadedIndexPath.row)
                    {
                        [self.collectionView selectItemAtIndexPath:reloadedIndexPath animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                }
            }
        }];
    }
    else
    {
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:indexPathsToReload];
        } completion:nil];
    }
}

#pragma mark - DataSourceInformationProtocol methods
- (BOOL) isItemSelected:(NSIndexPath *) indexPath
{
    if(self.isEditing)
    {
        AlfrescoNode *selectedNode = nil;
        if(indexPath.item < [self.inUseDataSource numberOfNodesInCollection])
        {
            selectedNode = [self.inUseDataSource alfrescoNodeAtIndex:indexPath.item];
        }
        
        if([self.multiSelectContainerView.toolbar.selectedItems containsObject:selectedNode])
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - Actions methods

- (void)changeCollectionViewStyle:(CollectionViewStyle)style animated:(BOOL)animated trackAnalytics: (BOOL) trackAnalytics
{
    [super changeCollectionViewStyle:style animated:animated];
    BaseCollectionViewFlowLayout *associatedLayoutForStyle = [self layoutForStyle:style];
    self.swipeToDeleteGestureRecognizer.enabled = associatedLayoutForStyle.shouldSwipeToDelete;
    
    if (trackAnalytics)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:style == CollectionViewStyleList ? kAnalyticsViewDocumentListing : kAnalyticsViewDocumentGallery];
    }
}

- (void)setupActionsAlertController
{
    self.actionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.inUseDataSource.parentFolderPermissions.canEdit && self.inUseDataSource.shouldAllowMultiselect)
    {
        UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actioncontroller.select", @"Multi-Select") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self setEditing:!self.editing animated:YES];
        }];
        editAction.enabled = ([self.inUseDataSource numberOfNodesInCollection] > 0);
        
        [self.actionsAlertController addAction:editAction];
    }
    
    if (self.inUseDataSource.shouldAllowLayoutChange)
    {
        NSString *changeLayoutTitle;
        if(self.style == CollectionViewStyleList)
        {
            changeLayoutTitle = NSLocalizedString(@"browser.actioncontroller.grid", @"Grid View");
        }
        else
        {
            changeLayoutTitle = NSLocalizedString(@"browser.actioncontroller.list", @"List View");
        }
        UIAlertAction *changeLayoutAction = [UIAlertAction actionWithTitle:changeLayoutTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            if(self.style == CollectionViewStyleList)
            {
                [self changeCollectionViewStyle:CollectionViewStyleGrid animated:YES trackAnalytics:YES];
            }
            else
            {
                [self changeCollectionViewStyle:CollectionViewStyleList animated:YES trackAnalytics:YES];
            }
        }];
        [self.actionsAlertController addAction:changeLayoutAction];
    }
    
    if(self.actionsAlertController.actions.count > 0)
    {
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
            [self.actionsAlertController dismissViewControllerAnimated:YES completion:nil];
        }];
        
        [self.actionsAlertController addAction:cancelAction];
    }
}

- (void)displayActionSheet:(id)sender event:(UIEvent *)event
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.inUseDataSource.parentFolderPermissions.canAddChildren)
    {
        [alertController addAction:[self alertActionCreateFile]];
        [alertController addAction:[self alertActionAddFolder]];
        [alertController addAction:[self alertActionUpload]];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [alertController addAction:[self alertActionTakePhotoOrVideo]];
            if ([[AccountManager sharedManager] selectedAccount].paidAccount) {
                [alertController addAction:[self alertActionTakeContinousPhotos]];
            }
        }
        
        [alertController addAction:[self alertActionRecordAudio]];
    }
    
    [alertController addAction:[self alertActionCancel]];
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    alertController.popoverPresentationController.barButtonItem = sender;
    [self presentViewController:alertController animated:YES completion:nil];
    
    self.alertControllerSender = sender;
}

#pragma mark - UIAlertController UIAlertAction definitions

- (UIAlertAction *)alertActionCancel
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
        if ([[LocationManager sharedManager] isTrackingLocation])
        {
            [[LocationManager sharedManager] stopLocationUpdates];
        }
    }];
}

- (UIAlertAction *)alertActionCreateFile
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.createfile", @"Create File") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        TextFileViewController *textFileViewController = [[TextFileViewController alloc] initWithUploadFileDestinationFolder:[self.inUseDataSource parentFolder] session:self.session delegate:self];
        NavigationViewController *textFileViewNavigationController = [[NavigationViewController alloc] initWithRootViewController:textFileViewController];
        [UniversalDevice displayModalViewController:textFileViewNavigationController onController:[UniversalDevice revealViewController] withCompletionBlock:nil];
        
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionQuickAction
                                                           label:@"text/plain"
                                                           value:@1];
    }];
}

- (UIAlertAction *)alertActionAddFolder
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.addfolder", @"Create Folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action)
            {
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionQuickAction
                                                                   label:kAnalyticsEventLabelFolder
                                                                   value:@1];
                
                // Display the create folder UIAlertController
                UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"browser.alertview.addfolder.title", @"Create Folder Title")
                                                                                         message:NSLocalizedString(@"browser.alertview.addfolder.message", @"Create Folder Message")
                                                                                  preferredStyle:UIAlertControllerStyleAlert];
                
                [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) { }];
                
                [alertController addAction:[self alertActionCancel]];
                [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"browser.alertview.addfolder.create", @"Create Folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    NSString *desiredFolderName = [[alertController.textFields[0] text] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                    
                    if ([Utility isValidFolderName:desiredFolderName])
                    {
                        [self.inUseDataSource createFolderWithName:desiredFolderName];
                    }
                    else
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.createfolder.invalidname", @"Creation failed")]);
                    }
                }]];
                
                alertController.modalPresentationStyle = UIModalPresentationPopover;
                alertController.popoverPresentationController.barButtonItem = self.alertControllerSender;
                
                [self presentViewController:alertController animated:YES completion:nil];
            }];
}

- (UIAlertAction *)alertActionUpload
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload", @"Upload") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // Upload type UIAlertController
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
        [alertController addAction:[self alertActionUploadExistingPhotos]];
        [alertController addAction:[self alertActionUploadDocument]];
        [alertController addAction:[self alertActionCancel]];
        
        alertController.modalPresentationStyle = UIModalPresentationPopover;
        alertController.popoverPresentationController.barButtonItem = self.alertControllerSender;
        
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

- (UIAlertAction *)alertActionUploadExistingPhotos
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotos", @"Choose Photo Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeLibrary completionBlock:^(BOOL granted) {
            if (granted)
            {
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
                self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
                [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
            }
        }];
    }];
}

- (UIAlertAction *)alertActionUploadExistingPhotosOrVideos
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeLibrary completionBlock:^(BOOL granted) {
            if (granted)
            {
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
                self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
                self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
                [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
            }
        }];
    }];
}

- (UIAlertAction *)alertActionUploadDocument
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload.documents", @"Upload Document") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        DownloadsViewController *downloadPicker = [[DownloadsViewController alloc] init];
        downloadPicker.isDownloadPickerEnabled = YES;
        downloadPicker.downloadPickerDelegate = self;
        downloadPicker.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        NavigationViewController *downloadPickerNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadPicker];
        
        [self presentViewInPopoverOrModal:downloadPickerNavigationController animated:YES];
    }];
}

- (UIAlertAction *)alertActionTakePhoto
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.takephoto", @"Take Photo") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeCamera completionBlock:^(BOOL granted) {
            // Start location services
            [PermissionChecker requestPermissionForResourceType:ResourceTypeLocation completionBlock:nil];

            self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
            self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
            self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
        }];
    }];
}

- (UIAlertAction *)alertActionTakeContinousPhotos
{
    __weak typeof(self) weakSelf = self;
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.takecontinuosphotos", @"Take Continous Photos") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeCamera completionBlock:^(BOOL granted) {
            [PermissionChecker requestPermissionForResourceType:ResourceTypeLocation completionBlock:nil];
            if (granted)
            {
                UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Gallery" bundle:nil];
                CameraViewController *cvc =  (CameraViewController *)[storyboard instantiateViewControllerWithIdentifier:@"CameraViewController"];
                GalleryPhotosModel *model = [[GalleryPhotosModel alloc] initWithSession:weakSelf.session folder:[weakSelf.inUseDataSource parentFolder]];
                cvc.model = model;
                cvc.delegate = self;
                [weakSelf.navigationController presentViewController:cvc animated:YES completion:nil];
            }
        }];
    }];
}

- (UIAlertAction *)alertActionTakePhotoOrVideo
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeCamera completionBlock:^(BOOL granted) {
            if (granted)
            {
                // Start location services
                [PermissionChecker requestPermissionForResourceType:ResourceTypeLocation completionBlock:nil];
                
                self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
                self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
                self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
                [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionQuickAction
                                                                   label:kAnalyticsEventLabelTakePhotoOrVideo
                                                                   value:@1];
            }
        }];
    }];
}

- (UIAlertAction *)alertActionRecordAudio
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [PermissionChecker requestPermissionForResourceType:ResourceTypeMicrophone completionBlock:^(BOOL granted) {
            if (granted)
            {
                UploadFormViewController *audioRecorderViewController = [[UploadFormViewController alloc] initWithSession:self.session createAndUploadAudioToFolder:[self.inUseDataSource parentFolder] delegate:self];
                NavigationViewController *audioRecorderNavigationController = [[NavigationViewController alloc] initWithRootViewController:audioRecorderViewController];
                [UniversalDevice displayModalViewController:audioRecorderNavigationController onController:self.navigationController withCompletionBlock:nil];
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionQuickAction
                                                                   label:kAnalyticsEventLabelRecordAudio
                                                                   value:@1];
            }
        }];
    }];
}

#pragma mark - UIImagePickerControllerDelegate Functions
- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info
{
    self.capturingMedia = NO;
    NSString *mediaType = [info objectForKey:UIImagePickerControllerMediaType];
    
    __block UploadFormViewController *uploadFormController = nil;
    __block NavigationViewController *uploadFormNavigationController = nil;
    
    if ([mediaType isEqualToString:(NSString *)kUTTypeImage])
    {
        UIImage *selectedImage = [info objectForKey:UIImagePickerControllerOriginalImage];
        __block NSString *selectedImageExtension = [[[(NSURL *)[info objectForKey:UIImagePickerControllerImageURL] path] pathExtension] lowercaseString];
        
        // define an upload block
        void (^displayUploadForm)(NSDictionary *metadata, BOOL addGPSMetadata) = ^(NSDictionary *metadata, BOOL addGPSMetadata){
            // determine if the content was created or picked
            UploadFormType contentFormType = UploadFormTypeImagePhotoLibrary;
            
            // iOS camera uses JPEG images
            if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
            {
                selectedImageExtension = @"jpg";
                contentFormType = UploadFormTypeImageCreated;
                self.capturingMedia = YES;
            }
            
            // add GPS metadata if Location Services are allowed for this app
            if (addGPSMetadata && [[LocationManager sharedManager] usersLocationAuthorisation])
            {
                metadata = [Utility metadataByAddingGPSToMetadata:metadata];
            }
            
            // location services no longer required
            if ([[LocationManager sharedManager] isTrackingLocation])
            {
                [[LocationManager sharedManager] stopLocationUpdates];
            }
            
            uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadImage:selectedImage fileExtension:selectedImageExtension metadata:metadata inFolder:[self.inUseDataSource parentFolder] uploadFormType:contentFormType delegate:self];
            uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
            
            // display the preview form to upload
            if (self.capturingMedia)
            {
                [self.imagePickerController dismissViewControllerAnimated:YES completion:^{
                    [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
                }];
            }
            else
            {
                [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:^{
                    [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
                }];
            }
        };
        
        NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
        if (metadata)
        {
            displayUploadForm(metadata, YES);
        }
        else
        {
            PHAsset *asset = info[UIImagePickerControllerPHAsset];
            
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:nil resultHandler:^(NSData * _Nullable imageData, NSString * _Nullable dataUTI, UIImageOrientation orientation, NSDictionary * _Nullable info) {
                CGImageSourceRef source = CGImageSourceCreateWithData((__bridge CFDataRef)imageData, NULL);
                CFDictionaryRef imageMetaData = CGImageSourceCopyPropertiesAtIndex(source,0,NULL);
                NSDictionary *assetMetadata = (__bridge NSDictionary *)imageMetaData;
                if (assetMetadata)
                {
                    displayUploadForm(assetMetadata, NO);
                }
                else
                {
                    AlfrescoLogError(@"Unable to extract metadata from item for URL: %@.", info[UIImagePickerControllerImageURL]);
                }
            }];
        }
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeVideo] || [mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        // move the video file into the container
        // read from default file system
        NSString *filePathInDefaultFileSystem = [(NSURL *)[info objectForKey:UIImagePickerControllerMediaURL] path];
        
        // construct the file name
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        dateFormatter.dateFormat = @"yyyy-MM-dd HH.mm.ss";
        NSString *timestamp = [dateFormatter stringFromDate:[NSDate date]];
        NSString *fileExtension = [filePathInDefaultFileSystem pathExtension];
        
        NSString *videoFileNameWithoutExtension = [NSString stringWithFormat:NSLocalizedString(@"upload.default.video.name", @"Video default Name"), timestamp];
        NSString *videoFileName = [videoFileNameWithoutExtension stringByAppendingPathExtension:fileExtension];
        
        // rename the file
        NSString *renamedFilePath = [[filePathInDefaultFileSystem stringByDeletingLastPathComponent] stringByAppendingPathComponent:videoFileName];
        NSError *renameError = nil;
        [[AlfrescoFileManager sharedManager] moveItemAtPath:filePathInDefaultFileSystem toPath:renamedFilePath error:&renameError];
        
        if (renameError)
        {
            AlfrescoLogError(@"Error trying to rename file at path: %@ to path %@. Error: %@", filePathInDefaultFileSystem, renamedFilePath, renameError.localizedDescription);
        }
        
        // determine if the content was created or picked
        UploadFormType contentFormType = UploadFormTypeVideoPhotoLibrary;
        
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        {
            contentFormType = UploadFormTypeVideoCreated;
            self.capturingMedia = YES;
        }
        
        // create the view controller
        uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadDocumentPath:renamedFilePath inFolder:[self.inUseDataSource parentFolder] uploadFormType:contentFormType delegate:self];
        uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
        
        // display the preview form to upload
        if (self.capturingMedia)
        {
            [self.imagePickerController dismissViewControllerAnimated:YES completion:^{
                [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
            }];
        }
        else
        {
            [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:^{
                [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
            }];
        }
    }
}

- (NSDictionary *)metadataByAddingGPSToMetadata:(NSDictionary *)metadata
{
    NSMutableDictionary *returnedMetadata = [metadata mutableCopy];
    
    CLLocationCoordinate2D coordinates = [[LocationManager sharedManager] currentLocationCoordinates];
    
    NSDictionary *gpsDictionary = @{(NSString *)kCGImagePropertyGPSLatitude : [NSNumber numberWithFloat:fabs(coordinates.latitude)],
                                    (NSString *)kCGImagePropertyGPSLatitudeRef : ((coordinates.latitude >= 0) ? @"N" : @"S"),
                                    (NSString *)kCGImagePropertyGPSLongitude : [NSNumber numberWithFloat:fabs(coordinates.longitude)],
                                    (NSString *)kCGImagePropertyGPSLongitudeRef : ((coordinates.longitude >= 0) ? @"E" : @"W")};
    
    [returnedMetadata setValue:gpsDictionary forKey:(NSString *)kCGImagePropertyGPSDictionary];
    
    return returnedMetadata;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    self.capturingMedia = NO;
    
    if ([[LocationManager sharedManager] isTrackingLocation])
    {
        [[LocationManager sharedManager] stopLocationUpdates];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DownloadPickerDelegate Functions

- (void)downloadPicker:(DownloadsViewController *)picker didPickDocument:(NSString *)documentPath
{
    UploadFormViewController *uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session
                                                                                    uploadDocumentPath:documentPath
                                                                                              inFolder:[self.inUseDataSource parentFolder]
                                                                                        uploadFormType:UploadFormTypeDocument
                                                                                              delegate:self];
    
    NavigationViewController *uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
    
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:^{
        [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
    }];
}

- (void)downloadPickerDidCancel
{
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:nil];
}

#pragma mark - UIPopoverPresentationControllerDelegate Methods

- (BOOL)popoverPresentationControllerShouldDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    return !self.capturingMedia;
}

- (void)popoverPresentationControllerDidDismissPopover:(UIPopoverPresentationController *)popoverPresentationController
{
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:nil];
}

#pragma mark - UploadFormViewControllerDelegate Methods

- (void)didFinishUploadingNode:(AlfrescoNode *)node fromLocation:(NSURL *)locationURL
{
    [self.inUseDataSource addAlfrescoNodes:@[node]];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"upload.success-as.message", @"Document uplaoded as"), node.name]);
}

- (void)didFailUploadingDocumentWithName:(NSString *)name withError:(NSError *)error
{
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"saveback.failed.message", @"Document saved in Local Files"), name]);
    [Notifier notifyWithAlfrescoError:error];
}

#pragma mark - MultiplePhotosUpload Delegate

- (void)finishUploadGalleryWithDocuments:(NSArray<AlfrescoDocument *> *)documents
{
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    [self.inUseDataSource addAlfrescoNodes:documents];
}

#pragma mark - Camera Delegate

- (void)closeCameraWithSavePhotos:(BOOL)savePhotos photos:(NSArray<CameraPhoto *> *)photos model:(GalleryPhotosModel *)model
{
    if (savePhotos == YES)
    {
        model.cameraPhotos = photos;
    }
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"Gallery" bundle:nil];
    GalleryPhotosViewController *gpvc = (GalleryPhotosViewController *)[storyboard instantiateViewControllerWithIdentifier:@"GalleryPhotosViewController"];
    gpvc.model = model;
    gpvc.delegate = self;
    NavigationViewController *navGal = [[NavigationViewController alloc] initWithRootViewController:gpvc];
    [UniversalDevice displayModalViewController:navGal onController:self.navigationController withCompletionBlock:nil];
}

@end
