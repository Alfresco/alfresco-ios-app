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

#import "FileFolderCollectionViewController.h"
#import "BaseFileFolderCollectionViewController+Internal.h"
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
#import <AssetsLibrary/AssetsLibrary.h>
#import "SearchCollectionSectionHeader.h"

#import "FavouriteManager.h"

#import "FavoritesCollectionViewDataSource.h"
#import "SitesCollectionViewDataSource.h"
#import "FolderCollectionViewDataSource.h"
#import "DocumentCollectionViewDataSource.h"
#import "NodeCollectionViewDataSource.h"
#import "SearchCollectionViewDataSource.h"

typedef NS_ENUM(NSUInteger, FileFolderCollectionViewControllerType)
{
    FileFolderCollectionViewControllerTypeFolderNode,
    FileFolderCollectionViewControllerTypeSiteShortName,
    FileFolderCollectionViewControllerTypeFolderPath,
    FileFolderCollectionViewControllerTypeNodeRef,
    FileFolderCollectionViewControllerTypeDocumentPath,
    FileFolderCollectionViewControllerTypeSearchString,
    FileFolderCollectionViewControllerTypeCustomFolderType,
    FileFolderCollectionViewControllerTypeCMISSearch,
    FileFolderCollectionViewControllerTypeFavorites
};

static CGFloat const kSearchBarDisabledAlpha = 0.7f;
static CGFloat const kSearchBarEnabledAlpha = 1.0f;
static CGFloat const kSearchBarAnimationDuration = 0.2f;

@interface FileFolderCollectionViewController () <DownloadsPickerDelegate, MultiSelectActionsDelegate, UploadFormViewControllerDelegate, UIImagePickerControllerDelegate, UINavigationControllerDelegate>

// Views
@property (nonatomic, weak) UISearchBar *searchBar;
// Data Model
@property (nonatomic, assign) BOOL capturingMedia;
@property (nonatomic, strong) NSIndexPath *indexPathOfLoadingCell;
@property (nonatomic, assign) FileFolderCollectionViewControllerType controllerType;
@property (nonatomic) CustomFolderServiceFolderType customFolderType;
@property (nonatomic) BOOL shouldAutoSelectFirstItem;
// Controllers
@property (nonatomic, strong) UIImagePickerController *imagePickerController;

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
        self.controllerType = FileFolderCollectionViewControllerTypeFolderNode;
        self.dataSource = [[FolderCollectionViewDataSource alloc] initWithFolder:folder folderDisplayName:displayName folderPermissions:permissions session:session delegate:self];
    }
    return self;
}

- (instancetype)initWithSiteShortname:(NSString *)siteShortName sitePermissions:(AlfrescoPermissions *)permissions siteDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (siteShortName)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeSiteShortName;
            self.dataSource = [[SitesCollectionViewDataSource alloc] initWithSiteShortname:siteShortName session:session delegate:self];
        }
    }
    return self;
}

- (instancetype)initWithFolderPath:(NSString *)folderPath folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (folderPath)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeFolderPath;
            self.dataSource = [[FolderCollectionViewDataSource alloc] initWithFolderPath:folderPath folderDisplayName:displayName folderPermissions:permissions session:session delegate:self];
        }
    }
    return self;
}

- (instancetype)initWithNodeRef:(NSString *)nodeRef folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (nodeRef)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeNodeRef;
            [NodeCollectionViewDataSource collectionViewDataSourceWithNodeRef:nodeRef session:session delegate:self];
        }
    }
    return self;
}

- (instancetype)initWithDocumentNodeRef:(NSString *)nodeRef session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if(self)
    {
        if (nodeRef)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeNodeRef;
            [NodeCollectionViewDataSource collectionViewDataSourceWithNodeRef:nodeRef session:session delegate:self];
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
        if (documentPath)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeDocumentPath;
            self.dataSource = [[DocumentCollectionViewDataSource alloc] initWithDocumentPath:documentPath session:session delegate:self];
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
        self.dataSource = [[SearchCollectionViewDataSource alloc] initWithSearchString:string searchOptions:options emptyMessage:emptyMessage session:session delegate:self];
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
        self.dataSource = [[FolderCollectionViewDataSource alloc] initWithCustomFolderType:folderType folderDisplayName:displayName session:self.session delegate:self];
    }
    
    return self;
}

