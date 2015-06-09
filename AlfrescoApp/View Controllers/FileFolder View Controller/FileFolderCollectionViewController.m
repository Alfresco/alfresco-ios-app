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

#import "FileFolderCollectionViewController.h"
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

#import "BaseCollectionViewFlowLayout.h"

static CGFloat const kCellHeight = 64.0f;

static CGFloat const kSearchBarDisabledAlpha = 0.7f;
static CGFloat const kSearchBarEnabledAlpha = 1.0f;
static CGFloat const kSearchBarAnimationDuration = 0.2f;

@interface FileFolderCollectionViewController ()

@property (nonatomic, strong) AlfrescoPermissions *folderPermissions;
@property (nonatomic, strong) NSString *folderDisplayName;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) AlfrescoFolder *initialFolder;
@property (nonatomic, assign) UIBarButtonItem *actionSheetSender;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSMutableDictionary *nodePermissions;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIBarButtonItem *actionSheetBarButton;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, assign) BOOL capturingMedia;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, weak) IBOutlet MultiSelectActionsToolbar *multiSelectToolbar;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *multiSelectToolbarHeightConstraint;

@property (nonatomic, strong) BaseCollectionViewFlowLayout *listLayout;

@end

@implementation FileFolderCollectionViewController

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
    self = [super initWithNibName:@"FileFolderCollectionViewController" andSession:session];
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

- (void) setupWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    [super setupWithSession:session];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    }
    
    self.title = self.folderDisplayName;
    self.nodePermissions = [[NSMutableDictionary alloc] init];
    
//    if (!IS_IPAD)
//    {
//        // hide search bar initially
//        self.collectionView.contentOffset = CGPointMake(0., 40.);
//    }
    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create searchBar
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(view.frame.origin.x,
                                                                           view.frame.origin.y,
                                                                           view.frame.size.width,
                                                                           44.0f)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.delegate = self;
    searchBar.searchBarStyle = UISearchBarStyleMinimal;
    searchBar.backgroundColor = [UIColor whiteColor];
    self.searchBar = searchBar;
    
    // search controller
//    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:self];
//    self.searchController = searchController;
    
//    UINib *nib = [UINib nibWithNibName:@"FileFolderCollectionViewCell" bundle:nil];
//    [self.collectionView registerNib:nib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
//    UINib *loadingNib = [UINib nibWithNibName:@"LoadingCollectionViewCell" bundle:nil];
//    [self.collectionView registerNib:loadingNib forCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier]];
//    [self.searchController. registerNib:nib forCellReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    
//    self.tableView.tableHeaderView = self.searchBar;
    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.collectionView.swipeToDeleteDelegate = self;
    self.listLayout = [BaseCollectionViewFlowLayout new];
    self.listLayout.itemHeight = kCellHeight;
    [self.collectionView setCollectionViewLayout:self.listLayout animated:YES];
    
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
    
    if (self.actionSheet.visible)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
    }
    
    if (self.collectionView.isEditing)
    {
        self.collectionView.editing = NO;
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
    self.collectionView.allowsMultipleSelection = editing;
    [self.collectionView setEditing:editing animated:animated];
    [self updateUIUsingFolderPermissionsWithAnimation:YES];
    [self.navigationItem setHidesBackButton:editing animated:YES];
    
    [UIView animateWithDuration:kSearchBarAnimationDuration animations:^{
        self.searchBar.alpha = editing ? kSearchBarDisabledAlpha : kSearchBarEnabledAlpha;
    }];
    self.searchBar.userInteractionEnabled = !editing;
    
    if (editing)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
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
    self.collectionView.delegate = nil;
    self.imagePickerController.delegate = nil;
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
    
    [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
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
    [self setEditing:!self.collectionView.editing animated:YES];
}

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated
{
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    
    // update the UI based on permissions
    if (!self.collectionView.editing)
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
    
    self.editBarButtonItem.enabled = (self.collectionViewData.count > 0);
    [rightBarButtonItems addObject:self.editBarButtonItem];
    
    if (self.folderPermissions.canAddChildren || self.folderPermissions.canEdit)
    {
        if (!self.collectionView.isEditing)
        {
            if (!self.actionSheetBarButton)
            {
                UIBarButtonItem *displayActionSheetButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                          target:self
                                                                                                          action:@selector(displayActionSheet:event:)];
                self.actionSheetBarButton = displayActionSheetButton;
            }
            
            [rightBarButtonItems addObject:self.actionSheetBarButton];
        }
    }
    [self.navigationItem setRightBarButtonItems:rightBarButtonItems animated:animated];
}

