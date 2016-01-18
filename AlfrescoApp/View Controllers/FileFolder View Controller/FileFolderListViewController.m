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
 
#import "FileFolderListViewController.h"
#import "UniversalDevice.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NavigationViewController.h"
#import "MetaDataViewController.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "LocationManager.h"
#import <ImageIO/ImageIO.h>
#import "AccountManager.h"
#import "DocumentPreviewViewController.h"
#import "TextFileViewController.h"

#import "FailedTransferDetailViewController.h"

#import <AssetsLibrary/AssetsLibrary.h>

static CGFloat const kCellHeight = 64.0f;

static CGFloat const kSearchBarDisabledAlpha = 0.7f;
static CGFloat const kSearchBarEnabledAlpha = 1.0f;
static CGFloat const kSearchBarAnimationDuration = 0.2f;

@interface FileFolderListViewController () <UISearchControllerDelegate>

@property (nonatomic, strong) AlfrescoPermissions *folderPermissions;
@property (nonatomic, strong) NSString *folderDisplayName;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) AlfrescoFolder *initialFolder;
@property (nonatomic, assign) UIBarButtonItem *alertControllerSender;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSMutableDictionary *nodePermissions;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, assign) BOOL capturingMedia;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, weak) IBOutlet MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *multiSelectToolbarHeightConstraint;

@end

@implementation FileFolderListViewController

- (id)initWithFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:nil folderDisplayName:nil session:session];
}

- (id)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:nil folderDisplayName:displayName session:session];
}

- (id)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:permissions folderDisplayName:nil session:session];
}

- (id)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:@"FileFolderListViewController" andSession:session];
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
        self.initialFolder = folder;
        self.folderPermissions = permissions;
        self.folderDisplayName = (displayName) ? displayName : folder.name;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentUpdated:)
                                                     name:kAlfrescoDocumentUpdatedOnServerNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentDeleted:)
                                                     name:kAlfrescoDocumentDeletedOnServerNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(nodeAdded:)
                                                     name:kAlfrescoNodeAddedOnServerNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(documentUpdatedOnServer:)
                                                     name:kAlfrescoSaveBackRemoteComplete
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(editingDocumentCompleted:)
                                                     name:kAlfrescoDocumentEditedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(connectivityStatusChanged:)
                                                     name:kAlfrescoConnectivityChangedNotification
                                                    object:nil];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    }
    
    self.title = self.folderDisplayName;
    self.nodePermissions = [[NSMutableDictionary alloc] init];
    
    if (!IS_IPAD)
    {
        // hide search bar initially
        self.tableView.contentOffset = CGPointMake(0., 40.);
    }
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // search controller
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.delegate = self;
    searchController.searchBar.delegate = self;
    
    searchController.dimsBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = YES;
    
    // search bar
    self.searchBar = searchController.searchBar;
    self.searchBar.frame = CGRectMake(view.frame.origin.x,
                                      view.frame.origin.y,
                                      view.frame.size.width,
                                      44.0f);
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor whiteColor];
    
    self.searchController = searchController;
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.searchBar;
    
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
    
    if (self.initialFolder)
    {
        self.displayFolder = self.initialFolder;
    }
    else
    {
        [self loadContentOfFolder];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.tableView.isEditing)
    {
        self.tableView.editing = NO;
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self selectIndexPathForAlfrescoNodeInDetailView];
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    [self.tableView setAllowsMultipleSelectionDuringEditing:editing];
    [self.tableView setEditing:editing animated:animated];
    [self updateUIUsingFolderPermissionsWithAnimation:YES];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    
    [UIView animateWithDuration:kSearchBarAnimationDuration animations:^{
        self.searchBar.alpha = editing ? kSearchBarDisabledAlpha : kSearchBarEnabledAlpha;
    }];
    self.searchBar.userInteractionEnabled = !editing;
    
    if (editing)
    {
        [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:nil];
        [self disablePullToRefresh];
        [self.multiSelectToolbar enterMultiSelectMode:self.multiSelectToolbarHeightConstraint];
    }
    else
    {
        [self enablePullToRefresh];
        [self.multiSelectToolbar leaveMultiSelectMode:self.multiSelectToolbarHeightConstraint];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _imagePickerController.delegate = nil;
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

#pragma mark - Private Functions

- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder usingListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (!error)
        {
            for (AlfrescoNode *node in pagingResult.objects)
            {
                [self retrievePermissionsForNode:node];
            }
        }
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
        }
        
        [self selectIndexPathForAlfrescoNodeInDetailView];
        [self updateUIUsingFolderPermissionsWithAnimation:NO];
    }];
}

