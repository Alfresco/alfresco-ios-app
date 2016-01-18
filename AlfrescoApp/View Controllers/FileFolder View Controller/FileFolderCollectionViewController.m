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
#import "SearchCollectionSectionHeader.h"
#import "ALFSwipeToDeleteGestureRecognizer.h"
#import "CustomFolderService.h"

typedef NS_ENUM(NSUInteger, FileFolderCollectionViewControllerType)
{
    FileFolderCollectionViewControllerTypeFolderNode,
    FileFolderCollectionViewControllerTypeSiteShortName,
    FileFolderCollectionViewControllerTypeFolderPath,
    FileFolderCollectionViewControllerTypeNodeRef,
    FileFolderCollectionViewControllerTypeDocumentPath,
    FileFolderCollectionViewControllerTypeSearchString,
    FileFolderCollectionViewControllerTypeCustomFolderType,
    FileFolderCollectionViewControllerTypeCMISSearch
};

static CGFloat const kCellHeight = 64.0f;

static CGFloat const kSearchBarDisabledAlpha = 0.7f;
static CGFloat const kSearchBarEnabledAlpha = 1.0f;
static CGFloat const kSearchBarAnimationDuration = 0.2f;

@interface FileFolderCollectionViewController () <DownloadsPickerDelegate, MultiSelectActionsDelegate, UploadFormViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate, UIPopoverControllerDelegate, SwipeToDeleteDelegate, UIPopoverPresentationControllerDelegate>

// Views
@property (nonatomic, weak) UISearchBar *searchBar;
@property (nonatomic, assign) UIBarButtonItem *alertControllerSender;
@property (nonatomic, strong) UIBarButtonItem *editBarButtonItem;
// Data Model
@property (nonatomic, strong) AlfrescoPermissions *folderPermissions;
@property (nonatomic, strong) NSString *folderDisplayName;
@property (nonatomic, strong) AlfrescoFolder *initialFolder;
@property (nonatomic, strong) NSMutableDictionary *nodePermissions;
@property (nonatomic, assign) BOOL capturingMedia;
@property (nonatomic, strong) AlfrescoNode *retrySyncNode;
@property (nonatomic, strong) UITapGestureRecognizer *tapToDismissDeleteAction;
@property (nonatomic, strong) ALFSwipeToDeleteGestureRecognizer *swipeToDeleteGestureRecognizer;
@property (nonatomic, strong) NSIndexPath *initialCellForSwipeToDelete;
@property (nonatomic) BOOL shouldShowOrHideDelete;
@property (nonatomic) CGFloat cellActionViewWidth;
@property (nonatomic, strong) NSIndexPath *indexPathOfLoadingCell;
@property (nonatomic, assign) FileFolderCollectionViewControllerType controllerType;
@property (nonatomic, strong) NSString *siteShortName;
@property (nonatomic, strong) NSString *folderPath;
@property (nonatomic, strong) NSString *nodeRef;
@property (nonatomic, strong) NSString *documentPath;
@property (nonatomic) CustomFolderServiceFolderType customFolderType;
@property (nonatomic) BOOL shouldAutoSelectFirstItem;
@property (nonatomic, strong) NSString *previousSearchString;
@property (nonatomic, strong) AlfrescoKeywordSearchOptions *previousSearchOptions;
@property (nonatomic, strong) NSString *CMISSearchStatement;
// Controllers
@property (nonatomic, strong) UIPopoverController *popover;
@property (nonatomic, strong) UIImagePickerController *imagePickerController;
@property (nonatomic, strong) UIPopoverController *retrySyncPopover;
// Services
@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) CustomFolderService *customFolderService;
@end

@implementation FileFolderCollectionViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:nil folderDisplayName:nil session:session];
}

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:nil folderDisplayName:displayName session:session];
}

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    return [self initWithFolder:folder folderPermissions:permissions folderDisplayName:nil session:session];
}

- (instancetype)initWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        [self setupWithFolder:folder folderPermissions:permissions folderDisplayName:displayName session:session];
    }
    return self;
}

- (instancetype)initWithSiteShortname:(NSString *)siteShortName sitePermissions:(AlfrescoPermissions *)permissions siteDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [self initWithFolder:nil folderPermissions:permissions folderDisplayName:displayName session:session];
    if (self)
    {
        if (siteShortName)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeSiteShortName;
            self.siteShortName = siteShortName;
        }
    }
    return self;
}

