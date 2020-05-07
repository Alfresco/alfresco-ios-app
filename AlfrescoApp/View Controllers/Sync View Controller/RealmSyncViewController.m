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

#import "RealmSyncViewController.h"
#import "BaseFileFolderCollectionViewController+Internal.h"
#import "ConnectivityManager.h"
#import "SyncCollectionViewDataSource.h"
#import "UniversalDevice.h"
#import "PreferenceManager.h"
#import "AccountManager.h"
#import "SyncObstaclesViewController.h"
#import "SyncNavigationViewController.h"
#import "FailedTransferDetailViewController.h"
#import "FileFolderCollectionViewCell.h"
#import "ALFSwipeToDeleteGestureRecognizer.h"
#import "AlfrescoNode+Sync.h"

static CGFloat const kSyncOnSiteRequestsCompletionTimeout = 5.0; // seconds

static NSString * const kVersionSeriesValueKeyPath = @"properties.cmis:versionSeriesId.value";

@interface RealmSyncViewController () < RepositoryCollectionViewDataSourceDelegate >

@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, assign) BOOL didSyncAfterSessionRefresh;

@end

@implementation RealmSyncViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.session = session;
        self.parentNode = node;
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
    self.hasRequestFinished = NO;
    
    [self changeCollectionViewStyle:self.style animated:YES];
    
    [self addNotificationListeners];
    
    if (!self.didSyncAfterSessionRefresh || self.parentNode != nil)
    {
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        [self loadSyncNodesForFolder:self.parentNode];
        [self reloadCollectionView];
        self.didSyncAfterSessionRefresh = YES;
    }
    
    [[RealmSyncManager sharedManager] presentSyncObstaclesIfNeeded];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewMenuSyncedContent];
    
    [self adjustCollectionViewForProgressView:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private methods
- (void)reloadCollectionView
{
    [super reloadCollectionView];
    self.collectionView.contentOffset = CGPointZero;
}

- (void)addNotificationListeners
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(siteRequestsCompleted:)
                                                 name:kAlfrescoSiteRequestsCompletedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSyncObstacles:)
                                                 name:kSyncObstaclesNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didUpdatePreference:)
                                                 name:kSettingsDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(adjustCollectionViewForProgressView:)
                                                 name:kSyncProgressViewVisiblityChangeNotification
                                               object:nil];
}

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    self.dataSource = [[SyncCollectionViewDataSource alloc] initWithParentNode:self.parentNode session:self.session delegate:self];
    
    self.listLayout.dataSourceInfoDelegate = self.dataSource;
    self.gridLayout.dataSourceInfoDelegate = self.dataSource;
    self.collectionView.dataSource = self.dataSource;
    
    self.title = self.dataSource.screenTitle;
    
    [self reloadCollectionView];
    [self hidePullToRefreshView];
}

- (void)cancelSync
{
    [[RealmSyncManager sharedManager] cancelAllSyncOperations];
}

#pragma mark - UICollectionViewDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
    AlfrescoNode *selectedNode = [self.dataSource alfrescoNodeAtIndex:indexPath.row];
    
    if (selectedNode.isFolder)
    {
        RealmSyncViewController *controller = [[RealmSyncViewController alloc] initWithParentNode:selectedNode andSession:self.session];
        controller.style = self.style;
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        NSString *filePath = [[RealmSyncCore sharedSyncCore] contentPathForNode:selectedNode forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];
        AlfrescoPermissions *syncNodePermissions = [syncManager permissionsForSyncNode:selectedNode];
        
        void (^displayPermissionRetrievalError)(NSError *) = ^void (NSError *error){
            NSString *permissionRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", "Permission Retrieval Error"), selectedNode.name];
            displayErrorMessage(permissionRetrievalErrorMessage);
            [Notifier notifyWithAlfrescoError:error];
        };
        
        void (^pushToDisplayDocumentPreviewController)(AlfrescoPermissions *, InAppDocumentLocation) = ^void (AlfrescoPermissions *permissions, InAppDocumentLocation location){
            [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                           permissions:permissions
                                                                           contentFile:filePath
                                                                      documentLocation:location
                                                                               session:self.session
                                                                  navigationController:self.navigationController
                                                                              animated:YES];
        };
        
        void (^retrievePermissionsAndPushToDisplayPreviewController)(InAppDocumentLocation) = ^void (InAppDocumentLocation location){
            [self showHUD];
            __weak typeof(self) weakSelf = self;
            [self.documentFolderService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                [weakSelf hideHUD];
                if (error)
                {
                    displayPermissionRetrievalError(error);
                }
                else if (location == InAppDocumentLocationFilesAndFolders)
                {
                    pushToDisplayDocumentPreviewController(permissions, InAppDocumentLocationFilesAndFolders);
                }
                
                if (location == InAppDocumentLocationSync)
                {
                    pushToDisplayDocumentPreviewController(permissions, InAppDocumentLocationSync);
                }
            }];
        };
        
        if (filePath)
        {
            if ([[ConnectivityManager sharedManager] hasInternetConnection])
            {
                if (syncNodePermissions)
                {
                    pushToDisplayDocumentPreviewController(syncNodePermissions, InAppDocumentLocationSync);
                }
                else
                {
                    retrievePermissionsAndPushToDisplayPreviewController(InAppDocumentLocationSync);
                }
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
            retrievePermissionsAndPushToDisplayPreviewController(InAppDocumentLocationFilesAndFolders);
        }
        else
        {
            pushToDisplayDocumentPreviewController(syncNodePermissions, InAppDocumentLocationFilesAndFolders);
        }
    }
}