- (void)retrieveAndSetPermissionsOfCurrentFolder
{
    [self.documentService retrievePermissionsOfNode:self.displayFolder completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (permissions)
        {
            self.folderPermissions = permissions;
            [self updateUIUsingFolderPermissionsWithAnimation:NO];
        }
        else
        {
            // display error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission retrieval failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (void)retrievePermissionsForNode:(AlfrescoNode *)node
{
    [self.documentService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (!error)
        {
            [self.nodePermissions setValue:permissions forKey:node.identifier];
        }
    }];
}

- (void)performEditBarButtonItemAction:(UIBarButtonItem *)sender
{
    [self setEditing:!self.tableView.editing animated:YES];
}

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated
{
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    
    // update the UI based on permissions
    if (!self.tableView.editing)
    {
        self.editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                               target:self
                                                                               action:@selector(performEditBarButtonItemAction:)];
    }
    else
    {
        self.editBarButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                               target:self
                                                                               action:@selector(performEditBarButtonItemAction:)];
    }
    
    self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
    [rightBarButtonItems addObject:self.editBarButtonItem];
    
    if (!self.tableView.isEditing && (self.folderPermissions.canAddChildren || self.folderPermissions.canEdit))
    {
        [rightBarButtonItems addObject:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                     target:self
                                                                                     action:@selector(displayActionSheet:event:)]];
    }
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:animated];
}

- (void)displayActionSheet:(id)sender event:(UIEvent *)event
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.folderPermissions.canAddChildren)
    {
        [alertController addAction:[self alertActionCreateFile]];
        [alertController addAction:[self alertActionAddFolder]];
        [alertController addAction:[self alertActionUpload]];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [alertController addAction:[self alertActionTakePhotoOrVideo]];
        }
        
        [alertController addAction:[self alertActionRecordAudio]];
    }

    [alertController addAction:[self alertActionCancel]];
    
    self.alertControllerSender = sender;

    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.barButtonItem = sender;
    [self presentViewController:alertController animated:YES completion:nil];
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
        TextFileViewController *textFileViewController = [[TextFileViewController alloc] initWithUploadFileDestinationFolder:self.displayFolder session:self.session delegate:self];
        NavigationViewController *textFileViewNavigationController = [[NavigationViewController alloc] initWithRootViewController:textFileViewController];
        [UniversalDevice displayModalViewController:textFileViewNavigationController onController:[UniversalDevice revealViewController] withCompletionBlock:nil];
    }];
}

- (UIAlertAction *)alertActionAddFolder
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.addfolder", @"Create Folder") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
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
                [self.documentService createFolderWithName:desiredFolderName inParentFolder:self.displayFolder properties:nil completionBlock:^(AlfrescoFolder *folder, NSError *error) {
                    if (folder)
                    {
                        [self retrievePermissionsForNode:folder];
                        [self addAlfrescoNodes:@[folder] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self updateUIUsingFolderPermissionsWithAnimation:NO];
                    }
                    else
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.createfolder.createfolder", @"Creation failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.createfolder.invalidname", @"Creation failed")]);
            }
        }]];
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
        
        UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
        popoverPresenter.barButtonItem = self.alertControllerSender;
        [self presentViewController:alertController animated:YES completion:nil];
    }];
}

- (UIAlertAction *)alertActionUploadExistingPhotos
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotos", @"Choose Photo Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
    }];
}

- (UIAlertAction *)alertActionUploadExistingPhotosOrVideos
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
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
        // start location services
        [[LocationManager sharedManager] startLocationUpdates];
        
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
    }];
}