- (instancetype)initWithFolderPath:(NSString *)folderPath folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [self initWithFolder:nil folderPermissions:permissions folderDisplayName:displayName session:session];
    if (self)
    {
        if (folderPath)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeFolderPath;
            self.folderPath = folderPath;
        }
    }
    return self;
}

- (instancetype)initWithNodeRef:(NSString *)nodeRef folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [self initWithFolder:nil folderPermissions:permissions folderDisplayName:displayName session:session];
    if (self)
    {
        if (nodeRef)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeNodeRef;
            self.nodeRef = nodeRef;
        }
    }
    return self;
}

- (instancetype)initWithDocumentNodeRef:(NSString *)nodeRef session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if(self)
    {
        [self setupWithFolder:nil folderPermissions:nil folderDisplayName:nil session:session];
        if (nodeRef)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeNodeRef;
            self.nodeRef = nodeRef;
            self.shouldAutoSelectFirstItem = YES;
        }
    }
    
    return self;
}

- (instancetype)initWithDocumentPath:(NSString *)documentPath session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        [self setupWithFolder:nil folderPermissions:nil folderDisplayName:nil session:session];
        if (documentPath)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeDocumentPath;
            self.documentPath = documentPath;
            self.shouldAutoSelectFirstItem = YES;
        }
    }
    
    return self;
}

- (instancetype)initWithSearchString:(NSString *)string searchOptions:(AlfrescoKeywordSearchOptions *)options emptyMessage:(NSString *)emptyMessage session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeSearchString;
        [self setupWithFolder:nil folderPermissions:nil folderDisplayName:string session:session];
        self.previousSearchString = string;
        self.previousSearchOptions = options;
        self.emptyMessage = emptyMessage;
    }
    
    return self;
}

- (instancetype)initWithCustomFolderType:(CustomFolderServiceFolderType)folderType folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        switch (folderType)
        {
            case CustomFolderServiceFolderTypeMyFiles:
            case CustomFolderServiceFolderTypeSharedFiles:
                break;
                
            default:
                AlfrescoLogError(@"%@ / %@: Unknown folder type %@", NSStringFromClass(self.class), _cmd, @(folderType));
                return nil;
        }
        
        self.controllerType = FileFolderCollectionViewControllerTypeCustomFolderType;
        self.customFolderType = folderType;
        [self setupWithFolder:nil folderPermissions:nil folderDisplayName:displayName session:session];
    }
    
    return self;
}

- (instancetype)initWithSearchStatement:(NSString *)statement session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if(self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeCMISSearch;
        [self setupWithFolder:nil folderPermissions:nil folderDisplayName:nil session:session];
        self.CMISSearchStatement = statement;
    }
    
    return self;
}

