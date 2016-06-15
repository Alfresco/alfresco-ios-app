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
 
#import "SyncViewController.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "DocumentPreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "SyncObstaclesViewController.h"
#import "FailedTransferDetailViewController.h"
#import "AccountManager.h"
#import "UserAccount.h"
#import "ThumbnailManager.h"
#import "Constants.h"
#import "PreferenceManager.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "DownloadsDocumentPreviewViewController.h"
#import "SyncNavigationViewController.h"

#import "FileFolderCollectionViewCell.h"
#import "FileFolderCollectionViewController.h"

static CGFloat const kCellHeight = 64.0f;
static CGFloat const kSyncOnSiteRequestsCompletionTimeout = 5.0; // seconds

static NSString * const kVersionSeriesValueKeyPath = @"properties.cmis:versionSeriesId.value";

@interface SyncViewController () <CollectionViewCellAccessoryViewDelegate>

@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, assign) BOOL didSyncAfterSessionRefresh;

@property (nonatomic, strong) UIBarButtonItem *switchLayoutBarButtonItem;

@end

@implementation SyncViewController

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
    
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    
    self.listLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:1 itemHeight:kCellHeight shouldSwipeToDelete:YES hasHeader:NO];
    self.listLayout.dataSourceInfoDelegate = self;
    self.gridLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:3 itemHeight:-1 shouldSwipeToDelete:NO hasHeader:NO];
    self.gridLayout.dataSourceInfoDelegate = self;
    
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
        [self loadSyncNodesForFolder:self.parentNode];
        self.didSyncAfterSessionRefresh = YES;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // if view has already loaded, the user changes selected Account, app will try to sync in viewWillAppear so that Alert to sync wouldn't appear on top of other view e.g Sites, Tasks ...
    if (!self.didSyncAfterSessionRefresh || self.parentNode != nil)
    {
        [self loadSyncNodesForFolder:self.parentNode];
        self.didSyncAfterSessionRefresh = YES;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.parentNode == nil)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewMenuSyncedContent];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reloadCollectionView
{
    [super reloadCollectionView];
    self.collectionView.contentOffset = CGPointMake(0., 0.);
}

#pragma mark - Private Methods

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    if (folder)
    {
        self.collectionViewData = [[SyncManager sharedManager] topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)self.parentNode];
        [self reloadCollectionView];
        [self hidePullToRefreshView];
    }
    else
    {
        self.collectionViewData = [[SyncManager sharedManager] syncDocumentsAndFoldersForSession:self.session withCompletionBlock:^(NSMutableArray *syncedNodes) {
            if (syncedNodes)
            {
                self.collectionViewData = syncedNodes;
                [self reloadCollectionView];
                [self hidePullToRefreshView];
            }
        }];
        [self reloadCollectionView];
    }
}

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

- (void)cancelSync
{
    [[SyncManager sharedManager] cancelAllSyncOperations];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    self.didSyncAfterSessionRefresh = NO;
    self.title = [self listTitle];
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    if (![[SyncManager sharedManager] isFirstUse])
    {
        // Hold off making sync network requests until either the Sites requests have completed, or a timeout period has passed
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSyncOnSiteRequestsCompletionTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            
            if (!self.didSyncAfterSessionRefresh)
            {
                [self loadSyncNodesForFolder:self.parentNode];
                self.didSyncAfterSessionRefresh = YES;
            }
        });
    }
}

- (void)siteRequestsCompleted:(NSNotification *)notification
{
    if (![[SyncManager sharedManager] isFirstUse])
    {
        [self loadSyncNodesForFolder:self.parentNode];
        self.didSyncAfterSessionRefresh = YES;
    }
}

- (void)didAddNodeToFavourites:(NSNotification *)notification
{
    if (!self.parentNode)
    {
        AlfrescoNode *nodeAdded = (AlfrescoNode *)notification.object;
        [self addAlfrescoNodes:@[nodeAdded] completion:nil];
    }
}

- (void)didRemoveNodeFromFavourites:(NSNotification *)notification
{
    if (!self.parentNode)
    {
        AlfrescoNode *nodeRemoved = (AlfrescoNode *)notification.object;
        NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:nodeRemoved.identifier inNodeIdentifiers:[self.collectionViewData valueForKey:@"identifier"]];
        if (indexPath)
        {
            [self.collectionViewData removeObjectAtIndex:indexPath.row];
            [self.collectionView deleteItemsAtIndexPaths:@[indexPath]];
        }
    }
}