- (UIAlertAction *)alertActionTakePhotoOrVideo
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        // start location services
        [[LocationManager sharedManager] startLocationUpdates];
        
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
        [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
    }];
}

- (UIAlertAction *)alertActionRecordAudio
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UploadFormViewController *audioRecorderViewController = [[UploadFormViewController alloc] initWithSession:self.session createAndUploadAudioToFolder:self.displayFolder delegate:self];
        NavigationViewController *audioRecorderNavigationController = [[NavigationViewController alloc] initWithRootViewController:audioRecorderViewController];
        [UniversalDevice displayModalViewController:audioRecorderNavigationController onController:self.navigationController withCompletionBlock:nil];
    }];
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

- (void)loadContentOfFolder
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        // if the display folder is not set, use the root view controller
        if (!self.displayFolder)
        {
            [self showHUD];
            AlfrescoFolder *rootFolder = [self.session rootFolder];
            if (rootFolder)
            {
                self.displayFolder = rootFolder;
                self.navigationItem.title = rootFolder.name;
                [self retrieveAndSetPermissionsOfCurrentFolder];
                [self hidePullToRefreshView];
            }
            else
            {
                [self.documentService retrieveRootFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                    if (folder)
                    {
                        self.displayFolder = folder;
                        self.navigationItem.title = folder.name;
                        [self retrieveAndSetPermissionsOfCurrentFolder];
                        [self hidePullToRefreshView];
                    }
                    else
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
        }
        else
        {
            [self showHUD];
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                // folder permissions not set, retrieve and update the UI
                if (!self.folderPermissions)
                {
                    [self retrieveAndSetPermissionsOfCurrentFolder];
                }
                else
                {
                    [self updateUIUsingFolderPermissionsWithAnimation:NO];
                }
                
                [self hideHUD];
                [self hidePullToRefreshView];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }];
        }
    }
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.displayFolder = nil;
    self.tableView.tableHeaderView = nil;
    
    [self createAlfrescoServicesWithSession:session];
    
    if (session && [self shouldRefresh])
    {
        [self loadContentOfFolder];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (self.isDisplayingSearch)
    {
        selectedNode = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        selectedNode = [self.tableViewData objectAtIndex:indexPath.row];
    }
    
    if (selectedNode.isFolder)
    {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            if (permissions)
            {
                [UniversalDevice pushToDisplayFolderPreviewControllerForAlfrescoDocument:(AlfrescoFolder *)selectedNode
                                                                             permissions:permissions
                                                                                 session:self.session
                                                                    navigationController:self.navigationController
                                                                                animated:YES];
            }
            else
            {
                NSString *permissionRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", "Permission Retrieval Error"), selectedNode.name];
                displayErrorMessage(permissionRetrievalErrorMessage);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        SyncManager *syncManager = [SyncManager sharedManager];
        SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:selectedNode.identifier];
        
        switch (nodeStatus.status)
        {
            case SyncStatusLoading:
            {
                [syncManager cancelSyncForDocumentWithIdentifier:selectedNode.identifier];
                break;
            }
            case SyncStatusFailed:
            {
                self.retrySyncNode = selectedNode;
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

- (void)selectIndexPathForAlfrescoNodeInDetailView
{
    NSArray *tableNodeIdentifiers = [self.tableViewData valueForKeyPath:@"identifier"];
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:[UniversalDevice detailViewItemIdentifier] inNodeIdentifiers:tableNodeIdentifiers];
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
}

- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    __weak FileFolderListViewController *weakSelf = self;
    [self.documentService deleteNode:nodeToDelete completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            if ([[UniversalDevice detailViewItemIdentifier] isEqualToString:nodeToDelete.identifier])
            {
                [UniversalDevice clearDetailViewController];
            }
            
            NSArray *tableNodeIdentifiers = nil;
            NSIndexPath *indexPathForNode = nil;
            
            // remove nodeToDelete from search tableview if search view is present
            if (weakSelf.isDisplayingSearch)
            {
                tableNodeIdentifiers = [weakSelf.searchResults valueForKeyPath:@"identifier"];
                [weakSelf.searchResults removeObject:nodeToDelete];
                indexPathForNode = [weakSelf indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:tableNodeIdentifiers];
                if (indexPathForNode != nil)
                {
                    [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            
            // remove nodeToDelete from tableview
            tableNodeIdentifiers = [weakSelf.tableViewData valueForKeyPath:@"identifier"];
            if (weakSelf.isDisplayingSearch)
            {
                [tableNodeIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger index, BOOL *stop) {
                    if ([identifier isEqualToString:nodeToDelete.identifier])
                    {
                        [weakSelf.tableViewData removeObjectAtIndex:index];
                        *stop = YES;
                    }
                }];
            }
            else
            {
                [weakSelf.tableViewData removeObject:nodeToDelete];
            }
            indexPathForNode = [self indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:tableNodeIdentifiers];
            if (indexPathForNode != nil)
            {
                [weakSelf.tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
                [weakSelf updateUIUsingFolderPermissionsWithAnimation:NO];
            }
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.unable.to.delete", @"Unable to delete file/folder"), [ErrorDescriptions descriptionForError:error]]);
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(succeeded);
        }
    }];
}

- (void)deleteNodes:(NSArray *)nodes completionBlock:(void (^)(NSInteger numberDeleted, NSInteger numberFailed))completionBlock
{
    __block NSInteger numberOfDocumentsToBeDeleted = nodes.count;
    __block int numberOfSuccessfulDeletes = 0;
    
    for (AlfrescoNode *node in nodes)
    {
        [self deleteNode:node completionBlock:^(BOOL success) {
            if (success)
            {
                numberOfSuccessfulDeletes++;
            }
            
            numberOfDocumentsToBeDeleted--;
            if (numberOfDocumentsToBeDeleted == 0 && completionBlock != NULL)
            {
                if (completionBlock)
                {
                    completionBlock(numberOfSuccessfulDeletes, nodes.count - numberOfSuccessfulDeletes);
                }
            }
        }];
    }
}

- (void)confirmDeletingMultipleNodes
{
    NSString *titleKey = (self.multiSelectToolbar.selectedItems.count == 1) ? @"multiselect.delete.confirmation.message.one-item" : @"multiselect.delete.confirmation.message.n-items";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(titleKey, @"Are you sure you want to delete x items"), self.multiSelectToolbar.selectedItems.count];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteMultiSelectedNodes];
    }]];
    [alertController addAction:[self alertActionCancel]];
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.sourceView = self.multiSelectToolbar;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteMultiSelectedNodes
{
    [self setEditing:NO animated:YES];
    [self showHUD];
    [self deleteNodes:self.multiSelectToolbar.selectedItems completionBlock:^(NSInteger numberDeleted, NSInteger numberFailed) {
        [self hideHUD];
        if (numberFailed == 0)
        {
            displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"multiselect.delete.completed.message", @"%@ files were deleted from the server."), @(numberDeleted)]);
        }
        else if (numberDeleted == 0)
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"multiselect.delete.failure.message", @"None of the files could be deleted from the server."),
                                         NSLocalizedString(@"multiselect.delete.completed.title", @"Delete Completed With Errors"));
        }
        else
        {
            displayErrorMessageWithTitle([NSString stringWithFormat:NSLocalizedString(@"multiselect.delete.partial.message", @"Only %@ files were deleted from the server."), @(numberDeleted)],
                                         NSLocalizedString(@"multiselect.delete.completed.title", @"Delete Completed With Errors"));
        }
    }];
}

