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

#import "SearchResultsTableViewController.h"
#import "AlfrescoNodeCell.h"
#import "ThumbnailManager.h"
#import "UniversalDevice.h"
#import "RealmSyncManager.h"
#import "AlfrescoNode+Sync.h"
#import "SearchViewController.h"
#import "FavouriteManager.h"
#import "PersonCell.h"
#import "AvatarManager.h"
#import "PersonProfileViewController.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "SearchResultsTableViewDataSource.h"

static CGFloat const kCellHeight = 73.0f;

@interface SearchResultsTableViewController () <SearchResultsTableViewDataSourceDelegate>

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSString *emptyMessage;
@property (nonatomic, strong) UILabel *alfEmptyLabel;
@property (nonatomic, assign) NSNumber *alfPreviousSeparatorStyle;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic) BOOL shouldPush;
@property (nonatomic, strong) SearchResultsTableViewDataSource *dataSource;

@end

@implementation SearchResultsTableViewController

- (instancetype)initWithDataType:(SearchViewControllerDataSourceType)dataType session:(id<AlfrescoSession>)session pushesSelection:(BOOL)shouldPush
{
    self = [super init];
    if (self)
    {
        self.dataType = dataType;
        self.session = session;
        self.shouldPush = shouldPush;
        self.shouldAutoPushFirstResult = NO;
    }
    
    return self;
}

- (instancetype)initWithDataType:(SearchViewControllerDataSourceType)dataType session:(id<AlfrescoSession>)session pushesSelection:(BOOL)shouldPush dataSourceArray:(NSArray *)dataSourceArray
{
    if (self = [self initWithDataType:dataType session:session pushesSelection:shouldPush])
    {
        self.dataSource = [[SearchResultsTableViewDataSource alloc] initWithDataSourceType:dataType results:dataSourceArray delegate:self];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
            [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
            self.emptyMessage = NSLocalizedString(@"No Files", @"No Files");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
            [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
            self.emptyMessage = NSLocalizedString(@"No Folders", @"No Folders");
            break;
        }
        case SearchViewControllerDataSourceTypeSearchSites:
        {
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            UINib *nib = [UINib nibWithNibName:NSStringFromClass([PersonCell class]) bundle:nil];
            [self.tableView registerNib:nib forCellReuseIdentifier:NSStringFromClass([PersonCell class])];
            self.emptyMessage = NSLocalizedString(@"No Users", @"No Users");
            break;
        }
        default:
        {
            break;
        }
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
        
    [self updateEmptyView];
    [self autoPushFirstResultIfNeeded];
    [self trackScreenName];
}

#pragma mark - TableViewDataSource methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.dataSource.searchResultsArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            AlfrescoNodeCell *properCell = (AlfrescoNodeCell *)[tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier] forIndexPath:indexPath];
            
            AlfrescoNode *currentNode = [self.dataSource.searchResultsArray objectAtIndex:indexPath.row];
            RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
            FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
            
            BOOL isSyncNode = [currentNode isNodeInSyncList];
            SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
            [properCell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus];
            [properCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
            
            [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
                
                [properCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
            }];
            
            AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
            UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
            if (thumbnail)
            {
                [properCell.image setImage:thumbnail withFade:NO];
            }
            else
            {
                [properCell.image setImage:smallImageForType([documentNode.name pathExtension]) withFade:NO];
                [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    @try
                    {
                        if (image)
                        {
                            // MOBILE-2991, check the tableView and indexPath objects are still valid as there is a chance
                            // by the time completion block is called the table view could have been unloaded.
                            if (tableView && indexPath)
                            {
                                AlfrescoNodeCell *updateCell = (AlfrescoNodeCell *)[tableView cellForRowAtIndexPath:indexPath];
                                [updateCell.image setImage:image withFade:YES];
                            }
                        }
                    }
                    @catch (NSException *exception)
                    {
                        AlfrescoLogError(@"Exception thrown is %@", exception);
                    }
                }];
            }

            cell = properCell;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            AlfrescoNodeCell *properCell = (AlfrescoNodeCell *)[tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier] forIndexPath:indexPath];
            
            AlfrescoNode *currentNode = [self.dataSource.searchResultsArray objectAtIndex:indexPath.row];
            RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
            FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
            
            BOOL isSyncNode = [currentNode isNodeInSyncList];
            SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
            [properCell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus];
            [properCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
            
            [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
                
                [properCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
            }];
            
            [properCell.image setImage:smallImageForType(@"folder") withFade:NO];
            
            cell = properCell;
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            PersonCell *properCell = (PersonCell *)[tableView dequeueReusableCellWithIdentifier:NSStringFromClass([PersonCell class]) forIndexPath:indexPath];
            AlfrescoPerson *currentPerson = (AlfrescoPerson *)[self.dataSource.searchResultsArray objectAtIndex:indexPath.row];
            properCell.nameLabel.text = currentPerson.fullName;
            
            AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:currentPerson.identifier session:self.session];
            configuration.ignoreCache = YES;
            [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *image, NSError *error) {
                properCell.avatarImageView.image = image;
            }];
            
            cell = properCell;
            break;
        }
        default:
        {
            break;
        }
    }
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