- (void)documentDeleted:(NSNotification *)notification
{
    AlfrescoDocument *deletedDocument = notification.object;
    
    if ([self.collectionViewData containsObject:deletedDocument])
    {
        NSUInteger index = [self.collectionViewData indexOfObject:deletedDocument];
        [self.collectionViewData removeObject:deletedDocument];
        NSIndexPath *indexPathOfDeletedNode = [NSIndexPath indexPathForRow:index inSection:0];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPathOfDeletedNode]];
    }
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    AlfrescoDocument *editedDocument = notification.object;
    NSString *editedDocumentIdentifier = [Utility nodeRefWithoutVersionID:editedDocument.identifier];
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:editedDocumentIdentifier inNodeIdentifiers:[self.collectionViewData valueForKeyPath:kVersionSeriesValueKeyPath]];
    
    if (indexPath)
    {
        [self.collectionViewData replaceObjectAtIndex:indexPath.row withObject:editedDocument];
        [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
    }
}

- (void)didUpdatePreference:(NSNotification *)notification
{
    NSString *preferenceKeyChanged = notification.object;
    BOOL isCurrentlyOnCellular = [[ConnectivityManager sharedManager] isOnCellular];
    
    if ([preferenceKeyChanged isEqualToString:kSettingsSyncOnCellularIdentifier] && isCurrentlyOnCellular)
    {
        BOOL shouldSyncOnCellular = [notification.userInfo[kSettingChangedToKey] boolValue];
        
        // if changed to no and is syncing, then cancel sync
        if ([[SyncManager sharedManager] isCurrentlySyncing] && !shouldSyncOnCellular)
        {
            [self cancelSync];
        }
        else if (shouldSyncOnCellular)
        {
            [self loadSyncNodesForFolder:self.parentNode];
        }
    }
}

- (void)accountInfoUpdated:(NSNotification *)notification
{
    [self.navigationController popToRootViewControllerAnimated:NO];
    self.title = [self listTitle];
    
    UserAccount *notificationAccount = notification.object;
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    
    if ((notificationAccount == selectedAccount) && notificationAccount.isSyncOn)
    {
        [self loadSyncNodesForFolder:nil];
    }
    else if (notificationAccount == selectedAccount)
    {
        [self reloadCollectionView];
    }
}

#pragma mark - CollectionViewDataSource methods

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.collectionViewData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileFolderCollectionViewCell *nodeCell = [collectionView dequeueReusableCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier] forIndexPath:indexPath];
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    AlfrescoNode *node = self.collectionViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
    [nodeCell updateCellInfoWithNode:node nodeStatus:nodeStatus];
    [nodeCell registerForNotifications];
    
//    BOOL isSyncOn = [syncManager isNodeInSyncList:node];
    
