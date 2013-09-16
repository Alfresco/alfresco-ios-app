//
//  ParentListViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@interface ParentListViewController ()

@property (nonatomic, strong) NSDictionary *imageMappings;
@property (nonatomic, strong) MBProgressHUD *progressHUD;

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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
    }
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        self.tableViewData = [NSMutableArray array];
        self.defaultListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:0];
        self.moreItemsAvailable = NO;
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.view.autoresizesSubviews = YES;
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
    
    // Pull to Refresh
    [self enablePullToRefresh];
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
        self.tableViewData = (data != nil) ? data : [pagingResult.objects mutableCopy];
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
    NSComparator comparator = ^(AlfrescoNode *obj1, AlfrescoNode *obj2)
    {
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
            
            if ([identifier hasPrefix:nodeIdentifier])
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
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        [self.progressHUD show:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hide:YES];
    });
}

- (void)hidePullToRefreshView
{
    dispatch_async(dispatch_get_main_queue(), ^{
        self.lastUpdated = [NSDate date];
        [self.refreshHeaderView refreshLastUpdatedDate];
        [self.refreshHeaderView egoRefreshScrollViewDataSourceDidFinishedLoading:self.tableView];
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
    self.refreshHeaderView = [[CustomEGORefreshTableHeaderView alloc] initWithFrame:CGRectMake(0.0f, 0.0f - self.tableView.bounds.size.height, self.view.frame.size.width, self.tableView.bounds.size.height)
                                                                  arrowImageName:@"pull-to-refresh.png"
                                                                       textColor:[UIColor grayColor]];
    self.refreshHeaderView.delegate = self;
    self.lastUpdated = [NSDate date];
    [self.refreshHeaderView refreshLastUpdatedDate];
    [self.tableView addSubview:self.refreshHeaderView];
}

- (void)disablePullToRefresh
{
    [self.refreshHeaderView removeFromSuperview];
    self.refreshHeaderView = nil;
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
}

#pragma mark - UIScrollViewDelegate Methods

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.tableView)
    {
        [self.refreshHeaderView egoRefreshScrollViewDidScroll:scrollView];
    }
}

- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (scrollView == self.tableView)
    {
        [self.refreshHeaderView egoRefreshScrollViewDidEndDragging:scrollView];
    }
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    AlfrescoLogDebug(@"egoRefreshTableHeaderDidTriggerRefresh: is not implemented in the subclass of %@", [self class]);
}

- (BOOL)egoRefreshTableHeaderDataSourceIsLoading:(EGORefreshTableHeaderView*)view
{
    return NO;
}

- (NSDate *)egoRefreshTableHeaderDataSourceLastUpdated:(EGORefreshTableHeaderView*)view
{
    return self.lastUpdated;
}


@end
