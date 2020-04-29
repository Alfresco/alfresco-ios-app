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
 
#import "SitesListViewController.h"
#import "FileFolderCollectionViewController.h"
#import "UniversalDevice.h"
#import "SitesCell.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "AlfrescoNodeCell.h"
#import "MetaDataViewController.h"
#import "ThumbnailManager.h"
#import "AccountManager.h"
#import "FilePreviewViewController.h"
#import "PreferenceManager.h"
#import "SiteMembersViewController.h"
#import "UISearchBar+Paste.h"

static CGFloat const kSearchBarSpeed = 0.3f;

static NSString * const kSitesFolderLocation = @"/Sites";
static NSString * const kSitesPreviousSearchThumbnailMappingsFileName = @"SitesSearchMappings";

static CGFloat kSearchCellHeight = 60.0f;

@interface SitesListViewController () <UISearchControllerDelegate>

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) NSIndexPath *expandedCellIndexPath;
@property (nonatomic, assign) SitesListViewFilter sitesFilter;
@property (nonatomic, assign) SiteListTypeSelection selectedListType;
@property (nonatomic, strong) MBProgressHUD *searchProgressHUD;

@end

@implementation SitesListViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
        self.title = NSLocalizedString(@"sites.title", @"Sites Title");
    }
    return self;
}

- (instancetype)initWithSitesListFilter:(SitesListViewFilter)filter title:(NSString *)title session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.sitesFilter = filter;
        self.selectedListType = [self selectionTypeForFilter:filter];
        if (title)
        {
            self.title = title;
        }
    }
    return self;
}

- (void)dealloc
{
    [_searchController.view removeFromSuperview];
}

