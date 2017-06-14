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

#import "ParentCollectionViewController.h"
#import "ConnectivityManager.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "UIBarButtonItem+MainMenu.h"

@interface ParentCollectionViewController ()

@property (nonatomic, strong) NSDictionary *imageMappings;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@property (nonatomic, strong) UILabel *alfEmptyLabel;

@end

@implementation ParentCollectionViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    return [self initWithSession:session style:CollectionViewStyleList];
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session style:(CollectionViewStyle)style
{
    self = [super initWithNibName:@"ParentCollectionViewController" bundle:nil];
    [self setupWithSession:session];
    if (self)
    {
        self.style = style;
    }
    return self;
}

- (void)setupWithSession:(id<AlfrescoSession>)session
{
    self.session = session;
    self.allowsPullToRefresh = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionReceived:)
                                                 name:kAlfrescoSessionReceivedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(connectivityChanged:)
                                                 name:kAlfrescoConnectivityChangedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(sessionReceived:)
                                                 name:kAlfrescoSessionRefreshedNotification
                                               object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _collectionView.delegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.definesPresentationContext = YES;
    
    if (!IS_IPAD && !self.presentingViewController)
    {
        [UIBarButtonItem setupMainMenuButtonOnViewController:self withHandler:@selector(expandRootRevealController)];
    }
    
    // Pull to Refresh
    if (self.allowsPullToRefresh && [[ConnectivityManager sharedManager] hasInternetConnection])
    {
        [self enablePullToRefresh];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if([[self.collectionView indexPathsForSelectedItems] count] > 0)
    {
        NSArray *arrayOfSelectedItems = [self.collectionView indexPathsForSelectedItems];
        for(NSIndexPath *indexPath in arrayOfSelectedItems)
        {
            [self.collectionView deselectItemAtIndexPath:indexPath animated:YES];
        }
    }
}

#pragma mark - Collection view delegate

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    [collectionView deselectItemAtIndexPath:indexPath animated:YES];
    
    AlfrescoLogDebug(@"collectionView:didSelectItemAtIndexPath: is not implemented in the subclass of %@", [self class]);
}

#pragma mark - Public Functions

- (void)reloadCollectionView
{
    [self.collectionView reloadData];
    if ((!IS_IPAD) && (self.shouldIncludeSearchBar))
    {
        // hide search bar initially
        self.collectionView.contentOffset = CGPointMake(0., 40.);
    }
    [self updateEmptyView];
}

- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)collectionViewNodeIdentifiers
{
    NSIndexPath *indexPath = nil;
    
    if (identifier != nil)
    {
        BOOL (^matchesAlfrescoNodeIdentifier)(NSString *, NSUInteger, BOOL *) = ^(NSString *nodeIdentifier, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            
            if ([nodeIdentifier isKindOfClass:[NSString class]] && [identifier hasPrefix:nodeIdentifier])
            {
                matched = YES;
                *stop = YES;
            }
            return matched;
        };
        
        // See if there's a matching node identifier in tableview node identifiers, using the block defined above
        
        NSUInteger matchingIndex = NSNotFound;
        NSUInteger inSection = 0;
        
        for (int i = 0; i < collectionViewNodeIdentifiers.count; i++)
        {
            id item = collectionViewNodeIdentifiers[i];
            
            if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSMutableArray class]])
            {
                matchingIndex = [item indexOfObjectPassingTest:matchesAlfrescoNodeIdentifier];
                
                if (matchingIndex != NSNotFound)
                {
                    inSection = i;
                    break;
                }
            }
            else
            {
                matchingIndex = [collectionViewNodeIdentifiers indexOfObjectPassingTest:matchesAlfrescoNodeIdentifier];
                break;
            }
        }
        
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:inSection];
        }
    }
    
    return indexPath;
}

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

- (void)hidePullToRefreshView
{
    if (self.refreshControl.isRefreshing)
    {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ui.refreshcontrol.pulltorefresh", @"Pull To Refresh...")];
            [self.refreshControl endRefreshing];
            self.collectionView.contentInset = UIEdgeInsetsZero;
        });
    }
}

- (BOOL)shouldRefresh
{
    if (self.isViewLoaded && self == [self.navigationController.viewControllers objectAtIndex:0])
    {
        return YES;
    }
    return NO;
}