- (void)displayActionSheet:(id)sender event:(UIEvent *)event
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    if (self.folderPermissions.canAddChildren)
    {
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.createfile", @"Create File")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.addfolder", @"Create Folder")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.upload", @"Upload")];
        
        if ([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
        {
            [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video")];
        }
        
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio")];
    }
    
    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        actionSheet.actionSheetStyle = UIActionSheetStyleDefault;
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
    else
    {
        [actionSheet showInView:self.view];
    }
    
    // UIActionSheet button titles don't pick up the global tint color by default
    [Utility colorButtonsForActionSheet:actionSheet tintColor:[UIColor appTintColor]];
    
    self.actionSheet = actionSheet;
    self.actionSheetSender = sender;
    
}

- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated
{
    if (IS_IPAD)
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        popoverController.delegate = self;
        self.popover = popoverController;
        self.popover.contentViewController = controller;
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.popover presentPopoverFromBarButtonItem:self.actionSheetSender permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
        });
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
                [self.view bringSubviewToFront:self.collectionView];
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
                        [self.view bringSubviewToFront:self.collectionView];
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
                [self reloadCollectionViewWithPagingResult:pagingResult error:error];
                
                [self.view bringSubviewToFront:self.collectionView];
            }];
        }
    }
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.displayFolder = nil;
//    self.tableView.tableHeaderView = nil;
    
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

- (void)selectIndexPathForAlfrescoNodeInDetailView
{
    NSArray *collectionViewNodeIdentifiers = [self.collectionViewData valueForKeyPath:@"identifier"];
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:[UniversalDevice detailViewItemIdentifier] inNodeIdentifiers:collectionViewNodeIdentifiers];
    
    [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
}

- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    __weak FileFolderCollectionViewController *weakSelf = self;
    [self.documentService deleteNode:nodeToDelete completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            if ([[UniversalDevice detailViewItemIdentifier] isEqualToString:nodeToDelete.identifier])
            {
                [UniversalDevice clearDetailViewController];
            }
            
            NSArray *collectionViewNodeIdentifiers = nil;
            NSIndexPath *indexPathForNode = nil;
            
            // remove nodeToDelete from search tableview if search view is present
            if (weakSelf.searchController.searchResultsTableView.window)
            {
                collectionViewNodeIdentifiers = [weakSelf.searchResults valueForKeyPath:@"identifier"];
                [weakSelf.searchResults removeObject:nodeToDelete];
                indexPathForNode = [weakSelf indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:collectionViewNodeIdentifiers];
                if (indexPathForNode != nil)
                {
                    [weakSelf.searchController.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            
            // remove nodeToDelete from collection view
            collectionViewNodeIdentifiers = [weakSelf.collectionViewData valueForKeyPath:@"identifier"];
            if (weakSelf.searchController.searchResultsTableView.window)
            {
                [collectionViewNodeIdentifiers enumerateObjectsUsingBlock:^(NSString *identifier, NSUInteger index, BOOL *stop) {
                    if ([identifier isEqualToString:nodeToDelete.identifier])
                    {
                        [weakSelf.collectionViewData removeObjectAtIndex:index];
                        *stop = YES;
                    }
                }];
            }
            else
            {
                [weakSelf.collectionViewData removeObject:nodeToDelete];
            }
            indexPathForNode = [self indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:collectionViewNodeIdentifiers];
            if (indexPathForNode != nil)
            {
                [weakSelf.collectionView performBatchUpdates:^{
                    [weakSelf.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode]];
                } completion:nil];
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
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:title
                                                             delegate:self
                                                    cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                               destructiveButtonTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete")
                                                    otherButtonTitles:nil];
    [actionSheet showFromToolbar:self.multiSelectToolbar];
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
        
        NSArray *allIdentifiers = [self.collectionViewData valueForKey:@"identifier"];
        if ([allIdentifiers containsObject:existingDocument.identifier])
        {
            NSUInteger index = [allIdentifiers indexOfObject:existingDocument.identifier];
            [self.collectionViewData replaceObjectAtIndex:index withObject:updatedDocument];
            NSIndexPath *indexPathOfDocument = [NSIndexPath indexPathForRow:index inSection:0];
            
            NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
            [self.collectionView performBatchUpdates:^{
                [self.collectionView reloadItemsAtIndexPaths:@[indexPathOfDocument]];
            } completion:^(BOOL finished) {
                // reselect the row after it has been updated
                for(NSIndexPath *indexPath in selectedIndexPaths)
                {
                    if (indexPath.row == indexPathOfDocument.row)
                    {
                        [self.collectionView selectItemAtIndexPath:indexPathOfDocument animated:NO scrollPosition:UICollectionViewScrollPositionNone];
                    }
                }
            }];
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
    
    if ([self.collectionViewData containsObject:deletedDocument])
    {
        NSUInteger index = [self.collectionViewData indexOfObject:deletedDocument];
        [self.collectionViewData removeObject:deletedDocument];
        NSIndexPath *indexPathOfDeletedNode = [NSIndexPath indexPathForRow:index inSection:0];
        [self.collectionView deleteItemsAtIndexPaths:@[indexPathOfDeletedNode]];
    }
}

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *foldersDictionary = notification.object;
    
    AlfrescoFolder *parentFolder = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([parentFolder isEqual:self.displayFolder])
    {
        AlfrescoNode *subnode = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        [self addAlfrescoNodes:@[subnode] completion:nil];
    }
}

- (void)documentUpdatedOnServer:(NSNotification *)notification
{
    NSString *nodeIdentifierUpdated = notification.object;
    AlfrescoDocument *updatedDocument = notification.userInfo[kAlfrescoDocumentUpdatedFromDocumentParameterKey];
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:nodeIdentifierUpdated inNodeIdentifiers:[self.collectionViewData valueForKey:@"identifier"]];
    
    if (indexPath)
    {
        [self.collectionViewData replaceObjectAtIndex:indexPath.row withObject:updatedDocument];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        } completion:nil];
    }
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    AlfrescoDocument *editedDocument = notification.object;
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:editedDocument.name inNodeIdentifiers:[self.collectionViewData valueForKey:@"name"]];
    
    if (indexPath)
    {
        [self.collectionViewData replaceObjectAtIndex:indexPath.row withObject:editedDocument];
        [self.collectionView performBatchUpdates:^{
            [self.collectionView reloadItemsAtIndexPaths:@[indexPath]];
        } completion:nil];
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
//    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchController.searchResultsTableView];
//    [self.searchController.searchResultsTableView addSubview:self.searchProgressHUD];
//    [self.searchProgressHUD show:YES];
}

- (void)hideSearchProgressHUD
{
//    [self.searchProgressHUD hide:YES];
//    self.searchProgressHUD = nil;
}

- (void)connectivityStatusChanged:(NSNotification *)notification
{
    NSNumber *object = [notification object];
    bool hasInternetConnectivity = [object boolValue];
    
    [self.editBarButtonItem setEnabled:hasInternetConnectivity];
}

#pragma mark - Collection view data source

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
//    if (collectionView == self.searchController.searchResultsTableView)
//    {
//        return self.searchResults.count;
//    }
    return self.collectionViewData.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    [cell registerForNotifications];
    cell.accessoryViewDelegate = self;
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileFolderCollectionViewCell *nodeCell = (FileFolderCollectionViewCell *)cell;
    [nodeCell removeNotifications];
}

//- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
//{
//    AlfrescoPermissions *nodePermission = nil;
//    if (tableView == self.searchController.searchResultsTableView)
//    {
//        nodePermission = self.nodePermissions[[self.searchResults[indexPath.row] identifier]];
//    }
//    else
//    {
//        nodePermission = self.nodePermissions[[self.tableViewData[indexPath.row] identifier]];
//    }
//    return (tableView.isEditing) ? YES : nodePermission.canDelete;
//}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
//    if (tableView == self.searchController.searchResultsTableView)
//    {
//        selectedNode = [self.searchResults objectAtIndex:indexPath.row];
//    }
//    else
//    {
        selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