- (void)documentUpdated:(NSNotification *)notification
{
    id updatedDocumentObject = notification.object;
    id existingDocumentObject = notification.userInfo[kAlfrescoDocumentUpdatedFromDocumentParameterKey];
    
    // this should always be an AlfrescoDocument. If it isn't something has gone terribly wrong...
    if ([updatedDocumentObject isKindOfClass:[AlfrescoDocument class]])
    {
        AlfrescoDocument *existingDocument = (AlfrescoDocument *)existingDocumentObject;
        AlfrescoDocument *updatedDocument = (AlfrescoDocument *)updatedDocumentObject;
        
        NSArray *allIdentifiers = [self.tableViewData valueForKey:@"identifier"];
        if ([allIdentifiers containsObject:existingDocument.identifier])
        {
            NSUInteger index = [allIdentifiers indexOfObject:existingDocument.identifier];
            [self.tableViewData replaceObjectAtIndex:index withObject:updatedDocument];
            NSIndexPath *indexPathOfDocument = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSIndexPath *selectedIndexPath = [self.tableView indexPathForSelectedRow];
            [self.tableView reloadRowsAtIndexPaths:@[indexPathOfDocument] withRowAnimation:UITableViewRowAnimationFade];
            
            // reselect the row after it has been updated
            if (selectedIndexPath.row == indexPathOfDocument.row)
            {
                [self.tableView selectRowAtIndexPath:selectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
            }
        }
    }
    else
    {
        @throw ([NSException exceptionWithName:@"AlfrescoNode update exception in FileFolderListViewController - (void)documentUpdated:"
                                        reason:@"No document node returned from the edit file service"
                                      userInfo:nil]);
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

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *foldersDictionary = notification.object;
    
    AlfrescoFolder *parentFolder = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([parentFolder isEqual:self.displayFolder])
    {
        AlfrescoNode *subnode = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        [self addAlfrescoNodes:@[subnode] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)documentUpdatedOnServer:(NSNotification *)notification
{
    NSString *nodeIdentifierUpdated = notification.object;
    AlfrescoDocument *updatedDocument = notification.userInfo[kAlfrescoDocumentUpdatedFromDocumentParameterKey];

    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:nodeIdentifierUpdated inNodeIdentifiers:[self.tableViewData valueForKey:@"identifier"]];
    
    if (indexPath)
    {
        [self.tableViewData replaceObjectAtIndex:indexPath.row withObject:updatedDocument];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    AlfrescoDocument *editedDocument = notification.object;
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:editedDocument.name inNodeIdentifiers:[self.tableViewData valueForKey:@"name"]];
    
    if (indexPath)
    {
        [self.tableViewData replaceObjectAtIndex:indexPath.row withObject:editedDocument];
        [self.tableView reloadRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
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

- (void)showSearchProgressHUD
{
    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [self.tableView addSubview:self.searchProgressHUD];
    [self.searchProgressHUD show:YES];
}

- (void)hideSearchProgressHUD
{
    [self.searchProgressHUD hide:YES];
    self.searchProgressHUD = nil;
}

- (void)connectivityStatusChanged:(NSNotification *)notification
{
    NSNumber *object = [notification object];
    bool hasInternetConnectivity = [object boolValue];
    
    [self.editBarButtonItem setEnabled:hasInternetConnectivity];
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isDisplayingSearch)
    {
        return self.searchResults.count;
    }
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = (AlfrescoNodeCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell registerForNotifications];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *nodeCell = (AlfrescoNodeCell *)cell;
    [nodeCell removeNotifications];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoPermissions *nodePermission = nil;
    if (self.isDisplayingSearch)
    {
        nodePermission = self.nodePermissions[[self.searchResults[indexPath.row] identifier]];
    }
    else
    {
        nodePermission = self.nodePermissions[[self.tableViewData[indexPath.row] identifier]];
    }
    return (tableView.isEditing) ? YES : nodePermission.canDelete;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        AlfrescoNode *nodeToDelete = (self.isDisplayingSearch) ? self.searchResults[indexPath.row] : self.tableViewData[indexPath.row];
        AlfrescoPermissions *permissionsForNodeToDelete = self.nodePermissions[nodeToDelete.identifier];
        
        if (permissionsForNodeToDelete.canDelete)
        {
            [self deleteNode:nodeToDelete completionBlock:nil];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (self.isDisplayingSearch)
    {
        selectedNode = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        selectedNode = [self.tableViewData objectAtIndex:indexPath.row];
    }
    
    if (self.tableView.isEditing)
    {
        [self.multiSelectToolbar userDidSelectItem:selectedNode];
    }
    else
    {
        if ([selectedNode isKindOfClass:[AlfrescoFolder class]])
        {
            [self showHUD];
            [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                [self hideHUD];
                if (permissions)
                {
                    // push again
                    FileFolderListViewController *browserViewController = [[FileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderPermissions:permissions session:self.session];
                    [self.navigationController pushViewController:browserViewController animated:YES];
                }
                else
                {
                    // display permission retrieval error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission failed to be retrieved"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }];
            
        }
        else
        {
            [self showHUD];
            [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                [self hideHUD];
                
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    NSString *contentPath = [[SyncManager sharedManager] contentPathForNode:(AlfrescoDocument *)selectedNode];
                    if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:NO])
                    {
                        contentPath = nil;
                    }
                    
                    [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                                   permissions:permissions
                                                                                   contentFile:contentPath
                                                                              documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                       session:self.session
                                                                          navigationController:self.navigationController
                                                                                      animated:YES];
                }
            }];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableView.isEditing)
    {
        AlfrescoNode *selectedNode = [self.tableViewData objectAtIndex:indexPath.row];
        [self.multiSelectToolbar userDidDeselectItem:selectedNode];
    }
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
        __block NSString *selectedImageExtension = [[[(NSURL *)[info objectForKey:UIImagePickerControllerReferenceURL] path] pathExtension] lowercaseString];
        
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
                metadata = [self metadataByAddingGPSToMetadata:metadata];
            }
            
            // location services no longer required
            if ([[LocationManager sharedManager] isTrackingLocation])
            {
                [[LocationManager sharedManager] stopLocationUpdates];
            }
            
            uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadImage:selectedImage fileExtension:selectedImageExtension metadata:metadata inFolder:self.displayFolder uploadFormType:contentFormType delegate:self];
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
            ALAssetsLibrary *assetLibrary = [[ALAssetsLibrary alloc] init];
            [assetLibrary assetForURL:info[UIImagePickerControllerReferenceURL] resultBlock:^(ALAsset *asset) {
                NSDictionary *assetMetadata = [[asset defaultRepresentation] metadata];
                displayUploadForm(assetMetadata, NO);
            } failureBlock:^(NSError *error) {
                AlfrescoLogError(@"Unable to extract metadata from item for URL: %@. Error: %@", info[UIImagePickerControllerReferenceURL], error.localizedDescription);
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
        uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadDocumentPath:renamedFilePath inFolder:self.displayFolder uploadFormType:contentFormType delegate:self];
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
                                                                                                    inFolder:self.displayFolder
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

#pragma mark - UIPopoverControllerDelegate Functions

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return !self.capturingMedia;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:nil];
}

#pragma mark - FileFolderListViewControllerDelegate Functions

- (void)didFinishUploadingNode:(AlfrescoNode *)node fromLocation:(NSURL *)locationURL
{
    [self retrievePermissionsForNode:node];
    [self addAlfrescoNodes:@[node] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"upload.success-as.message", @"Document uplaoded as"), node.name]);
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadContentOfFolder];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadContentOfFolder];
            }
        }];
    }
}

#pragma mark - MultiSelectDelegate Functions

- (void)multiSelectUserDidPerformAction:(NSString *)actionId selectedItems:(NSArray *)selectedItems
{
    if ([actionId isEqualToString:kMultiSelectDelete])
    {
        [self confirmDeletingMultipleNodes];
    }
}

- (void)multiSelectItemsDidChange:(NSArray *)selectedItems
{
    for (AlfrescoNode *node in selectedItems)
    {
        AlfrescoPermissions *nodePermission = self.nodePermissions[node.identifier];
        if (!nodePermission.canDelete)
        {
            [self.multiSelectToolbar enableAction:kMultiSelectDelete enable:NO];
            break;
        }
    }
}

#pragma mark - Retrying Failed Sync Methods

- (void)showPopoverForFailedSyncNodeAtIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *node = self.tableViewData[indexPath.row];
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
        
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:indexPath];
        
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

@end