- (void)enablePullToRefresh
{
    if (self.allowsPullToRefresh)
    {
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.backgroundColor = [UIColor whiteColor];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ui.refreshcontrol.pulltorefresh", @"Pull To Refresh...")];
        [refreshControl addTarget:self action:@selector(refreshCollectionView:) forControlEvents:UIControlEventValueChanged];
        self.refreshControl = refreshControl;
        [self.collectionView addSubview:refreshControl];
    }
}

- (void)disablePullToRefresh
{
    [self.refreshControl removeFromSuperview];
    self.refreshControl = nil;
}

- (void)showLoadingTextInRefreshControl:(UIRefreshControl *)refreshControl
{
    dispatch_async(dispatch_get_main_queue(), ^{
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ui.refreshcontrol.refreshing", @"Loading...")];
    });
}

- (void)expandRootRevealController
{
    [(RootRevealViewController *)[UniversalDevice revealViewController] expandViewController];
}

#pragma mark - Custom Getters and Setters

- (void)setAllowsPullToRefresh:(BOOL)allowsPullToRefresh
{
    _allowsPullToRefresh = allowsPullToRefresh;
    
    if (!_allowsPullToRefresh)
    {
        [self disablePullToRefresh];
    }
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
}

- (void)connectivityChanged:(NSNotification *)notification
{
    BOOL hasInternet = [notification.object boolValue];
    if (hasInternet && self.allowsPullToRefresh)
    {
        [self enablePullToRefresh];
    }
    else
    {
        [self disablePullToRefresh];
    }
}

#pragma mark - UIRefreshControl Functions

- (void)refreshCollectionView:(UIRefreshControl *)refreshControl
{
    AlfrescoLogDebug(@"refreshTableView: is not implemented in the subclass of %@", [self class]);
}

#pragma mark - Empty view message
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
        
        [self.collectionView addSubview:emptyLabel];
        self.alfEmptyLabel = emptyLabel;
    }
    
    CGRect frame = self.collectionView.bounds;
    frame.origin = CGPointMake(0, 0);
    frame.size.height -= self.collectionView.contentInset.top;
    
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
    self.alfEmptyLabel.hidden = !shouldShowEmptyLabel;
}

- (BOOL)isDataSetEmpty
{
    return ([self.collectionView.dataSource collectionView:self.collectionView numberOfItemsInSection:0] == 0);
}

#pragma mark - Layout changing
- (void)changeCollectionViewStyle:(CollectionViewStyle)style animated:(BOOL)animated
{
    BaseCollectionViewFlowLayout *associatedLayoutForStyle = [self layoutForStyle:style];
    self.style = style;
    [self.collectionView setCollectionViewLayout:associatedLayoutForStyle animated:animated];
}

- (BaseCollectionViewFlowLayout *)layoutForStyle:(CollectionViewStyle)style
{
    BaseCollectionViewFlowLayout *returnLayout = nil;
    switch (style)
    {
        case CollectionViewStyleList:
        {
            returnLayout = self.listLayout;
        }
            break;
            
        case CollectionViewStyleGrid:
        {
            returnLayout = self.gridLayout;
        }
            break;
    }
    return returnLayout;
}

#pragma mark - DataSourceInformationProtocol methods
- (BOOL) isItemSelected:(NSIndexPath *) indexPath
{
    AlfrescoLogDebug(@"isItemSelected: is not implemented in the subclass of %@", [self class]);
    return NO;
}

- (NSInteger)indexOfNode:(AlfrescoNode *)node
{
    AlfrescoLogDebug(@"indexOfNode: is not implemented in the subclass of %@", [self class]);
    return 0;
}

- (BOOL)isNodeAFolderAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoLogDebug(@"isNodeAFolderAtIndex: is not implemented in the subclass of %@", [self class]);
    return NO;
}

#pragma mark - CollectionViewCellAccessoryViewDelegate methods
- (void)didTapCollectionViewCellAccessorryView:(AlfrescoNode *)node
{
    AlfrescoLogDebug(@"didTapCollectionViewCellAccessoryView: is not implemented in the subclass of %@", [self class]);
}

- (void)setIsOnSearchResults:(BOOL)newValue
{
    _isOnSearchResults = newValue;
    RepositoryCollectionViewDataSource *currentDataSource = nil;
    if(_isOnSearchResults)
    {
        currentDataSource = self.searchDataSource;
    }
    else
    {
        currentDataSource = self.dataSource;
    }
    
    self.collectionView.dataSource = currentDataSource;
    self.listLayout.dataSourceInfoDelegate = currentDataSource;
    self.gridLayout.dataSourceInfoDelegate = currentDataSource;
}

@end