//    [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:NO animate:NO];
    [favoriteManager isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
//        [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:isFavorite animate:NO];
    }];
    
    BaseCollectionViewFlowLayout *currentLayout = [self layoutForStyle:self.style];
    
    if (node.isFolder)
    {
        if(currentLayout.shouldShowSmallThumbnail)
        {
            [nodeCell.image setImage:smallImageForType(@"folder") withFade:NO];
        }
        else
        {
            [nodeCell.image setImage:largeImageForType(@"folder") withFade:NO];
        }
    }
    else if (node.isDocument)
    {
        AlfrescoDocument *document = (AlfrescoDocument *)node;
        ThumbnailManager *thumbnailManager = [ThumbnailManager sharedManager];
        UIImage *thumbnail = [thumbnailManager thumbnailForDocument:document renditionType:kRenditionImageDocLib];
        
        if (thumbnail)
        {
            [nodeCell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            if(currentLayout.shouldShowSmallThumbnail)
            {
                [nodeCell.image setImage:smallImageForType([document.name pathExtension]) withFade:NO];
            }
            else
            {
                [nodeCell.image setImage:largeImageForType([document.name pathExtension]) withFade:NO];
            }
            [thumbnailManager retrieveImageForDocument:document renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    FileFolderCollectionViewCell *updateCell = (FileFolderCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell)
                    {
                        [updateCell.image setImage:image withFade:YES];
                    }
                }
            }];
        }
    }
    
    nodeCell.accessoryViewDelegate = self;
    return nodeCell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:FileFolderCollectionViewCell.class])
    {
        [(FileFolderCollectionViewCell *)cell removeNotifications];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *selectedNode = self.collectionViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:selectedNode.identifier];
    
    BOOL isSyncOn = [syncManager isSyncPreferenceOn];
    
    if (selectedNode.isFolder)
    {
        ParentCollectionViewController *controller = nil;
        if (isSyncOn)
        {
            controller = [[SyncViewController alloc] initWithParentNode:selectedNode andSession:self.session];
        }
        else
        {
            controller = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderDisplayName:selectedNode.name session:self.session];
        }
        controller.style = self.style;
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        if (nodeStatus.status == SyncStatusLoading)
        {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
            return;
        }
        
        NSString *filePath = [syncManager contentPathForNode:(AlfrescoDocument *)selectedNode];
        AlfrescoPermissions *syncNodePermissions = [syncManager permissionsForSyncNode:selectedNode];
        if (filePath)
        {
            if ([[ConnectivityManager sharedManager] hasInternetConnection])
            {
                [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                               permissions:syncNodePermissions
                                                                               contentFile:filePath
                                                                          documentLocation:InAppDocumentLocationSync
                                                                                   session:self.session
                                                                      navigationController:self.navigationController
                                                                                  animated:YES];
            }
            else
            {
                [UniversalDevice pushToDisplayDownloadDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                                       permissions:nil
                                                                                       contentFile:filePath
                                                                                  documentLocation:InAppDocumentLocationSync
                                                                                           session:self.session
                                                                              navigationController:self.navigationController
                                                                                          animated:YES];
            }
        }
        else if ([[ConnectivityManager sharedManager] hasInternetConnection])
        {
            [self showHUD];
            [self.documentFolderService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                
                [self hideHUD];
                if (!error)
                {
                    [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                                   permissions:permissions
                                                                                   contentFile:filePath
                                                                              documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                       session:self.session
                                                                          navigationController:self.navigationController
                                                                                      animated:YES];
                }
                else
                {
                    // display an error
                    NSString *permissionRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", "Permission Retrieval Error"), selectedNode.name];
                    displayErrorMessage(permissionRetrievalErrorMessage);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
    }
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    SyncManager *syncManager = [SyncManager sharedManager];
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

- (void)showPopoverForFailedSyncNodeAtIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
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
        [self.retrySyncPopover setPopoverContentSize:syncFailedDetailController.view.frame.size];
        
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        
        if (cell.accessoryView.window != nil)
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
    [[SyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
    [self.retrySyncPopover dismissPopoverAnimated:YES];
    self.retrySyncNode = nil;
    self.retrySyncPopover = nil;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadSyncNodesForFolder:self.parentNode];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadSyncNodesForFolder:self.parentNode];
            }
        }];
    }
}

#pragma mark - Private Class Functions

- (void)handleSyncObstacles:(NSNotification *)notification
{
    NSMutableDictionary *syncObstacles = [[notification.userInfo objectForKey:kSyncObstaclesKey] mutableCopy];
    
    if (syncObstacles)
    {
        SyncObstaclesViewController *syncObstaclesController = [[SyncObstaclesViewController alloc] initWithErrors:syncObstacles];
        syncObstaclesController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        UINavigationController *syncObstaclesNavigationController = [[UINavigationController alloc] initWithRootViewController:syncObstaclesController];
        [UniversalDevice displayModalViewController:syncObstaclesNavigationController onController:self withCompletionBlock:nil];
    }
}

#pragma mark UIAlertView delegate methods

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != alertView.cancelButtonIndex)
    {
        [[SyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
        self.retrySyncNode = nil;
    }
}

#pragma mark - Connectivity Notification Methods

// @Override
- (void)connectivityChanged:(NSNotification *)notification
{
    BOOL hasInternet = [notification.object boolValue];
    if (hasInternet && self.parentNode == nil)
    {
        [self enablePullToRefresh];
        [self loadSyncNodesForFolder:self.parentNode];
    }
    else
    {
        [self disablePullToRefresh];
    }
}

#pragma mark - Upload Node Notification

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *infoDictionary = notification.object;
    AlfrescoFolder *parentFolder = [infoDictionary objectForKey:kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([parentFolder.identifier isEqualToString:self.parentNode.identifier])
    {
        AlfrescoNode *subnode = [infoDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        [self addAlfrescoNodes:@[subnode] completion:nil];
    }
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

#pragma mark - DataSourceInformationProtocol methods
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

#pragma mark - Private methods
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

#pragma mark - Actions methods
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
