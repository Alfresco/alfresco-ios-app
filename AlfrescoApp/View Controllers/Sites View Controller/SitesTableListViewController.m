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

#import "SitesTableListViewController.h"
// Cells
#import "SitesCell.h"
// Managers
#import "LoginManager.h"
#import "AccountManager.h"
#import "ConnectivityManager.h"
// View Controllers
#import "SiteMembersViewController.h"
#import "FileFolderCollectionViewController.h"
// Data Sources
#import "SearchResultsTableViewDataSource.h"

@interface SitesTableListViewController () < UITableViewDelegate, UITableViewDataSource, SiteCellDelegate, SearchResultsTableViewDataSourceDelegate>

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSIndexPath *expandedCellIndexPath;
@property (nonatomic) SiteListTypeSelection listType;
@property (nonatomic, weak) UIViewController *pushHandler;
@property (nonatomic, strong) SearchResultsTableViewDataSource *dataSource;

@end

@implementation SitesTableListViewController

- (instancetype)initWithType:(SiteListTypeSelection)listType session:(id<AlfrescoSession>)session pushHandler:(UIViewController *)viewController listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super initWithSession:session];
    
    if (self)
    {
        self.listType = listType;
        self.pushHandler = viewController;
        
        if (listingContext)
        {
            self.defaultListingContext = listingContext;
        }
        
        [self createAlfrescoServicesWithSession:session];
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    ALFTableView *tableView = [[ALFTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.emptyMessage = NSLocalizedString(@"sites.empty", @"No Sites");
    self.tableView = tableView;

    if (self.listType != SiteListTypeSelectionSearch)
    {
        [self enablePullToRefresh];
    }

    [self.view addSubview:self.tableView];

    if (self.listType != SiteListTypeSelectionSearch)
    {
        [self showHUD];
        [self loadSitesForSiteType:self.listType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.listType == SiteListTypeSelectionSearch)
    {
        [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewSearchResultSites];
    }
}

#pragma mark - Table view data source and delegate methods

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SitesCell";
    
    SitesCell *siteCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!siteCell)
    {
        siteCell = (SitesCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SitesCell class]) owner:self options:nil] objectAtIndex:0];
        siteCell.delegate = self;
    }
    
    if (indexPath.row < self.tableViewData.count)
    {
        AlfrescoSite *currentSite = [self.tableViewData objectAtIndex:indexPath.row];
        siteCell.siteNameLabelView.text = currentSite.title;
        siteCell.siteImageView.image = smallImageForType(@"site");
        siteCell.expandButton.transform = CGAffineTransformMakeRotation([indexPath isEqual:self.expandedCellIndexPath] ? M_PI : 0);
        
        [siteCell updateCellStateWithSite:currentSite];
    }
        
    return siteCell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.tableViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastSiteRowIndex)
    {
        int maxItems = self.defaultListingContext.maxItems;
        int skipCount = self.defaultListingContext.skipCount + (int)self.tableViewData.count;
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];
        if (self.moreItemsAvailable)
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            if (self.dataSource)
            {
                [self.dataSource retrieveNextItems:moreListingContext];
            }
            else
            {
                [self loadSitesForSiteType:self.listType listingContext:moreListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                    self.tableView.tableFooterView = nil;
                }];
            }
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [indexPath isEqual:self.expandedCellIndexPath] ? SitesCellExpandedHeight : SitesCellDefaultHeight;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.expandedCellIndexPath = nil;

    AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:indexPath.row];
    
    if(selectedSite)
    {
        [self showHUD];
        [self.siteService retrieveDocumentLibraryFolderForSite:selectedSite.shortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
            if (folder)
            {
                [self.documentService retrievePermissionsOfNode:folder completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                    [self hideHUD];
                    if (permissions)
                    {
                        FileFolderCollectionViewController *browserListViewController = [[FileFolderCollectionViewController alloc] initWithFolder:folder folderPermissions:permissions folderDisplayName:selectedSite.title session:self.session];
                        
                        [self.pushHandler.navigationController pushViewController:browserListViewController animated:YES];
                    }
                    else
                    {
                        // display permission retrieval error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission Retrieval"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    [tableView deselectRowAtIndexPath:indexPath animated:YES];
                }];
            }
            else
            {
                // show error
                [self hideHUD];
                
                NSString *errorString = [ErrorDescriptions descriptionForError:error];
                if (!errorString)
                {
                    errorString = NSLocalizedString(@"error.access.permissions.message", @"Check you have permission...");
                }
                
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.documentlibrary.failed", @"Doc Library Retrieval"), errorString]);
                [Notifier notifyWithAlfrescoError:error];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
    }
}

#pragma mark - Custom Setters

- (void)setExpandedCellIndexPath:(NSIndexPath *)expandedCellIndexPath
{
    NSMutableArray *indexPaths = [NSMutableArray new];
    SitesCell *siteCell;
    
    if (self.expandedCellIndexPath)
    {
        // Start collapsing an existing expanded cell
        siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:_expandedCellIndexPath];
        if (siteCell)
        {
            [indexPaths addObject:_expandedCellIndexPath];
            [self rotateView:siteCell.expandButton duration:kExpandButtonRotationSpeed angle:0.0f];
        }
    }
    
    _expandedCellIndexPath = expandedCellIndexPath;
    
    if (expandedCellIndexPath)
    {
        // Start expanding the new cell
        siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:expandedCellIndexPath];
        if (siteCell)
        {
            [indexPaths addObject:expandedCellIndexPath];
            [self rotateView:siteCell.expandButton duration:kExpandButtonRotationSpeed angle:M_PI];
        }
    }
    
    if (indexPaths.count > 0)
    {
        [self.tableView reloadRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Custom Getters

- (NSArray *)tableViewData
{
    return self.dataSource ? self.dataSource.searchResultsArray : [super tableViewData];
}

- (BOOL)moreItemsAvailable
{
    return self.dataSource ? self.dataSource.moreItemsAvailable : [super moreItemsAvailable];
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self.siteService clear];
    if (self.session)
    {
        [self loadSitesForSelectedSegment:nil];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadSitesForSelectedSegment:nil];
            }
        }];
    }
}

