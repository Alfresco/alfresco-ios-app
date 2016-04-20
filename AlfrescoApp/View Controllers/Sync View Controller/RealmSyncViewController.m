/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "RealmSyncViewController.h"
#import "ConnectivityManager.h"
#import "FileFolderCollectionViewCell.h"
#import "SyncCollectionViewDataSource.h"
#import "RealmSyncManager.h"
#import "UniversalDevice.h"
#import "FailedTransferDetailViewController.h"
#import "PreferenceManager.h"
#import "SyncNavigationViewController.h"

static CGFloat const kCellHeight = 64.0f;
static CGFloat const kSyncOnSiteRequestsCompletionTimeout = 5.0; // seconds

static NSString * const kVersionSeriesValueKeyPath = @"properties.cmis:versionSeriesId.value";

@interface RealmSyncViewController () < RepositoryCollectionViewDataSourceDelegate >

@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, assign) BOOL didSyncAfterSessionRefresh;

@property (nonatomic, strong) UIBarButtonItem *switchLayoutBarButtonItem;

@property (nonatomic, strong) SyncCollectionViewDataSource *dataSource;

@end

@implementation RealmSyncViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.session = session;
        self.parentNode = node;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(siteRequestsCompleted:)
                                                     name:kAlfrescoSiteRequestsCompletedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didAddNodeToFavourites:)
                                                     name:kFavouritesDidAddNodeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(didRemoveNodeFromFavourites:)
                                                     name:kFavouritesDidRemoveNodeNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDeleted:)
                                                     name:kAlfrescoDocumentDeletedOnServerNotification
                                                   object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.parentNode != nil || ![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        [self disablePullToRefresh];
    }
    
    self.title = [self listTitle];
    [self adjustCollectionViewForProgressView:nil];
    
    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([FileFolderCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    
    self.dataSource = [[SyncCollectionViewDataSource alloc] initWithTopLevelSyncNodes];
    self.dataSource.session = self.session;
    self.dataSource.delegate = self;
    
    self.collectionView.dataSource = self.dataSource;
    self.collectionView.delegate = self;
    
    self.listLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:1 itemHeight:kCellHeight shouldSwipeToDelete:YES hasHeader:NO];
    self.listLayout.dataSourceInfoDelegate = self;
    self.listLayout.collectionViewMultiSelectDelegate = self;
    self.gridLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:3 itemHeight:-1 shouldSwipeToDelete:NO hasHeader:NO];
    self.gridLayout.dataSourceInfoDelegate = self;
    self.gridLayout.collectionViewMultiSelectDelegate = self;
    
    [self changeCollectionViewStyle:self.style animated:YES];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSyncObstacles:)
                                                 name:kSyncObstaclesNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdatePreference:)
                                                 name:kSettingsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountInfoUpdated:)
                                                 name:kAlfrescoAccountUpdatedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(nodeAdded:)
                                                 name:kAlfrescoNodeAddedOnServerNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustCollectionViewForProgressView:)
                                                 name:kSyncProgressViewVisiblityChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(editingDocumentCompleted:)
                                                 name:kAlfrescoDocumentEditedNotification object:nil];
    
    [self setupBarButtonItems];
    
    if (!self.didSyncAfterSessionRefresh || self.parentNode != nil)
    {
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
//        [self loadSyncNodesForFolder:self.parentNode];
        [super reloadCollectionView];
        self.didSyncAfterSessionRefresh = YES;
    }
}

#pragma mark - Private methods
- (NSString *)listTitle
{
    NSString *title = @"";
    
    if (self.parentNode)
    {
        title = self.parentNode.name;
    }
    else
    {
        title = NSLocalizedString(@"sync.title", @"Sync Title");
    }
    
    self.emptyMessage = NSLocalizedString(@"sync.empty", @"No Synced Content");
    return title;
}

- (void) setupBarButtonItems
{
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    
    // update the UI based on permissions
    self.switchLayoutBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"dots-A"] style:UIBarButtonItemStylePlain target:self action:@selector(showLayoutSwitchPopup:)];
    
    [rightBarButtonItems addObject:self.switchLayoutBarButtonItem];
    
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:NO];
}

- (void)showLayoutSwitchPopup:(UIBarButtonItem *)sender
{
    [self setupActionsAlertController];
    self.actionsAlertController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popPC = [self.actionsAlertController popoverPresentationController];
    popPC.barButtonItem = self.switchLayoutBarButtonItem;
    popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
    popPC.delegate = self;
    
    [self presentViewController:self.actionsAlertController animated:YES completion:nil];
}

- (void)setupActionsAlertController
{
    self.actionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
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
            [self changeCollectionViewStyle:CollectionViewStyleGrid animated:YES];
        }
        else
        {
            [self changeCollectionViewStyle:CollectionViewStyleList animated:YES];
        }
    }];
    [self.actionsAlertController addAction:changeLayoutAction];
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self.actionsAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.actionsAlertController addAction:cancelAction];
}