- (void)loadView
{    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[
                                   NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites"),
                                   NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites"),
                                   NSLocalizedString(@"sites.segmentControl.allsites", @"All Sites")]];
    segment.frame = CGRectMake((view.frame.origin.x + (kUISegmentControlHorizontalPadding / 2)),
                               (view.frame.origin.y + kUISegmentControlVerticalPadding),
                               view.frame.size.width - kUISegmentControlVerticalPadding,
                               kUISegmentControllerHeight - kUISegmentControlVerticalPadding);
    [segment addTarget:self action:@selector(loadSitesForSelectedSegment:) forControlEvents:UIControlEventValueChanged];
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segment.selectedSegmentIndex = [self selectionTypeForFilter:self.sitesFilter];
    self.selectedListType = segment.selectedSegmentIndex;
    self.segmentedControl = segment;
    [view addSubview:self.segmentedControl];
    
    // create and configure the table view
    BOOL shouldHideSegmentControl = (self.sitesFilter != SitesListViewFilterNoFilter);
    CGFloat tableOrigin = view.frame.origin.y + kUISegmentControllerHeight;
    CGFloat tableHeight = view.frame.size.height - kUISegmentControllerHeight;
    
    if (shouldHideSegmentControl)
    {
        tableOrigin = view.frame.origin.y;
        tableHeight = view.frame.size.height;
    }
    
    ALFTableView *tableView = [[ALFTableView alloc] initWithFrame:CGRectMake(view.frame.origin.x,
                                                                             tableOrigin,
                                                                             view.frame.size.width,
                                                                             tableHeight)
                                                            style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.emptyMessage = NSLocalizedString(@"sites.empty", @"No Sites");
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    // search controller
    UISearchController *searchController = [[UISearchController alloc] initWithSearchResultsController:nil];
    searchController.delegate = self;
    searchController.searchBar.delegate = self;
    
    searchController.obscuresBackgroundDuringPresentation = NO;
    searchController.hidesNavigationBarDuringPresentation = YES;
    
    // search bar
    self.searchBar = searchController.searchBar;
    self.searchBar.frame = CGRectMake(view.frame.origin.x,
                                      view.frame.origin.y,
                                      view.frame.size.width,
                                      44.0f);
    self.searchBar.searchBarStyle = UISearchBarStyleMinimal;
    self.searchBar.backgroundColor = [UIColor whiteColor];
    self.searchController = searchController;
    
    // add the searchBar to the tableview
    self.tableView.tableHeaderView = self.searchBar;
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (!IS_IPAD)
    {
        // hide search bar initially
        self.tableView.contentOffset = CGPointMake(0., 40.);
    }
    
    if (self.session)
    {
        [self showHUD];
        [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error)
         {
             [self hideHUD];
             [self reloadTableViewWithPagingResult:pagingResult error:error];
         }];
    }
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.isDisplayingSearch)
    {
        return self.searchResults.count;
    }
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SitesCell";
    static NSString *SearchCellIdentifier = @"AlfrescoNodeCell";
    
    SitesCell *siteCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    AlfrescoNodeCell *searchCell = [tableView dequeueReusableCellWithIdentifier:SearchCellIdentifier];
    
    UITableViewCell *returnCell = nil;
    
    if (!siteCell)
    {
        siteCell = (SitesCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SitesCell class]) owner:self options:nil] objectAtIndex:0];
        siteCell.delegate = self;
    }
    
    if (!searchCell)
    {
        searchCell = (AlfrescoNodeCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AlfrescoNodeCell class]) owner:self options:nil] lastObject];
    }
    
    if (!self.isDisplayingSearch)
    {
        returnCell = siteCell;
        
        AlfrescoSite *currentSite = [self.tableViewData objectAtIndex:indexPath.row];
        siteCell.siteNameLabelView.text = currentSite.title;
        siteCell.siteImageView.image = smallImageForType(@"site");
        siteCell.expandButton.transform = CGAffineTransformMakeRotation([indexPath isEqual:self.expandedCellIndexPath] ? M_PI : 0);
        
        [siteCell updateCellStateWithSite:currentSite];
    }
    else
    {
        returnCell = searchCell;
        
        AlfrescoNode *node = [self.searchResults objectAtIndex:indexPath.row];
        
        if ([node isKindOfClass:[AlfrescoDocument class]])
        {
            AlfrescoDocument *documentNode = (AlfrescoDocument *)node;
            
            searchCell.filename.text = documentNode.name;
            
            UIImage *thumbnailImage = [[ThumbnailManager sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
            
            if (thumbnailImage)
            {
                [searchCell.image setImage:thumbnailImage withFade:NO];
            }
            else
            {
                // set a placeholder image
                [searchCell.image setImage:smallImageForType([documentNode.name pathExtension]) withFade:NO];
                
                [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    if (image)
                    {
                        AlfrescoNodeCell *updateCell = (AlfrescoNodeCell *)[tableView cellForRowAtIndexPath:indexPath];
                        if (updateCell)
                        {
                            [updateCell.image setImage:image withFade:YES];
                        }
                    }
                }];
            }
            
            NSString *modifiedDateString = relativeTimeFromDate(documentNode.modifiedAt);
            searchCell.details.text = [NSString stringWithFormat:@"%@ • %@", modifiedDateString, stringForLongFileSize(documentNode.contentLength)];
            searchCell.accessoryView = [self makeDetailDisclosureButton];
        }
        else
        {
            AlfrescoFolder *folderNode = (AlfrescoFolder *)node;
            
            [searchCell.image setImage:smallImageForType(@"folder") withFade:NO];
            searchCell.filename.text = folderNode.name;
            searchCell.details.text = @"";
        }
        
    }
    
    return returnCell;
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
            
            [self loadSitesForSiteType:self.segmentedControl.selectedSegmentIndex listingContext:moreListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isDisplayingSearch)
    {
        return kSearchCellHeight;
    }
    return [indexPath isEqual:self.expandedCellIndexPath] ? SitesCellExpandedHeight : SitesCellDefaultHeight;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (!self.isDisplayingSearch)
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
    else
    {
        [self showHUDWithMode:MBProgressHUDModeDeterminate];
        
        AlfrescoNode *selectedNode = [self.searchResults objectAtIndex:indexPath.row];
        NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:selectedNode.name];
        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadDestinationPath append:NO];
        
        [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            [self.documentService retrieveContentOfDocument:(AlfrescoDocument *)selectedNode outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                if (succeeded)
                {
                    [UniversalDevice pushToDisplayDocumentPreviewControllerForAlfrescoDocument:(AlfrescoDocument *)selectedNode
                                                                                   permissions:permissions
                                                                                   contentFile:nil
                                                                              documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                       session:self.session
                                                                          navigationController:self.navigationController
                                                                                      animated:YES];
                }
                else
                {
                    // display an error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                // Update progress HUD
                self.progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
            }];
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

#pragma mark - Private Functions

- (void)loadSitesForSelectedSegment:(id)sender
{
    self.expandedCellIndexPath = nil;
    
    self.selectedListType = (SiteListTypeSelection)self.segmentedControl.selectedSegmentIndex;
    
    [self showHUD];
    [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    [self.siteService clear];
    
    if ([self shouldRefresh])
    {
        [self showHUD];
        
        self.tableViewData = nil;
        [self.tableView reloadData];
        
        [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
            /**
             * Site requests have completed which we use as a trigger to allow background requests to start being generated,
             * e.g. multiple Sync set determination requests.
             */
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSiteRequestsCompletedNotification object:nil];
        }];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        if (UserAccountTypeAIMS != [AccountManager sharedManager].selectedAccount.accountType)
        {
            [self.navigationController popToRootViewControllerAnimated:NO];
        }
    }
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

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:session];
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIButton *)accessoryButton withEvent:(UIEvent *)event
{
    AlfrescoNodeCell *selectedCell = (AlfrescoNodeCell *)accessoryButton.superview;
    NSIndexPath *indexPathToSelectedCell = nil;
    
    AlfrescoNode *selectedNode = nil;
    indexPathToSelectedCell = [self.tableView indexPathForCell:selectedCell];
    selectedNode = [self.searchResults objectAtIndex:indexPathToSelectedCell.row];
    
    [self.tableView selectRowAtIndexPath:indexPathToSelectedCell animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    [self showSearchProgressHUD];
    [self.documentService retrieveNodeWithIdentifier:selectedNode.identifier completionBlock:^(AlfrescoNode *node, NSError *error) {
        [self hideSearchProgressHUD];
        if (node)
        {
            MetaDataViewController *metadataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:node session:self.session];
            [UniversalDevice pushToDisplayViewController:metadataViewController usingNavigationController:self.navigationController animated:YES];
        }
        else
        {
            NSString *metadataRetrievalErrorMessage = [NSString stringWithFormat:NSLocalizedString(@"error.retrieving.metadata", "Metadata Retrieval Error"), selectedNode.name];
            displayErrorMessage(metadataRetrievalErrorMessage);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (void)showSearchProgressHUD
{
    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [self.tableView addSubview:self.searchProgressHUD];
    [self.searchProgressHUD showAnimated:YES];
}

- (void)hideSearchProgressHUD
{
    [self.searchProgressHUD hideAnimated:YES];
    self.searchProgressHUD = nil;
}

- (void)rotateView:(UIView *)view duration:(CGFloat)duration angle:(CGFloat)angle
{
    [UIView animateWithDuration:duration delay:0.0f options:UIViewAnimationOptionCurveEaseIn animations:^{
        view.transform = CGAffineTransformMakeRotation(angle);
    } completion:nil];
}

- (SiteListTypeSelection)selectionTypeForFilter:(SitesListViewFilter)filter
{
    SiteListTypeSelection returnSelectionType;
    
    switch (filter)
    {
        case SitesListViewFilterNoFilter:
        {
            returnSelectionType = self.selectedListType;
        }
        break;
            
        case SitesListViewFilterFavouriteSites:
        {
            returnSelectionType = SiteListTypeSelectionFavouriteSites;
        }
        break;
            
        case SitesListViewFilterMySites:
        {
            returnSelectionType = SiteListTypeSelectionMySites;
        }
        break;
            
        case SitesListViewFilterAllSites:
        {
            returnSelectionType = SiteListTypeSelectionAllSites;
        }
        break;
    }
    
    return returnSelectionType;
}

#pragma mark - UISearchBarDelegate Functions

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self showSearchProgressHUD];
    self.isDisplayingSearch = YES;
    [self.documentService retrieveNodeWithFolderPath:kSitesFolderLocation completionBlock:^(AlfrescoNode *node, NSError *error) {
        [self hideSearchProgressHUD];
        if (node)
        {
            BOOL shouldSearchContent = [[PreferenceManager sharedManager] shouldCarryOutFullSearch];
            
            AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithExactMatch:NO includeContent:shouldSearchContent folder:(AlfrescoFolder *)node includeDescendants:YES];
            [self showSearchProgressHUD];
            [self.searchService searchWithKeywords:searchBar.text options:searchOptions completionBlock:^(NSArray *array, NSError *error) {
                [self hideSearchProgressHUD];
                if (array)
                {
                    self.searchResults = array;
                    [self.tableView reloadData];
                }
                else
                {
                    // display error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.search.failed", @"Site Search failed"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            }];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.folder.failed", @"Sites Folder Error"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    self.searchResults = nil;
    self.isDisplayingSearch = NO;
    [self.tableView reloadData];
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [searchBar enableReturnKeyForPastedText:text range:range];
    
    return YES;
}

#pragma mark - UISearchControllerDelegate Methods

- (void)willPresentSearchController:(UISearchController *)searchController
{
    if (self.sitesFilter == SitesListViewFilterNoFilter)
    {
        [UIView animateWithDuration:kSearchBarSpeed animations:^{
            CGRect tableViewFrame = self.tableView.frame;
            tableViewFrame.origin.y -= kUISegmentControllerHeight;
            self.tableView.frame = tableViewFrame;
            CGRect test = searchController.searchBar.frame;
            test.origin.y += kUISegmentControllerHeight;
            searchController.searchBar.frame = test;
        }];
    }
}

- (void)didDismissSearchController:(UISearchController *)searchController
{
    if (self.sitesFilter == SitesListViewFilterNoFilter)
    {
        [UIView animateWithDuration:kSearchBarSpeed animations:^{
            CGRect tableViewFrame = self.tableView.frame;
            tableViewFrame.origin.y += kUISegmentControllerHeight;
            self.tableView.frame = tableViewFrame;
        }];
    }
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
    
    __weak SitesListViewController *weakSelf = self;
    SiteListTypeSelection siteListShowingAtSelection = self.selectedListType;
    
    if (selectedSite.isFavorite)
    {
        [self.siteService removeFavoriteSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            favoriteButton.enabled = YES;
            
            if (site)
            {
                // if the favourites are displayed, remove from the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeSelectionFavouriteSites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf removeSites:@[selectedSite] withRowAnimation:UITableViewRowAnimationTop];
                }
                else if (siteListShowingAtSelection == weakSelf.selectedListType)
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
            if (site)
            {
                // if the favourites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeSelectionFavouriteSites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf addSites:@[site] withRowAnimation:UITableViewRowAnimationFade];
                }
                else if (siteListShowingAtSelection == weakSelf.selectedListType)
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
    
    __weak SitesListViewController *weakSelf = self;
    SiteListTypeSelection siteListShowingAtSelection = self.selectedListType;
    
    if (!selectedSite.isMember && !selectedSite.isPendingMember)
    {
        [self.siteService joinSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            joinButton.enabled = YES;
            
            if (site)
            {
                // if my sites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeSelectionMySites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf addSites:@[site] withRowAnimation:UITableViewRowAnimationFade];
                }
                else if (siteListShowingAtSelection == weakSelf.selectedListType)
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
            
            if (site)
            {
                // replace the site with the updated one, if the all sites are displayed
                if (weakSelf.selectedListType == SiteListTypeSelectionAllSites)
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
            
            if (site)
            {
                // if my sites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeSelectionMySites)
                {
                    weakSelf.expandedCellIndexPath = nil;
                    [weakSelf removeSites:@[selectedSite] withRowAnimation:UITableViewRowAnimationTop];
                }
                else if (siteListShowingAtSelection == weakSelf.selectedListType)
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
    [self.navigationController pushViewController:membersVC animated:YES];
}

@end