- (instancetype)initForFavoritesWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeFavorites;
        self.dataSource = [[FavoritesCollectionViewDataSource alloc] initWithParentNode:nil session:session delegate:self];
    }
    
    return self;
}

- (instancetype)initWithSearchStatement:(NSString *)statement displayName:(NSString *)displayName session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if(self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeCMISSearch;
        self.dataSource = [[SearchCollectionViewDataSource alloc] initWithSearchStatement:statement session:session delegate:self];
    }
    
    return self;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(connectivityStatusChanged:) name:kAlfrescoConnectivityChangedNotification object:nil];
}

- (void)viewDidLoad
{
    self.shouldIncludeSearchBar = (self.controllerType != FileFolderCollectionViewControllerTypeFavorites);
    
    [super viewDidLoad];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeLeft | UIRectEdgeBottom | UIRectEdgeRight;
    }
    
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *nodeCellNib = [UINib nibWithNibName:NSStringFromClass([FileFolderCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:nodeCellNib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    UINib *loadingCellNib = [UINib nibWithNibName:NSStringFromClass([LoadingCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:loadingCellNib forCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier]];
    UINib *sectionHeaderNib = [UINib nibWithNibName:NSStringFromClass([SearchCollectionSectionHeader class]) bundle:nil];
    [self.collectionView registerNib:sectionHeaderNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    
    self.title = self.dataSource.screenTitle;
    
    if(self.shouldIncludeSearchBar)
    {
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleMinimal;
        self.searchController.delegate = self;
        self.definesPresentationContext = YES;
    }

    if(!self.dataSource)
    {
        self.dataSource = [[RepositoryCollectionViewDataSource alloc] initWithParentNode:nil session:self.session delegate:self];
    }
    self.collectionView.dataSource = self.dataSource;
    
    self.multiSelectToolbar.multiSelectDelegate = self;
    [self.multiSelectToolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
    
    [self changeCollectionViewStyle:self.style animated:YES trackAnalytics:NO];
    
    [self registerForNotifications];
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
        if(self.shouldIncludeSearchBar)
        {
            // hide search bar initially
            self.collectionView.contentSize = CGSizeMake(self.collectionView.contentSize.width, self.collectionView.bounds.size.height - self.collectionView.contentInset.bottom - self.collectionView.contentInset.top + 40.0);
            self.collectionView.contentOffset = CGPointMake(0., 40.);
        }
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
    
    if (self.navigationController.viewControllers && self != self.navigationController.viewControllers.firstObject)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:self.style == CollectionViewStyleList ? kAnalyticsViewDocumentListing : kAnalyticsViewDocumentGallery];
        
        return;
    }
    
    NSString *screenName = nil;
    
    if (self.controllerType == FileFolderCollectionViewControllerTypeCustomFolderType) // Shared Files or My Files
    {
        if (self.customFolderType == CustomFolderServiceFolderTypeMyFiles)
            screenName = kAnalyticsViewMenuMyFiles;
        else if (self.customFolderType == CustomFolderServiceFolderTypeSharedFiles)
            screenName = kAnalyticsViewMenuSharedFiles;
    }
    else if (self.controllerType == FileFolderCollectionViewControllerTypeFolderNode) // Repository
    {
        screenName = kAnalyticsViewMenuRepository;
    }
    else if (self.controllerType == FileFolderCollectionViewControllerTypeFavorites) // Favorites
    {
        screenName = kAnalyticsViewMenuFavorites;
    }
    
    [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
    
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

- (void)displayActionSheet:(id)sender event:(UIEvent *)event
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.dataSource.parentFolderPermissions.canAddChildren)
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
                [self.dataSource createFolderWithName:desiredFolderName];
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
        
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionQuickAction
                                                           label:kAnalyticsEventLabelTakePhotoOrVideo
                                                           value:@1];
    }];
}