#pragma mark - Private methods

- (void)rotateView:(UIView *)view duration:(CGFloat)duration angle:(CGFloat)angle
{
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        view.transform = CGAffineTransformMakeRotation(angle);
    } completion:nil];
}

- (void)loadSitesForSelectedSegment:(id)sender
{
    self.expandedCellIndexPath = nil;
    
    [self showHUD];
    [self loadSitesForSiteType:self.listType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        [self reloadTableViewWithPagingResult:pagingResult error:error];
        [self hidePullToRefreshView];
    }];
}

- (void)loadSitesForSiteType:(SiteListTypeSelection)siteType
              listingContext:(AlfrescoListingContext *)listingContext
         withCompletionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection] && self.session)
    {
        switch (siteType)
        {
            case SiteListTypeSelectionMySites:
            {
                self.view.accessibilityIdentifier = kSitesTableListVCMySitesViewIdentifier;
                [self.siteService retrieveSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    if (error)
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.retrieval.failed", @"Sites Retrieval Failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    completionBlock(pagingResult, error);
                }];
            }
                break;
                
            case SiteListTypeSelectionFavouriteSites:
            {
                self.view.accessibilityIdentifier = kSitesTableListVCFavoriteSitesViewIdentifier;
                [self.siteService retrieveFavoriteSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    if (error)
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.retrieval.failed", @"Sites Retrieval Failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    completionBlock(pagingResult, error);
                }];
            }
                break;
                
            case SiteListTypeSelectionAllSites:
            {
                self.view.accessibilityIdentifier = kSitesTableListVCAllSitesViewIdentifier;
                [self.siteService retrieveAllSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    if (error)
                    {
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.retrieval.failed", @"Sites Retrieval Failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                    completionBlock(pagingResult, error);
                }];
            }
                break;
                
            default:
                break;
        }
    }
    else
    {
        if (completionBlock != NULL)
        {
            completionBlock(nil, nil);
        }
    }
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
}

- (void)removeSites:(NSArray *)sitesArray withRowAnimation:(UITableViewRowAnimation)rowAnimation
{
    NSMutableArray *removalIndexPaths = [NSMutableArray arrayWithCapacity:sitesArray.count];
    
    for (AlfrescoSite *site in sitesArray)
    {
        NSInteger index = [self.tableViewData indexOfObject:site];
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:index inSection:0];
        [removalIndexPaths addObject:indexPath];
        // remove the site from the data array
        [self.tableViewData removeObject:site];
    }
    
    [self.tableView deleteRowsAtIndexPaths:removalIndexPaths withRowAnimation:UITableViewRowAnimationTop];
}

