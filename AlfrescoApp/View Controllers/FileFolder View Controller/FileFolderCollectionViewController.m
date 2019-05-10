/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import "MetaDataViewController.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "DocumentPreviewViewController.h"

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

@interface FileFolderCollectionViewController () < MultiSelectActionsDelegate>

// Views
@property (nonatomic, weak) UISearchBar *searchBar;
// Data Model

@property (nonatomic, strong) NSIndexPath *indexPathOfLoadingCell;
@property (nonatomic, assign) FileFolderCollectionViewControllerType controllerType;
@property (nonatomic) CustomFolderServiceFolderType customFolderType;
@property (nonatomic) BOOL shouldAutoSelectFirstItem;

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
        self.dataSource = [[FolderCollectionViewDataSource alloc] initWithFolder:folder folderDisplayName:displayName folderPermissions:permissions session:session delegate:self listingContext:nil];
    }
    return self;
}

- (instancetype)initWithSiteShortname:(NSString *)siteShortName sitePermissions:(AlfrescoPermissions *)permissions siteDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (siteShortName)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeSiteShortName;
            self.dataSource = [[SitesCollectionViewDataSource alloc] initWithSiteShortname:siteShortName session:session delegate:self listingContext:listingContext];
        }
    }
    return self;
}

- (instancetype)initWithFolderPath:(NSString *)folderPath folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (folderPath)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeFolderPath;
            self.dataSource = [[FolderCollectionViewDataSource alloc] initWithFolderPath:folderPath folderDisplayName:displayName folderPermissions:permissions session:session delegate:self listingContext:listingContext];
        }
    }
    return self;
}

- (instancetype)initWithNodeRef:(NSString *)nodeRef folderPermissions:(AlfrescoPermissions *)permissions folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (nodeRef)
        {
            self.controllerType = FileFolderCollectionViewControllerTypeNodeRef;
            [NodeCollectionViewDataSource collectionViewDataSourceWithNodeRef:nodeRef session:session delegate:self listingContext:listingContext];
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
            [NodeCollectionViewDataSource collectionViewDataSourceWithNodeRef:nodeRef session:session delegate:self listingContext:nil];
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

- (instancetype)initWithSearchString:(NSString *)string searchOptions:(AlfrescoKeywordSearchOptions *)options emptyMessage:(NSString *)emptyMessage listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeSearchString;
        self.dataSource = [[SearchCollectionViewDataSource alloc] initWithSearchString:string searchOptions:options emptyMessage:emptyMessage session:session delegate:self listingContext:listingContext];
    }
    
    return self;
}

- (instancetype)initWithCustomFolderType:(CustomFolderServiceFolderType)folderType folderDisplayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
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
        self.dataSource = [[FolderCollectionViewDataSource alloc] initWithCustomFolderType:folderType folderDisplayName:displayName session:self.session delegate:self listingContext:listingContext];
    }
    
    return self;
}

- (instancetype)initForFavoritesWithFilter:(NSString *)filter listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeFavorites;
        self.dataSource = [[FavoritesCollectionViewDataSource alloc] initWithFilter:filter session:session delegate:self listingContext:listingContext];
    }
    
    return self;
}

