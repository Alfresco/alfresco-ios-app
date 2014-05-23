//
//  SyncViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 30/09/2013.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "SyncViewController.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "AlfrescoNodeCell.h"
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
#import "FileFolderListViewController.h"
#import "LoginManager.h"
#import "DownloadsDocumentPreviewViewController.h"
#import "SyncNavigationViewController.h"

static CGFloat const kCellHeight = 64.0f;
static CGFloat const kSyncOnSiteRequestsCompletionTimeout = 5.0; // seconds

@interface SyncViewController ()

@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, assign) BOOL didSyncAfterSessionRefresh;

@end

@implementation SyncViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
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
	
    if (!self.didSyncAfterSessionRefresh || self.parentNode != nil)
    {
        self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        [self loadSyncNodesForFolder:self.parentNode];
        self.didSyncAfterSessionRefresh = YES;
    }
    
    if (self.parentNode != nil || ![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        [self disablePullToRefresh];
    }
    
    self.title = [self listTitle];
    [self adjustTableViewForProgressView];
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
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
                                             selector:@selector(adjustTableViewForProgressView)
                                                 name:kSyncProgressViewVisiblityChangeNotification
                                               object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Methods

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    if (folder)
    {
        self.tableViewData = [[SyncManager sharedManager] topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)self.parentNode];
        [self.tableView reloadData];
        [self hidePullToRefreshView];
    }
    else
    {
        self.tableViewData = [[SyncManager sharedManager] syncDocumentsAndFoldersForSession:self.session withCompletionBlock:^(NSMutableArray *syncedNodes) {
            if (syncedNodes)
            {
                self.tableViewData = syncedNodes;
                [self.tableView reloadData];
                [self hidePullToRefreshView];
            }
        }];
        [self.tableView reloadData];
    }
}

- (NSString *)listTitle
{
    NSString *title = @"";
    BOOL isSyncOn = [[SyncManager sharedManager] isSyncPreferenceOn];
    
    if (self.parentNode)
    {
        title = self.parentNode.name;
    }
    else
    {
        title = isSyncOn ? NSLocalizedString(@"sync.title", @"Sync Title") : NSLocalizedString(@"favourites.title", @"Favorites Title");
    }
    
    self.tableView.emptyMessage = isSyncOn ? NSLocalizedString(@"sync.empty", @"No Synced Content") : NSLocalizedString(@"favourites.empty", @"No Favorites");
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
        [self addAlfrescoNodes:@[nodeAdded] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)didRemoveNodeFromFavourites:(NSNotification *)notification
{
    if (!self.parentNode)
    {
        AlfrescoNode *nodeRemoved = (AlfrescoNode *)notification.object;
        NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:nodeRemoved.identifier inNodeIdentifiers:[self.tableViewData valueForKey:@"identifier"]];
        if (indexPath)
        {
            [self.tableViewData removeObjectAtIndex:indexPath.row];
            [self.tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }
}

- (void)documentDeleted:(NSNotification *)notifictation
{
    AlfrescoDocument *deletedDocument = notifictation.object;
    
    if ([self.tableViewData containsObject:deletedDocument])
    {
        NSUInteger index = [self.tableViewData indexOfObject:deletedDocument];
        [self.tableViewData removeObject:deletedDocument];
        NSIndexPath *indexPathOfDeletedNode = [NSIndexPath indexPathForRow:index inSection:0];
        [self.tableView deleteRowsAtIndexPaths:@[indexPathOfDeletedNode] withRowAnimation:UITableViewRowAnimationFade];
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
        [self.tableView reloadData];
    }
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *nodeCell = [tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
    [nodeCell updateCellInfoWithNode:node nodeStatus:nodeStatus];
    [nodeCell registerForNotifications];
    
    BOOL isSyncOn = [syncManager isNodeInSyncList:node];
    
    [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:NO animate:NO];
    [favoriteManager isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:isFavorite animate:NO];
    }];
    
    if (node.isFolder)
    {
        [nodeCell.image setImage:smallImageForType(@"folder") withFade:NO];
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
            [nodeCell.image setImage:smallImageForType([document.name pathExtension]) withFade:NO];
            [thumbnailManager retrieveImageForDocument:document renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
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
    return nodeCell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([cell isKindOfClass:AlfrescoNodeCell.class])
    {
        [(AlfrescoNodeCell *)cell removeNotifications];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *selectedNode = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:selectedNode.identifier];
    
    BOOL isSyncOn = [syncManager isSyncPreferenceOn];
    
    if (selectedNode.isFolder)
    {
        UIViewController *controller = nil;
        if (isSyncOn)
        {
            controller = [[SyncViewController alloc] initWithParentNode:selectedNode andSession:self.session];
        }
        else
        {
            controller = [[FileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderDisplayName:selectedNode.name session:self.session];
        }
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        if (nodeStatus.status == SyncStatusLoading)
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
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
                [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
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

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
    
    if (node.isFolder)
    {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
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
                [syncManager cancelSyncForDocumentWithIdentifier:node.identifier inAccountWithId:[[[AccountManager sharedManager] selectedAccount] accountIdentifier]];
                break;
            }
            case SyncStatusFailed:
            {
                self.retrySyncNode = node;
                [self showPopoverForFailedSyncNodeAtIndexPath:indexPath];
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
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    NSString *errorDescription = [syncManager syncErrorDescriptionForNode:node];
    
    if (IS_IPAD)
    {
        FailedTransferDetailViewController *syncFailedDetailController = nil;
        
        syncFailedDetailController = [[FailedTransferDetailViewController alloc] initWithTitle:NSLocalizedString(@"sync.state.failed-to-sync", @"Upload failed popover title")
                                                                                       message:errorDescription retryCompletionBlock:^(BOOL retry) {
                                                                                           if (retry)
                                                                                           {
                                                                                               [self retrySyncAndCloseRetryPopover];
                                                                                           }
                                                                                       }];
        
        self.retrySyncPopover = [[UIPopoverController alloc] initWithContentViewController:syncFailedDetailController];
        [self.retrySyncPopover setPopoverContentSize:syncFailedDetailController.view.frame.size];
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
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
    [[SyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode];
    [self.retrySyncPopover dismissPopoverAnimated:YES];
    self.retrySyncNode = nil;
    self.retrySyncPopover = nil;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
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
        [[SyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode];
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
        [self addAlfrescoNodes:@[subnode] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)adjustTableViewForProgressView
{
    id navigationController = self.navigationController;
    if ([navigationController isKindOfClass:[SyncNavigationViewController class]])
    {
        SyncNavigationViewController *syncNavigationController = (SyncNavigationViewController *)navigationController;
        
        UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, 0.0, 0.0);
        if ([syncNavigationController isProgressViewVisible])
        {
            edgeInset = UIEdgeInsetsMake(0.0, 0.0, [syncNavigationController progressViewHeight], 0.0);
        }
        self.tableView.contentInset = edgeInset;
    }
}

@end