- (UIAlertAction *)alertActionRecordAudio
{
    return [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actionsheet.record.audio", @"Record Audio") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UploadFormViewController *audioRecorderViewController = [[UploadFormViewController alloc] initWithSession:self.session createAndUploadAudioToFolder:self.displayFolder delegate:self];
        NavigationViewController *audioRecorderNavigationController = [[NavigationViewController alloc] initWithRootViewController:audioRecorderViewController];
        [UniversalDevice displayModalViewController:audioRecorderNavigationController onController:self.navigationController withCompletionBlock:nil];
        
        [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                          action:kAnalyticsEventActionQuickAction
                                                           label:kAnalyticsEventLabelRecordAudio
                                                           value:@1];
    }];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    if (session && [self shouldRefresh])
    {
        [self.dataSource reloadDataSource];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:NO];
    }
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

- (void)connectivityStatusChanged:(NSNotification *)notification
{
    NSNumber *object = [notification object];
    bool hasInternetConnectivity = [object boolValue];
    
    [self.editBarButtonItem setEnabled:hasInternetConnectivity];
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    if([cell isKindOfClass:[FileFolderCollectionViewCell class]])
    {
        FileFolderCollectionViewCell *nodeCell = (FileFolderCollectionViewCell *)cell;
        [nodeCell removeNotifications];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = [self.dataSource alfrescoNodeAtIndex:indexPath.item];
    if(selectedNode)
    {
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
                FileFolderCollectionViewController *browserViewController = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderPermissions:[self.dataSource permissionsForNode:selectedNode] session:self.session];
                browserViewController.style = self.style;
                [self.navigationController pushViewController:browserViewController animated:YES];
                
            }
            else
            {
                NSString *contentPath = [[RealmSyncManager sharedManager] contentPathForNode:(AlfrescoDocument *)selectedNode];
                if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:NO])
                {
                    contentPath = nil;
                }
                
                [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                               permissions:[self.dataSource permissionsForNode:selectedNode]
                                                                               contentFile:contentPath
                                                                          documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                   session:self.session
                                                                      navigationController:self.navigationController
                                                                                  animated:YES];
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
        AlfrescoNode *selectedNode = [self.dataSource alfrescoNodeAtIndex:indexPath.item];
        [self.multiSelectToolbar userDidDeselectItem:selectedNode];
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell wasSelectedInEditMode:NO];
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

#pragma mark - UploadFormViewControllerDelegate Functions

- (void)didFinishUploadingNode:(AlfrescoNode *)node fromLocation:(NSURL *)locationURL
{
    [self.dataSource addAlfrescoNodes:@[node]];
    [self updateUIUsingFolderPermissionsWithAnimation:NO];
    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"upload.success-as.message", @"Document uplaoded as"), node.name]);
}

#pragma mark - UIRefreshControl Functions

- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self.dataSource reloadDataSource];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self.dataSource reloadDataSource];
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
        AlfrescoPermissions *nodePermission = self.dataSource.nodesPermissions[node.identifier];
        if (!nodePermission.canDelete)
        {
            [self.multiSelectToolbar enableAction:kMultiSelectDelete enable:NO];
            break;
        }
    }
}

#pragma mark - Actions methods
- (void)setupActionsAlertController
{
    self.actionsAlertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    if (self.dataSource.parentFolderPermissions.canEdit)
    {
        UIAlertAction *editAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"browser.actioncontroller.select", @"Multi-Select") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self setEditing:!self.editing animated:YES];
        }];
        editAction.enabled = ([self.dataSource numberOfNodesInCollection] > 0);
        
        [self.actionsAlertController addAction:editAction];
    }
    
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
    
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction * action) {
        [self.actionsAlertController dismissViewControllerAnimated:YES completion:nil];
    }];
    
    [self.actionsAlertController addAction:cancelAction];
}

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

@end