- (instancetype)initWithSearchStatement:(NSString *)statement displayName:(NSString *)displayName listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if(self)
    {
        self.controllerType = FileFolderCollectionViewControllerTypeCMISSearch;
        self.dataSource = [[SearchCollectionViewDataSource alloc] initWithSearchStatement:statement session:session delegate:self listingContext:listingContext];
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
    
    self.navigationController.navigationBar.translucent = NO;
    
    UINib *nodeCellNib = [UINib nibWithNibName:NSStringFromClass([FileFolderCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:nodeCellNib forCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier]];
    UINib *loadingCellNib = [UINib nibWithNibName:NSStringFromClass([LoadingCollectionViewCell class]) bundle:nil];
    [self.collectionView registerNib:loadingCellNib forCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier]];
    UINib *sectionHeaderNib = [UINib nibWithNibName:NSStringFromClass([SearchCollectionSectionHeader class]) bundle:nil];
    [self.collectionView registerNib:sectionHeaderNib forSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader"];
    
    self.title = self.inUseDataSource.screenTitle;
    
    if(self.shouldIncludeSearchBar)
    {
        self.searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
        self.searchController.searchResultsUpdater = self;
        self.searchController.dimsBackgroundDuringPresentation = NO;
        self.searchController.searchBar.delegate = self;
        self.searchController.searchBar.searchBarStyle = UISearchBarStyleDefault;
        self.searchController.delegate = self;
        
        self.definesPresentationContext = YES;
        
    }

    if(!self.dataSource)
    {
        self.dataSource = [[RepositoryCollectionViewDataSource alloc] initWithParentNode:nil session:self.session delegate:self];
    }
    self.collectionView.dataSource = self.dataSource;
    
    [self changeCollectionViewStyle:self.style animated:YES trackAnalytics:NO];
    
    self.multiSelectContainerView.toolbar.multiSelectDelegate = self;
    [self.multiSelectContainerView.toolbar createToolBarButtonForTitleKey:@"multiselect.button.delete" actionId:kMultiSelectDelete isDestructive:YES];
    self.multiSelectContainerView.heightConstraint = self.multiSelectContainerViewHeightConstraint;
    self.multiSelectContainerView.bottomConstraint = self.multiSelectContainerViewBottomConstraint;
    
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
        if(self.shouldIncludeSearchBar &&
           !self.isOnSearchResults)
        {
            __weak typeof(self) weakSelf = self;
            dispatch_async(dispatch_get_main_queue(), ^{
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.collectionView.contentOffset = CGPointMake(0, kCollectionViewHeaderHight);
            });
        }
    }
    
    [self deselectAllItems];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGRect searchBarFrame = self.searchController.searchBar.frame;
    searchBarFrame.size.width = self.view.frame.size.width;
    self.searchController.searchBar.frame = searchBarFrame;
    
    if (@available(iOS 11.0, *))
    {
        self.multiSelectContainerViewHeightConstraint.constant = kPickerMultiSelectToolBarHeight + self.view.safeAreaInsets.bottom;
    }
    [self.view layoutIfNeeded];
    if(!self.editing)
    {
        [self.multiSelectContainerView hide];
    }
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
        
        [self.multiSelectContainerView show];
        self.swipeToDeleteGestureRecognizer.enabled = NO;
        [self searchBarEnable:NO];
    }
    else
    {
        [self enablePullToRefresh];
        [self.multiSelectContainerView hide];
        [self searchBarEnable:YES];
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

- (void)searchBarEnable:(BOOL)enable
{
    self.searchController.searchBar.userInteractionEnabled = enable;
    self.searchController.searchBar.translucent = enable;
    self.searchController.searchBar.searchBarStyle = (enable) ? UISearchBarStyleDefault : UISearchBarStyleMinimal;
    self.searchController.searchBar.backgroundColor = (enable) ? [UIColor clearColor] : [UIColor lightGrayColor];
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
        [super performEditBarButtonItemAction:sender];
    }
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    if (session && [self shouldRefresh])
    {
        [self.inUseDataSource reloadDataSource];
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
    NSString *titleKey = (self.multiSelectContainerView.toolbar.selectedItems.count == 1) ? @"multiselect.delete.confirmation.message.one-item" : @"multiselect.delete.confirmation.message.n-items";
    NSString *title = [NSString stringWithFormat:NSLocalizedString(titleKey, @"Are you sure you want to delete x items"), self.multiSelectContainerView.toolbar.selectedItems.count];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:title message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"multiselect.button.delete", @"Delete") style:UIAlertActionStyleDestructive handler:^(UIAlertAction *action) {
        [self deleteMultiSelectedNodes];
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:nil]];

    alertController.modalPresentationStyle = UIModalPresentationPopover;
    
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.sourceView = self.multiSelectContainerView;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)deleteMultiSelectedNodes
{
    [self setEditing:NO animated:YES];
    [self showHUD];
    [self deleteNodes:self.multiSelectContainerView.toolbar.selectedItems completionBlock:^(NSInteger numberDeleted, NSInteger numberFailed) {
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
    AlfrescoNode *selectedNode = [self.inUseDataSource alfrescoNodeAtIndex:indexPath.item];
    if(selectedNode)
    {
        if (self.isEditing)
        {
            [self.multiSelectContainerView.toolbar userDidSelectItem:selectedNode];
            FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
            [cell wasSelectedInEditMode:YES];
        }
        else
        {
            [self deselectAllItems];
            [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionNone];
            if ([selectedNode isKindOfClass:[AlfrescoFolder class]])
            {
                FileFolderCollectionViewController *browserViewController = [[FileFolderCollectionViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode folderPermissions:[self.inUseDataSource permissionsForNode:selectedNode] session:self.session];
                browserViewController.style = self.style;
                [self.navigationController pushViewController:browserViewController animated:YES];
                
            }
            else
            {
                NSString *contentPath = [[RealmSyncCore sharedSyncCore] contentPathForNode:selectedNode forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];;
                BOOL isDirectory = NO;
                if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:&isDirectory])
                {
                    contentPath = nil;
                }
                
                [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                               permissions:[self.inUseDataSource permissionsForNode:selectedNode]
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
        AlfrescoNode *selectedNode = [self.inUseDataSource alfrescoNodeAtIndex:indexPath.item];
        [self.multiSelectContainerView.toolbar userDidDeselectItem:selectedNode];
        FileFolderCollectionViewCell *cell = (FileFolderCollectionViewCell *)[self.collectionView cellForItemAtIndexPath:indexPath];
        [cell wasSelectedInEditMode:NO];
    }
}

#pragma mark - UIRefreshControl Functions
- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    self.editBarButtonItem.enabled = NO;
    if (self.session)
    {
        [self.inUseDataSource reloadDataSource];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self.inUseDataSource reloadDataSource];
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
        AlfrescoPermissions *nodePermission = [self.dataSource permissionsForNode:node];
        if (!nodePermission.canDelete)
        {
            [self.multiSelectContainerView.toolbar enableAction:kMultiSelectDelete enable:NO];
            break;
        }
    }
}

@end