//    }
    
    if (self.collectionView.isEditing)
    {
        [self.multiSelectToolbar userDidSelectItem:selectedNode];
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        self.collectionView.isInDeleteMode = NO;
        [cell wasSelectedInEditMode:YES];
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
                    FileFolderCollectionViewController *browserViewController = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderPermissions:permissions session:self.session];
                    [self.navigationController pushViewController:browserViewController animated:YES];
                }
                else
                {
                    // display permission retrieval error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission failed to be retrieved"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                [collectionView deselectItemAtIndexPath:indexPath animated:YES];
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

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.collectionView.isEditing)
    {
        AlfrescoNode *selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
        [self.multiSelectToolbar userDidDeselectItem:selectedNode];
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell wasSelectedInEditMode:NO];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
//    // the last row index of the table data
//    NSUInteger lastSiteRowIndex = self.collectionViewData.count - 1;
//    
//    // if the last cell is about to be drawn, check if there are more sites
//    if (indexPath.row == lastSiteRowIndex)
//    {
//        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.collectionViewData.count) intValue]];
//        if (self.moreItemsAvailable)
//        {
//            // show more items are loading ...
//            self.isLoadingAnotherPage = YES;
//            [self.collectionView performBatchUpdates:^{
//                [self.collectionView insertItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:self.collectionViewData.count inSection:0]]];
//            } completion:^(BOOL finished) {
//                [self retrieveContentOfFolder:self.displayFolder usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
//                    [self.collectionView performBatchUpdates:^{
//                        self.isLoadingAnotherPage = NO;
//                        [self.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForItem:self.collectionViewData.count inSection:0]]];
//                    } completion:^(BOOL finished) {
//                        [self addMoreToCollectionViewWithPagingResult:pagingResult error:error];
//                    }];
//                }];
//            }];
//        }
//    }
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
//{
//    if((self.isLoadingAnotherPage) && (indexPath.item == self.collectionViewData.count))
//    {
//        UIEdgeInsets insets = self.collectionView.contentInset;
//        CGFloat width = CGRectGetWidth(self.collectionView.bounds) - (insets.left + insets.right);
//        return CGSizeMake(width, 40);
//    }
//    else
//    {
//        if([collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
//        {
//            BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)collectionViewLayout;
//            return properLayout.itemSize;
//        }
//        return CGSizeZero;
//    }
//}