- (void)addSites:(NSArray *)sitesArray withRowAnimation:(UITableViewRowAnimation)rowAnimation
{
    NSComparator comparator = ^(AlfrescoSite *obj1, AlfrescoSite *obj2)
    {
        return (NSComparisonResult)[obj1.title caseInsensitiveCompare:obj2.title];
    };
    
    NSMutableArray *newNodeIndexPaths = [NSMutableArray arrayWithCapacity:sitesArray.count];
    for (AlfrescoSite *site in sitesArray)
    {
        // add to the tableView data source at the correct index
        NSUInteger newIndex = [self.tableViewData indexOfObject:site inSortedRange:NSMakeRange(0, self.tableViewData.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
        [self.tableViewData insertObject:site atIndex:newIndex];
        // create index paths to animate into the table view
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        [newNodeIndexPaths addObject:indexPath];
    }
    
    [self.tableView insertRowsAtIndexPaths:newNodeIndexPaths withRowAnimation:rowAnimation];
}

#pragma mark - SiteCellDelegate Functions

- (void)siteCell:(SitesCell *)siteCell didPressExpandButton:(UIButton *)expandButton
{
    NSIndexPath *selectedSiteIndexPath = [self.tableView indexPathForCell:siteCell];
    
    // if it's been tapped again, we want to collapse the cell
    if ([selectedSiteIndexPath isEqual:self.expandedCellIndexPath])
    {
        self.expandedCellIndexPath = nil;
    }
    else
    {
        self.expandedCellIndexPath = selectedSiteIndexPath;
    }
}

- (void)siteCell:(SitesCell *)siteCell didPressFavoriteButton:(UIButton *)favoriteButton
{
    NSIndexPath *selectedSiteIndexPath = [self.tableView indexPathForCell:siteCell];
    AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:selectedSiteIndexPath.row];
    
    favoriteButton.enabled = NO;
    
    __weak SitesTableListViewController *weakSelf = self;
    SiteListTypeSelection siteListShowingAtSelection = self.listType;
    
    if (selectedSite.isFavorite)
    {
        [self.siteService removeFavoriteSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            favoriteButton.enabled = YES;
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySite
                                                              action:kAnalyticsEventActionFavorite
                                                               label:kAnalyticsEventLabelDisable
                                                               value:@1];
            
            if (site)
            {
                // if the favourites are displayed, remove from the table view, otherwise replace the site with the updated one
                if (weakSelf.listType == SiteListTypeSelectionFavouriteSites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf removeSites:@[selectedSite] withRowAnimation:UITableViewRowAnimationTop];
                }
                else if (siteListShowingAtSelection == weakSelf.listType)
                {
                    [weakSelf.tableViewData replaceObjectAtIndex:selectedSiteIndexPath.row withObject:site];
                    [siteCell updateCellStateWithSite:site];
                }
                
                displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.unfavorited.banner", @"Site Unfavorited Message"), site.title]);
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.unable.to.unfavorite", @"Unable To Unfavorite"), selectedSite.title]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [self.siteService addFavoriteSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            favoriteButton.enabled = YES;
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySite
                                                              action:kAnalyticsEventActionFavorite
                                                               label:kAnalyticsEventLabelEnable
                                                               value:@1];
            
            if (site)
            {
                // if the favourites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.listType == SiteListTypeSelectionFavouriteSites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf addSites:@[site] withRowAnimation:UITableViewRowAnimationFade];
                }
                else if (siteListShowingAtSelection == weakSelf.listType)
                {
                    [weakSelf.tableViewData replaceObjectAtIndex:selectedSiteIndexPath.row withObject:site];
                    [siteCell updateCellStateWithSite:site];
                }
                
                displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.favorited.banner", @"Site Favorited Message"), site.title]);
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.unable.to.favorite", @"Unable To Favorite"), selectedSite.title]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
}

- (void)siteCell:(SitesCell *)siteCell didPressJoinButton:(UIButton *)joinButton
{
    NSIndexPath *selectedSiteIndexPath = [self.tableView indexPathForCell:siteCell];
    AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:selectedSiteIndexPath.row];
    
    joinButton.enabled = NO;
    
    __weak SitesTableListViewController *weakSelf = self;
    SiteListTypeSelection siteListShowingAtSelection = self.listType;
    
    if (!selectedSite.isMember && !selectedSite.isPendingMember)
    {
        [self.siteService joinSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            joinButton.enabled = YES;
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySite
                                                              action:kAnalyticsEventActionMembership
                                                               label:kAnalyticsEventLabelJoin
                                                               value:@1];
            
            if (site)
            {
                // if my sites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.listType == SiteListTypeSelectionMySites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf addSites:@[site] withRowAnimation:UITableViewRowAnimationFade];
                }
                else if (siteListShowingAtSelection == weakSelf.listType)
                {
                    [weakSelf.tableViewData replaceObjectAtIndex:selectedSiteIndexPath.row withObject:site];
                    [siteCell updateCellStateWithSite:site];
                }
                
                if (site.isMember)
                {
                    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.joined.banner", @"Joined Site Message"), site.title]);
                }
                else if (site.isPendingMember)
                {
                    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.requested.to.join.banner", @"Request To Join Message"), site.title]);
                }
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.unable.to.join", @"Unable To Join"), selectedSite.title]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else if (selectedSite.isPendingMember)
    {
        // cancel the request
        [self.siteService cancelPendingJoinRequestForSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            joinButton.enabled = YES;
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySite
                                                              action:kAnalyticsEventActionMembership
                                                               label:kAnalyticsEventLabelCancel
                                                               value:@1];
            
            if (site)
            {
                // replace the site with the updated one, if the all sites are displayed
                if ((weakSelf.listType == SiteListTypeSelectionAllSites) || (weakSelf.listType == SiteListTypeSelectionSearch))
                {
                    [weakSelf.tableViewData replaceObjectAtIndex:selectedSiteIndexPath.row withObject:site];
                    [siteCell updateCellStateWithSite:site];
                }
                
                displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.request.cancelled.banner", @"Request To Cancel Request Message"), site.title]);
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.unable.to.cancel.request", @"Unable To Cancel Request"), selectedSite.title]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [self.siteService leaveSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            joinButton.enabled = YES;
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySite
                                                              action:kAnalyticsEventActionMembership
                                                               label:kAnalyticsEventLabelLeave
                                                               value:@1];
            
            if (site)
            {
                // if my sites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.listType == SiteListTypeSelectionMySites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf removeSites:@[selectedSite] withRowAnimation:UITableViewRowAnimationTop];
                }
                else if (siteListShowingAtSelection == weakSelf.listType)
                {
                    [weakSelf.tableViewData replaceObjectAtIndex:selectedSiteIndexPath.row withObject:site];
                    [siteCell updateCellStateWithSite:site];
                }
                
                displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"sites.site.left.banner", @"Left Site Message"), site.title]);
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.unable.to.leave", @"Unable to Leave"), selectedSite.title]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
}

