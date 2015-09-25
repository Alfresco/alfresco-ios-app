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

#import "SitesTableListViewController.h"
// Cells
#import "SitesCell.h"
// Managers
#import "LoginManager.h"
#import "AccountManager.h"
// View Controllers
#import "SiteMembersViewController.h"
#import "FileFolderCollectionViewController.h"

static CGFloat const kExpandButtonRotationSpeed = 0.2f;
static CGFloat kSearchCellHeight = 60.0f;

@interface SitesTableListViewController () < UITableViewDelegate, UITableViewDataSource, SiteCellDelegate >

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSIndexPath *expandedCellIndexPath;

@end

@implementation SitesTableListViewController

- (void)loadView
{
    ALFTableView *tableView = [[ALFTableView alloc] initWithFrame:self.view.bounds style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.emptyMessage = NSLocalizedString(@"sites.empty", @"No Sites");
    self.tableView = tableView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
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
    
    AlfrescoSite *currentSite = [self.tableViewData objectAtIndex:indexPath.row];
    siteCell.siteNameLabelView.text = currentSite.title;
    siteCell.siteImageView.image = smallImageForType(@"site");
    siteCell.expandButton.transform = CGAffineTransformMakeRotation([indexPath isEqual:self.expandedCellIndexPath] ? M_PI : 0);
    
    [siteCell updateCellStateWithSite:currentSite];
    
    return siteCell;
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
            
//            [self loadSitesForSiteType:self.segmentedControl.selectedSegmentIndex listingContext:moreListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
//                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
//                self.tableView.tableFooterView = nil;
//            }];
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
    
    [self showHUD];
    [self.siteService retrieveDocumentLibraryFolderForSite:selectedSite.shortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if (folder)
        {
            [self.documentService retrievePermissionsOfNode:folder completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                [self hideHUD];
                if (permissions)
                {
                    FileFolderCollectionViewController *browserListViewController = [[FileFolderCollectionViewController alloc] initWithFolder:folder folderPermissions:permissions folderDisplayName:selectedSite.title session:self.session];
                    
                    [self.navigationController pushViewController:browserListViewController animated:YES];
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
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.documentlibrary.failed", @"Doc Library Retrieval"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }];
    
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

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self.siteService clear];
    if (self.session)
    {
//        [self loadSitesForSelectedSegment:nil];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
//                [self loadSitesForSelectedSegment:nil];
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

@end