#pragma mark - UIActionSheetDelegate Functions

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *selectedButtonText = [actionSheet buttonTitleAtIndex:buttonIndex];
    
    if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.createfile", @"Create File")])
    {
        TextFileViewController *textFileViewController = [[TextFileViewController alloc] initWithUploadFileDestinationFolder:self.displayFolder session:self.session delegate:self];
        NavigationViewController *textFileViewNavigationController = [[NavigationViewController alloc] initWithRootViewController:textFileViewController];
        dispatch_async(dispatch_get_main_queue(), ^{
            [UniversalDevice displayModalViewController:textFileViewNavigationController onController:[UniversalDevice revealViewController] withCompletionBlock:nil];
        });
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.addfolder", @"Create Folder")])
    {
        // display the create folder UI
        UIAlertView *createFolderAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"browser.alertview.addfolder.title", @"Create Folder Title")
                                                                    message:NSLocalizedString(@"browser.alertview.addfolder.message", @"Create Folder Message")
                                                                   delegate:self
                                                          cancelButtonTitle:NSLocalizedString(@"Cancel", @"Cancel")
                                                          otherButtonTitles:NSLocalizedString(@"browser.alertview.addfolder.create", @"Create Folder"), nil];
        createFolderAlert.alertViewStyle = UIAlertViewStylePlainTextInput;
        [createFolderAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
            if (!isCancelButton)
            {
                NSString *desiredFolderName = [[createFolderAlert textFieldAtIndex:0] text];
                desiredFolderName = [desiredFolderName stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
                if ([Utility isValidFolderName:desiredFolderName])
                {
                    [self.documentService createFolderWithName:desiredFolderName inParentFolder:self.displayFolder properties:nil completionBlock:^(AlfrescoFolder *folder, NSError *error) {
                        if (folder)
                        {
                            [self retrievePermissionsForNode:folder];
                            [self addAlfrescoNodes:@[folder] completion:nil];
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
            }
        }];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload", @"Upload")])
    {
        UIActionSheet *uploadActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        [uploadActionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library")];
        [uploadActionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.upload.documents", @"Upload Document")];
        [uploadActionSheet setCancelButtonIndex:[uploadActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")]];
        
        if (IS_IPAD)
        {
            uploadActionSheet.actionSheetStyle = UIActionSheetStyleDefault;
            dispatch_async(dispatch_get_main_queue(), ^{
                [uploadActionSheet showFromBarButtonItem:self.actionSheetSender animated:YES];
            });
        }
        else
        {
            [uploadActionSheet showInView:self.view];
        }
        
        // UIActionSheet button titles don't pick up the global tint color by default
        [Utility colorButtonsForActionSheet:uploadActionSheet tintColor:[UIColor appTintColor]];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload.existingPhotos", @"Choose Photo from Library")] ||
             [selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library")])
    {
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
        
        if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library")])
        {
            self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        }
        else
        {
            self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        
        self.imagePickerController.modalPresentationStyle = UIModalPresentationCurrentContext;
        [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload.documents", @"Upload Document")])
    {
        DownloadsViewController *downloadPicker = [[DownloadsViewController alloc] init];
        downloadPicker.isDownloadPickerEnabled = YES;
        downloadPicker.downloadPickerDelegate = self;
        downloadPicker.modalTransitionStyle = UIModalTransitionStyleFlipHorizontal;
        NavigationViewController *downloadPickerNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadPicker];
        
        [self presentViewInPopoverOrModal:downloadPickerNavigationController animated:YES];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video")] ||
             [selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.takephoto", @"Take Photo")])
    {
        // start location services
        [[LocationManager sharedManager] startLocationUpdates];
        
        self.imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        
        if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video")])
        {
            self.imagePickerController.mediaTypes = [UIImagePickerController availableMediaTypesForSourceType:self.imagePickerController.sourceType];
        }
        else
        {
            self.imagePickerController.mediaTypes = @[(NSString *)kUTTypeImage];
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            self.imagePickerController.modalPresentationStyle = UIModalPresentationFullScreen;
            [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
        });
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"multiselect.button.delete", @"Multi Select Delete Confirmation")])
    {
        [self deleteMultiSelectedNodes];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio")])
    {
        UploadFormViewController *audioRecorderViewController = [[UploadFormViewController alloc] initWithSession:self.session createAndUploadAudioToFolder:self.displayFolder delegate:self];
        NavigationViewController *audioRecorderNavigationController = [[NavigationViewController alloc] initWithRootViewController:audioRecorderViewController];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [UniversalDevice displayModalViewController:audioRecorderNavigationController onController:self.navigationController withCompletionBlock:nil];
        });
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        if ([[LocationManager sharedManager] isTrackingLocation])
        {
            [[LocationManager sharedManager] stopLocationUpdates];
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
    [self addAlfrescoNodes:@[node] completion:nil];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"upload.success-as.message", @"Document uplaoded as"), node.name]);
}

#pragma mark - UIRefreshControl Functions

- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
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
    [[SyncManager sharedManager] retrySyncForDocument:(AlfrescoDocument *)self.retrySyncNode completionBlock:nil];
    [self.retrySyncPopover dismissPopoverAnimated:YES];
    self.retrySyncNode = nil;
    self.retrySyncPopover = nil;
}

#pragma mark - SwipeToDeleteDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSwipeToDeleteItemAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *nodeToDelete = /*(collectionView == self.searchController.searchResultsTableView) ? self.searchResults[indexOfItemToDelete] : */self.collectionViewData[indexPath.item];
    AlfrescoPermissions *permissionsForNodeToDelete = self.nodePermissions[nodeToDelete.identifier];
    
    if (permissionsForNodeToDelete.canDelete)
    {
        [self deleteNode:nodeToDelete completionBlock:nil];
    }
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    NSIndexPath *selectedIndexPath = nil;
    
    if (self.searchController.searchResultsTableView.window)
    {
        NSUInteger item = [self.searchResults indexOfObject:node];
        selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    }
    else
    {
        NSUInteger item = [self.collectionViewData indexOfObject:node];
        selectedIndexPath = [NSIndexPath indexPathForItem:item inSection:0];
    }
    
    if (node.isFolder)
    {
        [self.collectionView selectItemAtIndexPath:selectedIndexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
        
        [self.documentService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
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
    else
    {
        SyncManager *syncManager = [SyncManager sharedManager];
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

@end