- (void)showPopoverForFailedSyncNodeAtIndexPath:(NSIndexPath *)indexPath
{
//    RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
//    AlfrescoNode *node = self.collectionViewData[indexPath.row];
//    NSString *errorDescription = [syncManager syncErrorDescriptionForNode:node];
//    
//    if (IS_IPAD)
//    {
//        FailedTransferDetailViewController *syncFailedDetailController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload failed popover title")
//                                                                                                                           message:errorDescription retryCompletionBlock:^() {
//                                                                                                                               [self retrySyncAndCloseRetryPopover];
//                                                                                                                           }];
//        
//        if (self.retrySyncPopover)
//        {
//            [self.retrySyncPopover dismissPopoverAnimated:YES];
//        }
//        self.retrySyncPopover = [[UIPopoverController alloc] initWithContentViewController:syncFailedDetailController];
//        [self.retrySyncPopover setPopoverContentSize:syncFailedDetailController.view.frame.size];
//        
//        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
//        
//        if (cell.accessoryView.window != nil)
//        {
//            [self.retrySyncPopover presentPopoverFromRect:cell.accessoryView.frame inView:cell permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
//        }
//    }
//    else
//    {
//        [[[UIAlertView alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload Failed")
//                                    message:errorDescription
//                                   delegate:self
//                          cancelButtonTitle:NSLocalizedString(@"Close", @"Close")
//                          otherButtonTitles:NSLocalizedString(@"Retry", @"Retry"), nil] show];
//    }
}

- (void)retrySyncAndCloseRetryPopover
{
//    [[RealmSyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
    [self.retrySyncPopover dismissPopoverAnimated:YES];
    self.retrySyncNode = nil;
    self.retrySyncPopover = nil;
}

- (void)adjustCollectionViewForProgressView:(NSNotification *)notification
{
    id navigationController = self.navigationController;
    
    if((notification) && (notification.object) && (navigationController != notification.object) && ([navigationController conformsToProtocol: @protocol(SyncManagerProgressDelegate)]))
    {
        /* The sender is not the navigation controller of this view controller, but the navigation controller of another instance of SyncViewController (namely the favorites view controller
         which was created when the account was first added). Will update the progress delegate on SyncManager to be able to show the progress view. The cause of this problem is a timing issue
         between begining the syncing process, menu reloading and delegate calls and notifications going around from component to component.
         */
        [SyncManager sharedManager].progressDelegate = navigationController;
    }
    
    if ([navigationController isKindOfClass:[SyncNavigationViewController class]])
    {
        SyncNavigationViewController *syncNavigationController = (SyncNavigationViewController *)navigationController;
        
        UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        if ([syncNavigationController isProgressViewVisible])
        {
            edgeInset = UIEdgeInsetsMake(0.0, 0.0, [syncNavigationController progressViewHeight], 0.0);
        }
        self.collectionView.contentInset = edgeInset;
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

#pragma mark - CollectionViewMultiSelectDelegate methods
- (BOOL) isItemSelected:(NSIndexPath *) indexPath
{
    if(self.isEditing)
    {
        AlfrescoNode *selectedNode = nil;
        if(indexPath.item < self.collectionViewData.count)
        {
            selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
        }
        
        if([self.multiSelectToolbar.selectedItems containsObject:selectedNode])
        {
            return YES;
        }
    }
    return NO;
}

#pragma mark - DataSourceInformationProtocol methods
- (NSInteger)indexOfNode:(AlfrescoNode *)node
{
    NSInteger index = NSNotFound;
    index = [self.collectionViewData indexOfObject:node];
    
    return index;
}

- (BOOL)isNodeAFolderAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if(indexPath.item < self.collectionViewData.count)
    {
        selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
    }
    
    return [selectedNode isKindOfClass:[AlfrescoFolder class]];
}

#pragma mark - SyncCollectionViewDataSourceDelegate methods
- (BaseCollectionViewFlowLayout *)currentSelectedLayout
{
    return [self layoutForStyle:self.style];
}

- (id<CollectionViewCellAccessoryViewDelegate>)cellAccessoryViewDelegate
{
    return self;
}

- (void)dataSourceHasChanged
{
    [super reloadCollectionView];
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
    
    NSIndexPath *selectedIndexPath = nil;
    
    NSUInteger item = [self.collectionViewData indexOfObject:node];
    selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    
    if (node.isFolder)
    {
        [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        
        AlfrescoPermissions *syncNodePermissions = [syncManager permissionsForSyncNode:node];
        if (syncNodePermissions)
        {
            [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)node
                                                                         permissions:syncNodePermissions
                                                                             session:self.session
                                                                navigationController:self.navigationController
                                                                            animated:YES];
        }
        else
        {
            [self.documentFolderService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                if (permissions)
                {
                    [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)node
                                                                                 permissions:permissions
                                                                                     session:self.session
                                                                        navigationController:self.navigationController
                                                                                    animated:YES];
                }
                else
                {
                    NSString *permissionRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", "Permission Retrieval Error"), node.name];
                    displayErrorMessage(permissionRetrievalErrorMessage);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
    }
    else
    {
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

@end
