//
//  FileFolderListViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FileFolderListViewController.h"
#import "UniversalDevice.h"
#import "PreviewViewController.h"
#import <MobileCoreServices/MobileCoreServices.h>
#import "NavigationViewController.h"
#import "Utility.h"
#import "MetaDataViewController.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "UIAlertView+ALF.h"
#import "LocationManager.h"
#import <ImageIO/ImageIO.h>
#import "AccountManager.h"
#import "DocumentPreviewViewController.h"
#import "TextFileViewController.h"
#import "FolderPreviewViewController.h"
#import "UIColor+Custom.h"

static CGFloat const kCellHeight = 64.0f;

static CGFloat const kSearchBarDisabledAlpha = 0.7f;
static CGFloat const kSearchBarEnabledAlpha = 1.0f;
static CGFloat const kSearchBarAnimationDuration = 0.2f;

@interface FileFolderListViewController ()

@property (nonatomic, strong) AlfrescoPermissions *folderPermissions;
@property (nonatomic, strong) NSString *folderDisplayName;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UIActionSheet *actionSheet;
@property (nonatomic, strong) AlfrescoFolder *displayFolder;
@property (nonatomic, assign) UIBarButtonItem *actionSheetSender;
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) NSMutableDictionary *nodePermissions;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIBarButtonItem *actionSheetBarButton;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
@property (nonatomic, assign) BOOL capturingMedia;
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
        self.displayFolder = folder;
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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.folderDisplayName;
    self.nodePermissions = [[NSMutableDictionary alloc] init];
    
    if (!IS_IPAD)
    {
        // hide search bar initially
        self.tableView.contentOffset = CGPointMake(0., 40.);
    }
    
    if (self.session)
    {
        [self loadContentOfFolder];
    }
    
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
    UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
    searchController.delegate = self;
    self.searchController = searchController;
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    [self.searchController.searchResultsTableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.tableHeaderView = self.searchBar;
    
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.actionSheet.visible)
    {
        [self.actionSheet dismissWithClickedButtonIndex:self.actionSheet.cancelButtonIndex animated:YES];
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
    
    if (self.editBarButtonItem)
    {
        self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
        [rightBarButtonItems addObject:self.editBarButtonItem];
    }
    
    if (self.folderPermissions.canAddChildren || self.folderPermissions.canEdit)
    {
        if (!self.tableView.isEditing)
        {
            if (!self.actionSheetBarButton)
            {
                UIBarButtonItem *displayActionSheetButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                                          target:self
                                                                                                          action:@selector(displayActionSheet:event:)];
                self.actionSheetBarButton = displayActionSheetButton;
            }
            
            if (!self.actionSheetSender.enabled && [self.actionSheetBarButton isEqual:self.actionSheetSender])
            {
                self.actionSheetBarButton.enabled = NO;
                self.actionSheetSender = self.actionSheetBarButton;
            }
            
            [rightBarButtonItems addObject:self.actionSheetBarButton];
        }
        else
        {
            self.actionSheetSender = nil;
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
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.takephotovideo", @"Take Photo or Video")];
        [actionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio")];
        
    }
    
    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        [actionSheet setActionSheetStyle:UIActionSheetStyleDefault];
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
    else
    {
        [actionSheet showInView:self.view];
    }

    // UIActionSheet button titles don't pick up the global tint color by default
    [Utility colorButtonsForActionSheet:actionSheet tintColor:[UIColor appTintColor]];

    self.actionSheetSender = (UIBarButtonItem *)sender;
    self.actionSheetSender.enabled = NO;
    self.actionSheet = actionSheet;
    self.editBarButtonItem.enabled = NO;
}

- (void)presentViewInPopoverOrModal:(UIViewController *)controller animated:(BOOL)animated
{
    self.actionSheetSender.enabled = NO;
    
    if (IS_IPAD)
    {
        UIPopoverController *popoverController = [[UIPopoverController alloc] initWithContentViewController:controller];
        popoverController.delegate = self;
        self.popover = popoverController;
        [self.popover setContentViewController:controller];
        
        [self.popover presentPopoverFromBarButtonItem:self.actionSheetSender permittedArrowDirections:UIPopoverArrowDirectionUp animated:animated];
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
            [self setPopover:nil];
            if (completionBlock != NULL)
            {
                completionBlock();
            }
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
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.root-folder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
        else
        {
            // folder permissions not set, retrieve and update the UI
            if (!self.folderPermissions)
            {
                [self retrieveAndSetPermissionsOfCurrentFolder];
            }
            else
            {
                [self updateUIUsingFolderPermissionsWithAnimation:NO];
            }
            
            [self showHUD];
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self hideHUD];
                [self hidePullToRefreshView];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }];
        }
    }
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    self.displayFolder = nil;
    self.tableView.tableHeaderView = nil;
    
    [self createAlfrescoServicesWithSession:session];
    
    if ([self shouldRefresh])
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
    if (self.searchController.searchResultsTableView.window)
    {
        selectedNode = [self.searchResults objectAtIndex:indexPath.row];
    }
    else
    {
        selectedNode = [self.tableViewData objectAtIndex:indexPath.row];
    }
    
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    if (self.searchController.searchResultsTableView && self.searchController.searchResultsTableView.window)
    {
        [self showSearchProgressHUD];
        [self.documentService retrieveNodeWithIdentifier:selectedNode.identifier completionBlock:^(AlfrescoNode *node, NSError *error) {
            [self hideSearchProgressHUD];
            if (node)
            {
                MetaDataViewController *metadataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:node session:self.session];
                [UniversalDevice pushToDisplayViewController:metadataViewController usingNavigationController:self.navigationController animated:YES];
            }
            else
            {
                NSString *metadataRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.retrieving.metadata", "Metadata Retrieval Error"), selectedNode.name];
                displayErrorMessage(metadataRetrievalErrorMessage);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            if (permissions)
            {
                FolderPreviewViewController *folderPreviewController = [[FolderPreviewViewController alloc] initWithAlfrescoFolder:(AlfrescoFolder *)selectedNode permissions:permissions session:self.session];
                [UniversalDevice pushToDisplayViewController:folderPreviewController usingNavigationController:self.navigationController animated:YES];
            }
            else
            {
                NSString *permissionRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", "Permission Retrieval Error"), selectedNode.name];
                displayErrorMessage(permissionRetrievalErrorMessage);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
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
            if (weakSelf.searchController.searchResultsTableView.window)
            {
                tableNodeIdentifiers = [weakSelf.searchResults valueForKeyPath:@"identifier"];
                [weakSelf.searchResults removeObject:nodeToDelete];
                indexPathForNode = [weakSelf indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:tableNodeIdentifiers];
                if (indexPathForNode != nil)
                {
                    [weakSelf.searchController.searchResultsTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode] withRowAnimation:UITableViewRowAnimationFade];
                }
            }
            
            // remove nodeToDelete from tableview
            tableNodeIdentifiers = [weakSelf.tableViewData valueForKeyPath:@"identifier"];
            if (weakSelf.searchController.searchResultsTableView.window)
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

- (void)deleteNodes:(NSArray *)nodes completionBlock:(void (^)(BOOL success))completionBlock
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
                (numberOfSuccessfulDeletes == nodes.count) ? completionBlock(YES) : completionBlock(NO);
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
    [self deleteNodes:self.multiSelectToolbar.selectedItems completionBlock:^(BOOL complete) {
        [self hideHUD];
    }];
}

- (void)documentUpdated:(NSNotification *)notification
{
    NSDictionary *updatedDocumentDetails = (NSDictionary *)notification.object;
    
    id documentNodeObject = [updatedDocumentDetails valueForKey:kAlfrescoDocumentUpdatedDocumentParameterKey];
    
    // this should always be an AlfrescoDocument. If it isn't something has gone terribly wrong...
    if ([documentNodeObject isKindOfClass:[AlfrescoDocument class]])
    {
        AlfrescoDocument *updatedDocument = (AlfrescoDocument *)documentNodeObject;
        
        NSArray *allIdentifiers = [self.tableViewData valueForKey:@"identifier"];
        if ([allIdentifiers containsObject:updatedDocument.identifier])
        {
            NSUInteger index = [allIdentifiers indexOfObject:updatedDocument.identifier];
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
    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchController.searchResultsTableView];
    [self.searchController.searchResultsTableView addSubview:self.searchProgressHUD];
    [self.searchProgressHUD show:YES];
}

- (void)hideSearchProgressHUD
{
    [self.searchProgressHUD hide:YES];
    self.searchProgressHUD = nil;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchController.searchResultsTableView)
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
    if (tableView == self.searchController.searchResultsTableView)
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
        if (self.folderPermissions.canDelete)
        {
            AlfrescoNode *nodeToDelete = nil;
            if (tableView == self.searchController.searchResultsTableView)
            {
                nodeToDelete = self.searchResults[indexPath.row];
            }
            else
            {
                nodeToDelete = self.tableViewData[indexPath.row];
            }
            [self deleteNode:nodeToDelete completionBlock:nil];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (tableView == self.searchController.searchResultsTableView)
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
                    DocumentPreviewViewController *previewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                                                                           permissions:permissions
                                                                                                                       contentFilePath:nil
                                                                                                                      documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                                                               session:self.session];
                    previewController.hidesBottomBarWhenPushed = YES;
                    [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
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

#pragma mark - UIActionSheetDelegate Functions

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *selectedButtonText = [actionSheet buttonTitleAtIndex:buttonIndex];
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    
    if (self.actionSheetSender)
    {
        self.actionSheetSender.enabled = YES;
    }
    
    if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.createfile", @"Create File")])
    {
        TextFileViewController *textFileViewController = [[TextFileViewController alloc] initWithUploadFileDestinationFolder:self.displayFolder session:self.session delegate:self];
        NavigationViewController *textFileViewNavigationController = [[NavigationViewController alloc] initWithRootViewController:textFileViewController];
        [UniversalDevice displayModalViewController:textFileViewNavigationController onController:[UniversalDevice revealViewController] withCompletionBlock:nil];
        self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
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
                [self.documentService createFolderWithName:desiredFolderName inParentFolder:self.displayFolder properties:nil completionBlock:^(AlfrescoFolder *folder, NSError *error) {
                    if (folder)
                    {
                        [self retrievePermissionsForNode:folder];
                        [self addAlfrescoNodes:@[folder] withRowAnimation:UITableViewRowAnimationAutomatic];
                        [self updateUIUsingFolderPermissionsWithAnimation:NO];
                    }
                    else
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
            self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
        }];
        
        self.actionSheetSender.enabled = YES;
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload", @"Upload")])
    {  
        UIActionSheet *uploadActionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
        
        [uploadActionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.upload.existingPhotosOrVideos", @"Choose Photo or Video from Library")];
        [uploadActionSheet addButtonWithTitle:NSLocalizedString(@"browser.actionsheet.upload.documents", @"Upload Document")];
        [uploadActionSheet setCancelButtonIndex:[uploadActionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")]];
        
        if (IS_IPAD)
        {
            [uploadActionSheet setActionSheetStyle:UIActionSheetStyleDefault];
            [uploadActionSheet showFromBarButtonItem:self.actionSheetSender animated:YES];
        }
        else
        {
            [uploadActionSheet showInView:self.view];
        }
        
        // UIActionSheet button titles don't pick up the global tint color by default
        [Utility colorButtonsForActionSheet:uploadActionSheet tintColor:[UIColor appTintColor]];

        [self.actionSheetSender setEnabled:NO];
        [self setActionSheet:uploadActionSheet];
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
        
        [self presentViewInPopoverOrModal:self.imagePickerController animated:YES];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.upload.documents", @"Upload Document")])
    {
        DownloadsViewController *downloadPicker = [[DownloadsViewController alloc] init];
        downloadPicker.isDownloadPickerEnabled = YES;
        downloadPicker.downloadPickerDelegate = self;
        [downloadPicker setModalTransitionStyle:UIModalTransitionStyleFlipHorizontal];
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
        
        [self.navigationController presentViewController:self.imagePickerController animated:YES completion:nil];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"multiselect.button.delete", @"Multi Select Deleteconfirmation")])
    {
        [self deleteMultiSelectedNodes];
    }
    else if ([selectedButtonText isEqualToString:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio")])
    {
        UploadFormViewController *audioRecorderViewController = [[UploadFormViewController alloc] initWithSession:self.session createAndUploadAudioToFolder:self.displayFolder delegate:self];
        NavigationViewController *audioRecorderNavigationController = [[NavigationViewController alloc] initWithRootViewController:audioRecorderViewController];
        
        [UniversalDevice displayModalViewController:audioRecorderNavigationController onController:self.navigationController withCompletionBlock:nil];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        self.actionSheetSender.enabled = YES;
        self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
        
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
        NSString *selectedImageExtension = [[[[info objectForKey:UIImagePickerControllerReferenceURL] path] pathExtension] lowercaseString];
        NSDictionary *metadata = [info objectForKey:UIImagePickerControllerMediaMetadata];
        
        // determine if the content was created or picked
        UploadFormType contentFormType = UploadFormTypeImagePhotoLibrary;
                
        // iOS camera uses JPEG images
        if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
        {
            selectedImageExtension = @"jpg";
            contentFormType = UploadFormTypeImageCreated;
        }
        
        // add GPS metadata if Location Services are allowed for this app
        if ([[LocationManager sharedManager] usersLocationAuthorisation])
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
        [self.imagePickerController dismissViewControllerAnimated:YES completion:^{
            [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
        }];
    }
    else if ([mediaType isEqualToString:(NSString *)kUTTypeVideo] || [mediaType isEqualToString:(NSString *)kUTTypeMovie])
    {
        // move the video file into the container
        // read from default file system
        NSString *filePathInDefaultFileSystem = [[info objectForKey:UIImagePickerControllerMediaURL] path];
        
        // construct the file name
        NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setDateFormat:@"yyyy-MM-dd HH.mm.ss"];
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
        }
        
        // create the view controller
        uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session uploadDocumentPath:renamedFilePath inFolder:self.displayFolder uploadFormType:contentFormType delegate:self];
        uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
        
        // display the preview form to upload
        [self.imagePickerController dismissViewControllerAnimated:YES completion:^{
            [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
        }];
    }

    self.actionSheetSender.enabled = YES;
    self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker
{
    self.capturingMedia = NO;
    self.actionSheetSender.enabled = YES;
    self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
    
    if ([[LocationManager sharedManager] isTrackingLocation])
    {
        [[LocationManager sharedManager] stopLocationUpdates];
    }
    
    [self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - DownloadPickerDelegate Functions

- (void)downloadPicker:(id)picker didPickDocument:(NSString *)documentPath
{
    UploadFormViewController *uploadFormController = [[UploadFormViewController alloc] initWithSession:self.session
                                                                                          uploadDocumentPath:documentPath
                                                                                                    inFolder:self.displayFolder
                                                                                              uploadFormType:UploadFormTypeDocument
                                                                                                    delegate:self];
    
    NavigationViewController *uploadFormNavigationController = [[NavigationViewController alloc] initWithRootViewController:uploadFormController];
    
    __weak FileFolderListViewController *weakSelf = self;
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:^{
        [UniversalDevice displayModalViewController:uploadFormNavigationController onController:self.navigationController withCompletionBlock:nil];
        weakSelf.actionSheetSender.enabled = YES;
    }];
}

- (void)downloadPickerDidCancel
{
    __weak FileFolderListViewController *weakSelf = self;
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:^{
        weakSelf.actionSheetSender.enabled = YES;
        weakSelf.editBarButtonItem.enabled = (self.tableViewData.count > 0);
    }];
}

#pragma mark - UIPopoverControllerDelegate Functions

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
    return !self.capturingMedia;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
    self.actionSheetSender.enabled = YES;
    self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
    
    [self dismissPopoverOrModalWithAnimation:YES withCompletionBlock:nil];
}

#pragma mark - FileFolderListViewControllerDelegate Functions

- (void)didFinishUploadingNode:(AlfrescoNode *)node
{
    [self retrievePermissionsForNode:node];
    [self addAlfrescoNodes:@[node] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"upload.success-as.message", @"Document uplaoded as"), node.name]);
}

- (void)didCancelUpload
{
    self.editBarButtonItem.enabled = (self.tableViewData.count > 0);
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
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
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

@end
