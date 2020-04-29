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
 
#import "ParentListViewController.h"
#import "ConnectivityManager.h"
#import "UniversalDevice.h"
#import "RootRevealViewController.h"
#import "UIBarButtonItem+MainMenu.h"

@interface ParentListViewController ()
@property (nonatomic, strong) NSDictionary *imageMappings;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@end

@implementation ParentListViewController

- (id)initWithNibName:(NSString *)nibName andSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:nibName bundle:nil];
    if (self)
    {
        self.session = session;
        self.tableViewData = [NSMutableArray array];
        self.defaultListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:0];
        self.moreItemsAvailable = NO;
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
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    return [self initWithNibName:nil andSession:session];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView.delegate = nil;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.view.autoresizesSubviews = YES;
    
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
    
    [self.tableView deselectRowAtIndexPath:[self.tableView indexPathForSelectedRow] animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    AlfrescoLogDebug(@"tableView:numberOfRowsInSection: is not implemented in the subclass of %@", [self class]);
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    // config the cell hhere...
    cell.textLabel.text = @"Delegate methods not implemented ...";
    
    AlfrescoLogDebug(@"tableView:cellForRowAtIndexPath: is not implemented in the subclass of %@", [self class]);
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AlfrescoLogDebug(@"tableView:didSelectRowAtIndexPath: is not implemented in the subclass of %@", [self class]);
}

#pragma mark - Public Functions

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    [self reloadTableViewWithPagingResult:pagingResult data:nil error:error];
}

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data  error:(NSError *)error
{
    if (pagingResult)
    {
        self.tableViewData = data ?: [pagingResult.objects mutableCopy];
        self.moreItemsAvailable = pagingResult.hasMoreItems;
        [self.tableView reloadData];
    }
    else
    {
        // display error
    }
}

- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    [self addMoreToTableViewWithPagingResult:pagingResult data:nil error:error];
}

- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error
{
    if (pagingResult)
    {
        if (data)
        {
            self.tableViewData = data;
        }
        else
        {
           [self.tableViewData addObjectsFromArray:pagingResult.objects]; 
        }
        
        self.moreItemsAvailable = pagingResult.hasMoreItems;
        [self.tableView reloadData];
    }
    else
    {
        // display error
    }
}

- (void)addAlfrescoNodes:(NSArray *)alfrescoNodes withRowAnimation:(UITableViewRowAnimation)rowAnimation
{
    NSComparator comparator = ^(AlfrescoNode *obj1, AlfrescoNode *obj2) {
        return (NSComparisonResult)[obj1.name caseInsensitiveCompare:obj2.name];
    };
    
    NSMutableArray *newNodeIndexPaths = [NSMutableArray arrayWithCapacity:alfrescoNodes.count];
    for (AlfrescoNode *node in alfrescoNodes)
    {
        // add to the tableView data source at the correct index
        NSUInteger newIndex = [self.tableViewData indexOfObject:node inSortedRange:NSMakeRange(0, self.tableViewData.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
        [self.tableViewData insertObject:node atIndex:newIndex];
        // create index paths to animate into the table view
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        [newNodeIndexPaths addObject:indexPath];
    }

    [self.tableView insertRowsAtIndexPaths:newNodeIndexPaths withRowAnimation:rowAnimation];
}

- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)tableViewNodeIdentifiers
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
        
        for (int i = 0; i < tableViewNodeIdentifiers.count; i++)
        {
            id item = tableViewNodeIdentifiers[i];
            
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
                matchingIndex = [tableViewNodeIdentifiers indexOfObjectPassingTest:matchesAlfrescoNodeIdentifier];
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
    dispatch_async(dispatch_get_main_queue(), ^{
        self.refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ui.refreshcontrol.pulltorefresh", @"Pull To Refresh...")];
        [self.refreshControl endRefreshing];
    });
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
        UITableViewController *tableViewController = [[UITableViewController alloc] init];
        tableViewController.tableView = self.tableView;
        UIRefreshControl *refreshControl = [[UIRefreshControl alloc] init];
        refreshControl.backgroundColor = [UIColor whiteColor];
        refreshControl.attributedTitle = [[NSAttributedString alloc] initWithString:NSLocalizedString(@"ui.refreshcontrol.pulltorefresh", @"Pull To Refresh...")];
        [refreshControl addTarget:self action:@selector(refreshTableView:) forControlEvents:UIControlEventValueChanged];
        tableViewController.refreshControl = refreshControl;
        self.refreshControl = refreshControl;
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

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    AlfrescoLogDebug(@"refreshTableView: is not implemented in the subclass of %@", [self class]);
}

@end
