//
//  SyncViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 30/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncViewController.h"
#import "SyncManager.h"
#import "SyncCell.h"
#import "Utility.h"
#import "PreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "SyncObstaclesViewController.h"
#import "FailedTransferDetailViewController.h"

static NSInteger const kCellHeight = 84;
static CGFloat const kFooterHeight = 32.0f;
static CGFloat const kCellImageViewWidth = 32.0f;
static CGFloat const kCellImageViewHeight = 32.0f;
static NSString * const kSyncInterface = @"SyncViewController";

@interface SyncViewController ()
@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;

@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@end

@implementation SyncViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:kSyncInterface andSession:session];
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
	
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    [self loadSyncNodesForFolder:self.parentNode];
    
    self.title = self.parentNode ? self.parentNode.name : NSLocalizedString(@"Favorites", @"Favorites Title") ;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleSyncObstacles:)
                                                 name:kSyncObstaclesNotification
                                               object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private methods

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    if (folder)
    {
        self.tableViewData = [[[SyncManager sharedManager] topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)self.parentNode] mutableCopy];
        [self hidePullToRefreshView];
    }
    else
    {
        self.tableViewData = [[[SyncManager sharedManager] syncDocumentsAndFoldersForSession:self.session withCompletionBlock:^(NSArray *syncedNodes) {
            if (syncedNodes)
            {
                self.tableViewData = [syncedNodes mutableCopy];
                [self.tableView reloadData];
                [self hidePullToRefreshView];
            }
        }] mutableCopy];
    }
    [self.tableView reloadData];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self loadSyncNodesForFolder:self.parentNode];
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

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *cellIdentifier = kSyncTableCellIdentifier;
    SyncCell *syncCell = [tableView dequeueReusableCellWithIdentifier:kSyncTableCellIdentifier];
    if (nil == syncCell)
    {
        syncCell = (SyncCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SyncCell class]) owner:self options:nil] lastObject];
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:syncCell
                                             selector:@selector(statusChanged:)
                                                 name:kSyncStatusChangeNotification
                                               object:nil];
    
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [[SyncManager sharedManager] syncStatusForNode:node];
    
    syncCell.node = node;
    syncCell.filename.text = node.name;
    
    NSString *modifiedDateString = nil;
    if (nodeStatus.activityType == SyncActivityTypeUpload)
    {
        modifiedDateString = relativeDateFromDate(node.modifiedAt);
        
        // getting downloaded file locally updated Date
        SyncManager *syncManager = [SyncManager sharedManager];
        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
        NSError *dateError = nil;
        NSString *pathToSyncedFile = [syncManager contentPathForNode:(AlfrescoDocument *)node];
        NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:pathToSyncedFile error:&dateError];
        if (!dateError)
        {
            modifiedDateString = relativeDateFromDate([fileAttributes objectForKey:kAlfrescoFileLastModification]);
        }
    }
    else
    {
        modifiedDateString = relativeDateFromDate(node.modifiedAt);
    }
    
    if (node.isFolder)
    {
        syncCell.image.image = imageForType(@"folder");
        syncCell.nodeDetails = modifiedDateString;
    }
    else if (node.isDocument)
    {
        syncCell.image.image = imageForType([node.name pathExtension]);
        syncCell.nodeDetails = [NSString stringWithFormat:@"%@ • %@", modifiedDateString, stringForLongFileSize(((AlfrescoDocument *)node).contentLength)];
    }
    
    [syncCell updateCellWithNodeStatus:nodeStatus propertyChanged:kSyncStatus];
    
    return syncCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *selectedNode = self.tableViewData[indexPath.row];
    
    if (selectedNode.isFolder)
    {
        SyncViewController *controller = [[SyncViewController alloc] initWithParentNode:selectedNode andSession:self.session];
        [self.navigationController pushViewController:controller animated:YES];
    }
    else
    {
        NSString *filePath = [syncManager contentPathForNode:(AlfrescoDocument *)selectedNode];
        if (filePath)
        {
            PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:(AlfrescoDocument *)selectedNode documentPermissions:nil contentFilePath:filePath session:self.session];
            [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
        }
        else
        {
            NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:selectedNode.name];
            NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadDestinationPath append:NO];
            
            [self showHUD];
            [self.documentFolderService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                [self.documentFolderService retrieveContentOfDocument:(AlfrescoDocument *)selectedNode outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                    [self hideHUD];
                    if (succeeded)
                    {
                        PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:(AlfrescoDocument *)selectedNode documentPermissions:permissions contentFilePath:downloadDestinationPath session:self.session];
                        [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
                    }
                    else
                    {
                        // display an error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                    // progress indicator update
                }];
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNode:node];
    
    switch (nodeStatus.status)
    {
        case SyncStatusLoading:
            [syncManager cancelSyncForDocument:(AlfrescoDocument *)node];
            break;
            
        case SyncStatusFailed:
        {
            self.retrySyncNode = node;
            [self showPopoverForFailedSyncNodeAtIndexPath:indexPath];
            break;
        }
            
        default:
        {
            MetaDataViewController *metaDataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:node showingVersionHistoryOption:YES session:self.session];
            [UniversalDevice pushToDisplayViewController:metaDataViewController usingNavigationController:self.navigationController animated:YES];
            break;
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
                                                                                       message:errorDescription];
        
        syncFailedDetailController.closeTarget = self;
        syncFailedDetailController.closeAction = @selector(retrySyncAndCloseRetryPopover:);
        
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

- (void)retrySyncAndCloseRetryPopover:(id)controller
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
    [self loadSyncNodesForFolder:self.parentNode];
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

@end