#pragma mark - Notifications methods
- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    self.didSyncAfterSessionRefresh = NO;
    self.dataSource.session = session;
    self.title = self.dataSource.screenTitle;
    
    [self.navigationController popToRootViewControllerAnimated:YES];
    // Hold off making sync network requests until either the Sites requests have completed, or a timeout period has passed
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(kSyncOnSiteRequestsCompletionTimeout * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if (!self.didSyncAfterSessionRefresh)
        {
            [self loadSyncNodesForFolder:self.parentNode];
            self.didSyncAfterSessionRefresh = YES;
        }
    });
}

- (void)siteRequestsCompleted:(NSNotification *)notification
{
    [self loadSyncNodesForFolder:self.parentNode];
    self.didSyncAfterSessionRefresh = YES;
}

- (void)didUpdatePreference:(NSNotification *)notification
{
    NSString *preferenceKeyChanged = notification.object;
    BOOL isCurrentlyOnCellular = [[ConnectivityManager sharedManager] isOnCellular];
    
    if ([preferenceKeyChanged isEqualToString:kSettingsSyncOnCellularIdentifier] && isCurrentlyOnCellular)
    {
        BOOL shouldSyncOnCellular = [notification.userInfo[kSettingChangedToKey] boolValue];
        
        // if changed to no and is syncing, then cancel sync
        if ([[RealmSyncManager sharedManager] isCurrentlySyncing] && !shouldSyncOnCellular)
        {
            [self cancelSync];
        }
        else if (shouldSyncOnCellular)
        {
            [self loadSyncNodesForFolder:self.parentNode];
        }
    }
}

- (void)adjustCollectionViewForProgressView:(NSNotification *)notification
{
    id navigationController = self.navigationController;
    
    if((notification) && (notification.object) && (navigationController != notification.object) && ([navigationController conformsToProtocol: @protocol(RealmSyncManagerProgressDelegate)]))
    {
        /* The sender is not the navigation controller of this view controller, but the navigation controller of another instance of SyncViewController (namely the favorites view controller
         which was created when the account was first added). Will update the progress delegate on SyncManager to be able to show the progress view. The cause of this problem is a timing issue
         between begining the syncing process, menu reloading and delegate calls and notifications going around from component to component.
         */
        [RealmSyncManager sharedManager].progressDelegate = navigationController;
    }
    
    if ([navigationController isKindOfClass:[SyncNavigationViewController class]])
    {
        SyncNavigationViewController *syncNavigationController = (SyncNavigationViewController *)navigationController;
        
        UIEdgeInsets edgeInset = UIEdgeInsetsZero;
        if ([syncNavigationController isProgressViewVisible])
        {
            edgeInset = UIEdgeInsetsMake(0.0, 0.0, [syncNavigationController progressViewHeight], 0.0);
        }
        self.collectionView.contentInset = edgeInset;
    }
}

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

- (void)connectivityChanged:(NSNotification *)notification
{
    [super connectivityChanged:notification];
    [self loadSyncNodesForFolder:self.parentNode];
}

#pragma mark - UIRefreshControl Functions

- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
{
    self.editBarButtonItem.enabled = NO;
    [self showLoadingTextInRefreshControl:refreshControl];
    
    // Verify Internet connection.
    if (![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        return;
    }

    [[RealmSyncManager sharedManager] refreshWithCompletionBlock:^(BOOL completed){
        [self hidePullToRefreshView];
    }];
}

@end