#pragma mark - UITableViewDelegate methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *currentItem = self.dataSource.searchResultsArray[indexPath.row];
    
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
        {
            [self.documentService retrievePermissionsOfNode:currentItem completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    NSString *contentPath = [(AlfrescoDocument *)currentItem contentPath];
                    BOOL isDirectory = NO;
                    if (![[AlfrescoFileManager sharedManager] fileExistsAtPath:contentPath isDirectory:&isDirectory])
                    {
                        contentPath = nil;
                    }
                    
                    if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                    {
                        SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                        [vc pushDocument:currentItem contentPath:contentPath permissions:permissions];
                    }
                }
            }];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchFolders:
        {
            [self.documentService retrievePermissionsOfNode:currentItem completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                if (permissions)
                {
                    if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                    {
                        SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                        [vc pushFolder:(AlfrescoFolder *)currentItem folderPermissions:permissions];
                    }
                }
                else
                {
                    // display permission retrieval error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission failed to be retrieved"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
            break;
        }
        case SearchViewControllerDataSourceTypeSearchUsers:
        {
            AlfrescoPerson *currentPerson = (AlfrescoPerson *)currentItem;
            if(self.shouldPush)
            {
                PersonProfileViewController *personProfileViewController = [[PersonProfileViewController alloc] initWithUsername:currentPerson.identifier session:self.session];
                [UniversalDevice pushToDisplayViewController:personProfileViewController usingNavigationController:self.navigationController animated:YES];
            }
            else
            {
                if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                {
                    SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                    [vc pushUser:currentPerson];
                }
                else if(self.navigationController)
                {
                    PersonProfileViewController *personProfileViewController = [[PersonProfileViewController alloc] initWithUsername:currentPerson.identifier session:self.session];
                    [UniversalDevice pushToDisplayViewController:personProfileViewController usingNavigationController:self.navigationController animated:YES];
                }
            }
        }
        default:
        {
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.dataSource.searchResultsArray[indexPath.row];
    
    if (selectedNode.isFolder)
    {
        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
        
        [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            if (permissions)
            {
                if([self.presentingViewController isKindOfClass:[SearchViewController class]])
                {
                    SearchViewController *vc = (SearchViewController *)self.presentingViewController;
                    [vc pushFolderPreviewForAlfrescoFolder:(AlfrescoFolder *)selectedNode folderPermissions:permissions];
                }
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger lastRowIndex = self.dataSource.searchResultsArray.count - 1;
    
    if (indexPath.row == lastRowIndex)
    {
        int maxItems = self.dataSource.defaultListingContext.maxItems;
        int skipCount = self.dataSource.defaultListingContext.skipCount + (int)self.dataSource.searchResultsArray.count;
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];
        
        if (self.dataSource.moreItemsAvailable)
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;

            [self.dataSource retrieveNextItems:moreListingContext];
        }
    }
}

#pragma mark - Custom setters/getters

- (BOOL)isDataSetEmpty
{
    return self.dataSource.searchResultsArray.count == 0;
}

- (UITableViewCellSeparatorStyle)previousSeparatorStyle
{
    return self.alfPreviousSeparatorStyle ? [self.alfPreviousSeparatorStyle integerValue] : self.tableView.separatorStyle;
}

- (void)setPreviousSeparatorStyle:(UITableViewCellSeparatorStyle)value
{
    self.alfPreviousSeparatorStyle = [NSNumber numberWithInteger:value];
}

#pragma mark - Public methods

- (void)showHUD
{
    [self showHUDWithMode:MBProgressHUDModeIndeterminate];
}

- (void)showHUDWithMode:(MBProgressHUDMode)mode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        self.progressHUD.mode = mode;
        [self.progressHUD show:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hide:YES];
        self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    });
}

