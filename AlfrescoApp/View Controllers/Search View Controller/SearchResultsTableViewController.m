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

#import "SearchResultsTableViewController.h"
#import "AlfrescoNodeCell.h"
#import "UniversalDevice.h"
#import "AlfrescoNode+Sync.h"
#import "SearchViewController.h"
#import "PersonCell.h"
#import "PersonProfileViewController.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "SearchResultsTableViewDataSource.h"
#import "UIBarButtonItem+MainMenu.h"
#import "RealmSyncCore.h"
#import "AccountManager.h"

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
        self.tableView.dataSource = self.dataSource;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
    
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - UITableViewDelegate methods

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if(self.dataSource.searchResultsArray.count)
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
                        NSString *contentPath = [[RealmSyncCore sharedSyncCore] contentPathForNode:currentItem forAccountIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];
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
        [self.progressHUD showAnimated:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideAnimated:YES];
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
        self.tableView.dataSource = self.dataSource;
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

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
}

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
            [UIBarButtonItem setupMainMenuButtonOnViewController:self withHandler:@selector(expandRootRevealController)];
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