- (void)siteCell:(SitesCell *)siteCell didPressMembersButton:(UIButton *)membersButton
{
    NSIndexPath *selectedSiteIndexPath = [self.tableView indexPathForCell:siteCell];
    AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:selectedSiteIndexPath.row];
    
    SiteMembersViewController *membersVC = [[SiteMembersViewController alloc] initWithSiteShortName:selectedSite.shortName listingContext:nil session:self.session displayName:selectedSite.title];
    [self.pushHandler.navigationController pushViewController:membersVC animated:YES];
}

#pragma mark - Public methods

- (void)search:(NSString *)searchString listingContext:(AlfrescoListingContext *)listingContext
{
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    self.dataSource = [[SearchResultsTableViewDataSource alloc] initWithDataSourceType:SearchViewControllerDataSourceTypeSearchSites searchString:searchString session:self.session delegate:self listingContext:self.defaultListingContext];
}

- (void)clearDataSource
{
    [self.dataSource clearDataSource];
}

- (void)updateSession:(id<AlfrescoSession>)session {
    self.session = session;
    [self createAlfrescoServicesWithSession:session];
}

#pragma mark - SearchResultsTableViewDataSourceDelegate

- (void)dataSourceUpdated
{
    [self.tableView reloadData];
    self.tableView.tableFooterView = nil;
}

@end