- (void)loadViewWithKeyword:(NSString *)keyword
{
    self.title = keyword;
    
    [self search:keyword listingContext:nil];
}

- (void)search:(NSString *)searchString listingContext:(AlfrescoListingContext *)listingContext
{
    if (self.dataSource == nil)
    {
        self.dataSource = [[SearchResultsTableViewDataSource alloc] initWithDataSourceType:self.dataType searchString:searchString session:self.session delegate:self listingContext:listingContext];
    }
    else
    {
        [self.dataSource searchKeyword:searchString session:self.session listingContext:listingContext];
    }
}

- (void)clearDataSource
{
    [self.dataSource clearDataSource];
}

#pragma mark - Private methods

- (void)updateEmptyView
{
    if (!self.alfEmptyLabel)
    {
        UILabel *emptyLabel = [[UILabel alloc] init];
        emptyLabel.font = [UIFont systemFontOfSize:kEmptyListLabelFontSize];
        emptyLabel.numberOfLines = 0;
        emptyLabel.textAlignment = NSTextAlignmentCenter;
        emptyLabel.textColor = [UIColor noItemsTextColor];
        emptyLabel.hidden = YES;
        
        [self.tableView addSubview:emptyLabel];
        self.alfEmptyLabel = emptyLabel;
    }
    
    CGRect frame = self.tableView.bounds;
    frame.origin = CGPointZero;
    frame = UIEdgeInsetsInsetRect(frame, UIEdgeInsetsMake(CGRectGetHeight(self.tableView.tableHeaderView.frame), 0, 0, 0));
    frame.size.height -= self.tableView.contentInset.top;
    
    self.alfEmptyLabel.frame = frame;
    self.alfEmptyLabel.text = self.emptyMessage ?: NSLocalizedString(@"No Files", @"No Files");
    self.alfEmptyLabel.insetTop = -(frame.size.height / 3.0);
    self.alfEmptyLabel.autoresizingMask = (UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth);
    
    BOOL shouldShowEmptyLabel = [self isDataSetEmpty];
    BOOL isShowingEmptyLabel = !self.alfEmptyLabel.hidden;
    
    if (shouldShowEmptyLabel == isShowingEmptyLabel)
    {
        // Nothing to do
        return;
    }
    
    // Need to remove the separator lines in empty mode and restore afterwards
    if (shouldShowEmptyLabel)
    {
        self.previousSeparatorStyle = self.tableView.separatorStyle;
        self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    }
    else
    {
        self.tableView.separatorStyle = self.previousSeparatorStyle;
    }
    self.alfEmptyLabel.hidden = !shouldShowEmptyLabel;
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

- (void)autoPushFirstResultIfNeeded
{
    if(self.shouldAutoPushFirstResult)
    {
        if (!IS_IPAD)
        {
            UIBarButtonItem *hamburgerButtom = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(expandRootRevealController)];
            if (self.navigationController.viewControllers.firstObject == self)
            {
                self.navigationItem.leftBarButtonItem = hamburgerButtom;
            }
        }
        
        if ([self.tableView numberOfRowsInSection:0])
        {
            [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            self.shouldAutoPushFirstResult = NO;
        }
    }
}

- (void)trackScreenName
{
    NSString *screenName = nil;
    
    switch (self.dataType)
    {
        case SearchViewControllerDataSourceTypeSearchFiles:
            screenName = kAnalyticsViewSearchResultFiles;
            break;
            
        case SearchViewControllerDataSourceTypeSearchFolders:
            screenName = kAnalyticsViewSearchResultFolders;
            break;
            
        case SearchViewControllerDataSourceTypeSearchUsers:
            screenName = kAnalyticsViewSearchResultPeople;
            break;
            
        default:
            break;
    }
    
    if (screenName)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
    }
}

#pragma mark - SearchResultsTableViewDataSourceDelegate methods

- (void)dataSourceUpdated
{
    [self updateEmptyView];
    [self.tableView reloadData];
    self.tableView.tableFooterView = nil;
    
    [self autoPushFirstResultIfNeeded];
}

@end