- (void)setupWithFolder:(AlfrescoFolder *)folder folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    [super setupWithSession:session];
    [self createAlfrescoServicesWithSession:session];
    self.initialFolder = folder;
    self.folderPermissions = permissions;
    self.folderDisplayName = (displayName) ? displayName : folder.name;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdated:) name:kAlfrescoDocumentUpdatedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDeleted:) name:kAlfrescoDocumentDeletedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeAdded:) name:kAlfrescoNodeAddedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdatedOnServer:) name:kAlfrescoSaveBackRemoteComplete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectivityStatusChanged:) name:kAlfrescoConnectivityChangedNotification object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    }
    
    UINib *nodeCellNib = [UINib nibWithNibName:NSStringFromClass([FileFolderCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:nodeCellNib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    UINib *loadingCellNib = [UINib nibWithNibName:NSStringFromClass([LoadingCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:loadingCellNib forCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier]];
    UINib *sectionHeaderNib = [UINib nibWithNibName:NSStringFromClass([SearchCollectionSectionHeader class]) bundle:nil];
    [self.collectionView registerNib:sectionHeaderNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    
    self.title = self.folderDisplayName;
    self.nodePermissions = [[NSMutableDictionary alloc] init];
    
    self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    self.searchController.searchResultsUpdater = self;
    self.searchController.dimsBackgroundDuringPresentation = NO;
    self.searchController.searchBar.delegate = self;
    self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchController.delegate = self;
    self.definesPresentationContext = YES;

    self.collectionView.dataSource = self;
    self.collectionView.delegate = self;
    self.listLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:1 itemHeight:kCellHeight shouldSwipeToDelete:YES hasHeader:YES];
    self.listLayout.dataSourceInfoDelegate = self;
    self.gridLayout = [[BaseCollectionViewFlowLayout alloc] initWithNumberOfColumns:3 itemHeight:-1 shouldSwipeToDelete:NO hasHeader:YES];
    self.gridLayout.dataSourceInfoDelegate = self;
    
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
    
    //Swipe to Delete Gestures
    
    self.swipeToDeleteGestureRecognizer = [[ALFSwipeToDeleteGestureRecognizer alloc] initWithTarget:self action:@selector(swipeToDeletePanGestureHandler:)];
    self.swipeToDeleteGestureRecognizer.delegate = self;
    [self.collectionView addGestureRecognizer:self.swipeToDeleteGestureRecognizer];
    
    self.tapToDismissDeleteAction = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapToDismissDeleteGestureHandler:)];
    self.tapToDismissDeleteAction.numberOfTapsRequired = 1;
    self.tapToDismissDeleteAction.delegate = self;
    [self.collectionView addGestureRecognizer:self.tapToDismissDeleteAction];
    
    [self changeCollectionViewStyle:self.style animated:YES];
    
    if (self.initialFolder)
    {
        self.displayFolder = self.initialFolder;
    }
    else
    {
        [self loadContent];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    if (self.isEditing)
    {
        self.editing = NO;
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    if (!IS_IPAD)
    {
        // hide search bar initially
        self.collectionView.contentSize = CGSizeMake(self.collectionView.contentSize.width, self.collectionView.bounds.size.height - self.collectionView.contentInset.bottom - self.collectionView.contentInset.top + 40.0);
        self.collectionView.contentOffset = CGPointMake(0., 40.);
    }
    
    [self deselectAllItems];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    if(self.shouldAutoSelectFirstItem)
    {
        [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
    }
    else
    {
        [self selectIndexPathForAlfrescoNodeInDetailView];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [self deselectAllItems];
    [super setEditing:editing animated:animated];
    self.collectionView.allowsMultipleSelection = editing;
    
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
        self.swipeToDeleteGestureRecognizer.enabled = NO;
    }
    else
    {
        [self enablePullToRefresh];
        [self.multiSelectToolbar leaveMultiSelectMode:self.multiSelectToolbarHeightConstraint];
    }
    
    if ([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
    {
        BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
        properLayout.editing = editing;
        if (!editing)
        {
            self.swipeToDeleteGestureRecognizer.enabled = properLayout.shouldSwipeToDelete;
        }
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

- (void)deselectAllItems
{
    NSArray *selectedIndexPaths = [self.collectionView indexPathsForSelectedItems];
    for(NSIndexPath *indexPath in selectedIndexPaths)
    {
        [self.collectionView deselectItemAtIndexPath:indexPath animated:NO];
    }
}

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
    if(self.isEditing)
    {
        [self setEditing:!self.editing animated:YES];
    }
    else
    {
        [self setupActionsAlertController];
        self.actionsAlertController.modalPresentationStyle = UIModalPresentationPopover;
        UIPopoverPresentationController *popPC = [self.actionsAlertController popoverPresentationController];
        popPC.barButtonItem = self.editBarButtonItem;
        popPC.permittedArrowDirections = UIPopoverArrowDirectionAny;
        popPC.delegate = self;
        
        [self presentViewController:self.actionsAlertController animated:YES completion:nil];
    }
}

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated
{
    NSMutableArray *rightBarButtonItems = [NSMutableArray array];
    
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
    
    [rightBarButtonItems addObject:self.editBarButtonItem];
    
    if (!self.isEditing && (self.folderPermissions.canAddChildren || self.folderPermissions.canEdit))
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
    
    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.barButtonItem = sender;
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
        }]];

        alertController.modalPresentationStyle = UIModalPresentationPopover;
        
        UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
        popoverPresenter.barButtonItem = self.alertControllerSender;
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
        // Start location services
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
        // Start location services
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

- (void)loadContent
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        switch (self.controllerType)
        {
            case FileFolderCollectionViewControllerTypeFolderNode:
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
            break;
                
            case FileFolderCollectionViewControllerTypeSiteShortName:
            {
                [self showHUD];
                [self.siteService retrieveDocumentLibraryFolderForSite:self.siteShortName completionBlock:^(AlfrescoFolder *documentLibraryFolder, NSError *documentLibraryFolderError) {
                    if (documentLibraryFolderError)
                    {
                        if(documentLibraryFolderError.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                        {
                            // display error
                            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:documentLibraryFolderError]]);
                        }
                        else
                        {
                            [Notifier notifyWithAlfrescoError:documentLibraryFolderError];
                        }
                        [self hideHUD];
                    }
                    else
                    {
                        self.displayFolder = documentLibraryFolder;
                        [self.siteService retrieveSiteWithShortName:self.siteShortName completionBlock:^(AlfrescoSite *site, NSError *error) {
                            self.folderDisplayName = site.title;
                            self.title = self.folderDisplayName;
                        }];
                        [self retrieveContentOfFolder:documentLibraryFolder usingListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
                }];
            }
            break;
                
            case FileFolderCollectionViewControllerTypeFolderPath:
            {
                [self showHUD];
                [self.documentService retrieveNodeWithFolderPath:self.folderPath completionBlock:^(AlfrescoNode *folderPathNode, NSError *folderPathNodeError) {
                    if (folderPathNodeError)
                    {
                        if(folderPathNodeError.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                        {
                            // display error
                            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:folderPathNodeError]]);
                        }
                        else
                        {
                            [Notifier notifyWithAlfrescoError:folderPathNodeError];
                        }
                        [self hideHUD];
                    }
                    else
                    {
                        if ([folderPathNode isKindOfClass:[AlfrescoFolder class]])
                        {
                            self.displayFolder = (AlfrescoFolder *)folderPathNode;
                            self.folderDisplayName = self.displayFolder.name;
                            self.title = self.folderDisplayName;
                            [self retrieveContentOfFolder:(AlfrescoFolder *)folderPathNode usingListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
                        else
                        {
                            AlfrescoLogError(@"Node returned wwith path; %@, is not a folder node", self.folderPath);
                        }
                    }
                }];
            }
            break;
                
            case FileFolderCollectionViewControllerTypeNodeRef:
            {
                [self showHUD];
                [self.documentService retrieveNodeWithIdentifier:self.nodeRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
                    if (nodeRefError)
                    {
                        if(nodeRefError.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                        {
                            // display error
                            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:nodeRefError]]);
                        }
                        else
                        {
                            [Notifier notifyWithAlfrescoError:nodeRefError];
                        }
                        [self hideHUD];
                    }
                    else
                    {
                        if ([nodeRefNode isKindOfClass:[AlfrescoFolder class]])
                        {
                            self.displayFolder = (AlfrescoFolder *)nodeRefNode;
                            self.folderDisplayName = self.displayFolder.name;
                            self.title = self.folderDisplayName;
                            [self retrieveContentOfFolder:(AlfrescoFolder *)nodeRefNode usingListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
                        else if([nodeRefNode isKindOfClass:[AlfrescoDocument class]])
                        {
                            self.collectionViewData = [NSMutableArray arrayWithObject:nodeRefNode];
                            [self hideHUD];
                            [self hidePullToRefreshView];
                            self.folderDisplayName = nodeRefNode.title;
                            [self reloadCollectionView];
                            [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                        }
                    }
                }];
            }
            break;
                
            case FileFolderCollectionViewControllerTypeDocumentPath:
            {
                [self.documentService retrieveNodeWithFolderPath:self.documentPath completionBlock:^(AlfrescoNode *node, NSError *error) {
                    if(node)
                    {
                        self.collectionViewData = [NSMutableArray arrayWithObject:node];
                        [self hideHUD];
                        [self hidePullToRefreshView];
                        [self reloadCollectionView];
                        [self collectionView:self.collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:0 inSection:0]];
                    }
                    else
                    {
                        if(error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                        {
                            // display error
                            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.rootfolder.notfound", @"Root Folder Not Found"), [ErrorDescriptions descriptionForError:error]]);
                        }
                        else
                        {
                            [Notifier notifyWithAlfrescoError:error];
                        }
                        [self hideHUD];
                    }
                }];
            }
            break;
                
            case FileFolderCollectionViewControllerTypeSearchString:
            {
                [self searchString:self.previousSearchString isFromSearchBar:NO searchOptions:self.previousSearchOptions];
                [self updateUIUsingFolderPermissionsWithAnimation:NO];
                [self hidePullToRefreshView];
            }
            break;

            case FileFolderCollectionViewControllerTypeCustomFolderType:
            {
                [self showHUD];
                
                /**
                 * Common completion block for each custom folder type response
                 */
                AlfrescoFolderCompletionBlock completionBlock = ^(AlfrescoFolder *folder, NSError *error) {
                    if (error)
                    {
                        [Notifier notifyWithAlfrescoError:error];
                        [self hidePullToRefreshView];
                        [self hideHUD];
                    }
                    else if (folder == nil)
                    {
                        displayErrorMessage(NSLocalizedString(@"error.alfresco.folder.notfound", @"Folder not found"));
                        [self hidePullToRefreshView];
                        [self hideHUD];
                    }
                    else
                    {
                        self.displayFolder = folder;
                        self.title = self.folderDisplayName;

                        [self retrieveContentOfFolder:(AlfrescoFolder *)folder usingListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
                };
                
                switch (self.customFolderType)
                {
                    case CustomFolderServiceFolderTypeMyFiles:
                        [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:completionBlock];
                        break;
                    
                    case CustomFolderServiceFolderTypeSharedFiles:
                        [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:completionBlock];
                        break;
                        
                    default:
                        break;
                }
                break;
            }
            case FileFolderCollectionViewControllerTypeCMISSearch:
            {
                [self showSearchProgressHUD];
                [self.searchService searchWithStatement:self.CMISSearchStatement language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
                    [self hideSearchProgressHUD];
                    if(array)
                    {
                        self.collectionViewData = [array mutableCopy];
                        [self reloadCollectionView];
                    }
                    else
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.search.searchfailed", @"Search failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];

                    }
                }];
            }
        }
    }
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    self.displayFolder = nil;
    
    [self createAlfrescoServicesWithSession:session];
    
    if (session && [self shouldRefresh])
    {
        [self loadContent];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    [super createAlfrescoServicesWithSession:session];
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    self.customFolderService = [[CustomFolderService alloc] initWithSession:self.session];
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
            if (self.isOnSearchResults)
            {
                collectionViewNodeIdentifiers = [weakSelf.searchResults valueForKeyPath:@"identifier"];
                [weakSelf.searchResults removeObject:nodeToDelete];
                indexPathForNode = [weakSelf indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:collectionViewNodeIdentifiers];
                if (indexPathForNode != nil)
                {
                    [weakSelf.collectionView deleteItemsAtIndexPaths:[NSArray arrayWithObject:indexPathForNode]];
                }
            }
            
            // remove nodeToDelete from collection view
            collectionViewNodeIdentifiers = [weakSelf.collectionViewData valueForKeyPath:@"identifier"];
            if (self.isOnSearchResults)
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
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteMultiSelectedNodes];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];

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
    [self showHUD];
}

- (void)hideSearchProgressHUD
{
    [self hideHUD];
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
    if (self.isOnSearchResults)
    {
        return self.searchResults.count;
    }
    NSInteger loadingIndex = 0;
    if(self.moreItemsAvailable)
    {
        loadingIndex = 1;
    }
    return self.collectionViewData.count + loadingIndex;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if((self.moreItemsAvailable) && (indexPath.item == self.collectionViewData.count) && (!self.isOnSearchResults))
    {
        LoadingCollectionViewCell *cell = (LoadingCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier] forIndexPath:indexPath];
        return cell;
    }
    
    FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[super collectionView:collectionView cellForItemAtIndexPath:indexPath];
    [cell registerForNotifications];
    cell.accessoryViewDelegate = self;
    self.cellActionViewWidth = cell.actionsViewWidthContraint.constant;
    
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
    {
        FileFolderCollectionViewCell *nodeCell = (FileFolderCollectionViewCell *)cell;
        [nodeCell removeNotifications];
    }
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if(((indexPath.item < self.collectionViewData.count) && (!self.isOnSearchResults)) || ((indexPath.item < self.searchResults.count) && (self.isOnSearchResults)))
    {
        AlfrescoNode *selectedNode = nil;
        if (self.isOnSearchResults)
        {
            selectedNode = [self.searchResults objectAtIndex:indexPath.row];
        }
        else
        {
            selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
        }
        
        if (self.isEditing)
        {
            [self.multiSelectToolbar userDidSelectItem:selectedNode];
            FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell wasSelectedInEditMode:YES];
        }
        else
        {
            [self deselectAllItems];
            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
            if ([selectedNode isKindOfClass:[AlfrescoFolder class]])
            {
                [self showHUD];
                [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                    [self hideHUD];
                    if (permissions)
                    {
                        // push again
                        FileFolderCollectionViewController *browserViewController = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderPermissions:permissions session:self.session];
                        browserViewController.style = self.style;
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
            
            if(self.shouldAutoSelectFirstItem)
            {
                self.shouldAutoSelectFirstItem = NO;
            }
        }
    }
}

- (void)collectionView:(UICollectionView *)collectionView didDeselectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isEditing)
    {
        AlfrescoNode *selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
        [self.multiSelectToolbar userDidDeselectItem:selectedNode];
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell wasSelectedInEditMode:NO];
    }
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.collectionViewData.count-1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.item == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.collectionViewData.count) intValue]];
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            self.isLoadingAnotherPage = YES;
            [self retrieveContentOfFolder:self.displayFolder usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self addMoreToCollectionViewWithPagingResult:pagingResult error:error];
                    self.isLoadingAnotherPage = NO;
            }];
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

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        SearchCollectionSectionHeader *headerView = (SearchCollectionSectionHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];
        
        if(!headerView.hasAddedSearchBar)
        {
            headerView.searchBar = self.searchController.searchBar;
            [headerView addSubview:self.searchController.searchBar];
            [self.searchController.searchBar sizeToFit];
        }
        
        reusableview = headerView;
    }
    
    return reusableview;
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
        [self loadContent];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadContent];
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
    AlfrescoNode *nodeToDelete = (self.isOnSearchResults) ? self.searchResults[indexPath.item] : self.collectionViewData[indexPath.item];
    AlfrescoPermissions *permissionsForNodeToDelete = self.nodePermissions[nodeToDelete.identifier];
    
    if (permissionsForNodeToDelete.canDelete)
    {
        [self deleteNode:nodeToDelete completionBlock:^(BOOL success) {
            if([self.collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
            {
                BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
                [properLayout setSelectedIndexPathForSwipeToDelete:nil];
            }
        }];
    }
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    NSIndexPath *selectedIndexPath = nil;
    
    if (self.isOnSearchResults)
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
                    if(indexPath && indexPath.item < self.collectionViewData.count)
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

#pragma mark - DataSourceInformationProtocol methods
- (BOOL) isItemSelected:(NSIndexPath *) indexPath
{
    if(self.isEditing)
    {
        AlfrescoNode *selectedNode = nil;
        if (self.isOnSearchResults)
        {
            if(indexPath.item < self.searchResults.count)
            {
                selectedNode = [self.searchResults objectAtIndex:indexPath.row];
            }
        }
        else
        {
            if(indexPath.item < self.collectionViewData.count)
            {
                selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
            }
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
    if(self.isOnSearchResults)
    {
        index = [self.searchResults indexOfObject:node];
    }
    else
    {
        index = [self.collectionViewData indexOfObject:node];
    }
    
    return index;
}

- (BOOL)isNodeAFolderAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (self.isOnSearchResults)
    {
        if(indexPath.item < self.searchResults.count)
        {
            selectedNode = [self.searchResults objectAtIndex:indexPath.row];
        }
    }
    else
    {
        if(indexPath.item < self.collectionViewData.count)
        {
            selectedNode = [self.collectionViewData objectAtIndex:indexPath.row];
        }
    }
    
    return [selectedNode isKindOfClass:[AlfrescoFolder class]];
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

#pragma mark - Actions methods
- (void)setupActionsAlertController
{
    self.actionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actioncontroller.select", @"Multi-Select") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        [self setEditing:!self.editing animated:YES];
    }];
    editAction.enabled = (self.collectionViewData.count > 0);
    
    [self.actionsAlertController addAction:editAction];
    
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

- (void)changeCollectionViewStyle:(CollectionViewStyle)style animated:(BOOL)animated
{
    [super changeCollectionViewStyle:style animated:animated];
    BaseCollectionViewFlowLayout *associatedLayoutForStyle = [self layoutForStyle:style];
    self.swipeToDeleteGestureRecognizer.enabled = associatedLayoutForStyle.shouldSwipeToDelete;
}

@end
