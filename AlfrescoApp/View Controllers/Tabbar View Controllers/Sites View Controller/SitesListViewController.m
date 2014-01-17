//
//  SitesListViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SitesListViewController.h"
#import "FileFolderListViewController.h"
#import "Utility.h"
#import "PreviewViewController.h"
#import "UniversalDevice.h"
#import "SitesCell.h"
#import "ConnectivityManager.h"
#import "LoginManager.h"
#import "FileFolderCell.h"
#import "MetaDataViewController.h"
#import "ThumbnailDownloader.h"
#import "AccountManager.h"

CGFloat kSegmentHorizontalPadding = 10.0f;
CGFloat kSegmentVerticalPadding = 10.0f;
CGFloat kSegmentControllerHeight = 40.0f;

static NSString * const kSitesFolderLocation = @"/Sites";
static NSString * const kSitesPreviousSearchThumbnailMappingsFileName = @"SitesSearchMappings";

static CGFloat kSearchCellHeight = 60.0f;

@interface SitesListViewController()

@property (nonatomic, strong) AlfrescoSiteService *siteService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UISearchDisplayController *searchController;
@property (nonatomic, strong) NSArray *searchResults;
@property (nonatomic, strong) NSIndexPath *expandedCellIndexPath;
@property (nonatomic, assign) SiteListType selectedListType;
@property (nonatomic, strong) __block NSMutableDictionary *thumbnails;
@property (nonatomic, strong) MBProgressHUD *searchProgressHUD;

@end

@implementation SitesListViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)loadView
{    
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    view.backgroundColor = [UIColor whiteColor];
    
    UISegmentedControl *segment = [[UISegmentedControl alloc] initWithItems:@[
                                   NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites"),
                                   NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites"),
                                   NSLocalizedString(@"sites.segmentControl.allsites", @"All Sites")]];
    segment.frame = CGRectMake((view.frame.origin.x + (kSegmentHorizontalPadding / 2)),
                               (view.frame.origin.y + (kSegmentVerticalPadding / 2)),
                               view.frame.size.width - kSegmentVerticalPadding,
                               kSegmentControllerHeight - kSegmentVerticalPadding);
    [segment addTarget:self action:@selector(loadSitesForSelectedSegment:) forControlEvents:UIControlEventValueChanged];
    segment.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    segment.selectedSegmentIndex = SiteListTypeFavouriteSites;
    self.selectedListType = segment.selectedSegmentIndex;
    self.segmentedControl = segment;
    [view addSubview:self.segmentedControl];
    
    // create and configure the table view
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(view.frame.origin.x,
                                                                   (view.frame.origin.y + kSegmentControllerHeight),
                                                                   view.frame.size.width,
                                                                   (view.frame.size.height - kSegmentControllerHeight))
                                                  style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    // create searchBar
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(view.frame.origin.x,
                                                                           view.frame.origin.y,
                                                                           view.frame.size.width,
                                                                           44.0f)];
    searchBar.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    searchBar.delegate = self;
    self.searchBar = searchBar;
    
    // search controller
    UISearchDisplayController *searchController = [[UISearchDisplayController alloc] initWithSearchBar:self.searchBar contentsController:self];
    searchController.searchResultsDataSource = self;
    searchController.searchResultsDelegate = self;
    searchController.delegate = self;
    self.searchController = searchController;
    
    // add the searchBar to the tableview
    self.tableView.tableHeaderView = self.searchBar;
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"sites.title", @"Sites Title");
    
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
    
    [self loadThumbnailMappings];
    
    if ([self respondsToSelector:@selector(edgesForExtendedLayout)])
    {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (tableView == self.searchController.searchResultsTableView)
    {
        return self.searchResults.count;
    }
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"SitesCell";
    static NSString *SearchCellIdentifier = @"FileFolderCell";
    
    SitesCell *siteCell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    __block FileFolderCell *searchCell = [tableView dequeueReusableCellWithIdentifier:SearchCellIdentifier];
    
    UITableViewCell *returnCell = nil;
    
    if (!siteCell)
    {
        siteCell = (SitesCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SitesCell class]) owner:self options:nil] objectAtIndex:0];
        siteCell.delegate = self;
    }
    
    if (!searchCell)
    {
        searchCell = (FileFolderCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([FileFolderCell class]) owner:self options:nil] lastObject];
    }
    
    if (tableView == self.tableView)
    {
        returnCell = siteCell;
        
        AlfrescoSite *currentSite = [self.tableViewData objectAtIndex:indexPath.row];
        siteCell.siteNameLabelView.text = currentSite.title;
        siteCell.siteImageView.image = imageForType(@"site");
        
        [siteCell updateCellStateWithSite:currentSite];
    }
    else
    {
        returnCell = searchCell;
        
        AlfrescoDocument *documentNode = [self.searchResults objectAtIndex:indexPath.row];
        searchCell.nodeNameLabel.text = documentNode.name;
        searchCell.nodeImageView.image = imageForType([documentNode.name pathExtension]);
        
        // get unique identifier of the document - last modified date will be suffixed
        NSString *uniqueIdentifier = uniqueFileNameForNode(documentNode);
        
        UIImage *thumbnailImage = [self thumbnailFromDiskForDocumentUniqueIdentifier:uniqueIdentifier];
        
        // file has been downloaded completely for this document
        if ([self.thumbnails objectForKey:uniqueIdentifier] && thumbnailImage)
        {
            searchCell.nodeImageView.image = thumbnailImage;
        }
        else if (!thumbnailImage || ![[ThumbnailDownloader sharedManager] thumbnailHasBeenRequestedForDocument:documentNode])
        {
            __weak SitesListViewController *weakSelf = self;
            
            // request the file to be downloaded, only if an existing request for this document hasn't been made.
            // set a placeholder image
            UIImage *placeholderImage = imageForType([documentNode.name pathExtension]);
            searchCell.nodeImageView.image = placeholderImage;
            
            [[ThumbnailDownloader sharedManager] retrieveImageForDocument:documentNode toFolderAtPath:[[AlfrescoFileManager sharedManager] thumbnailsDocLibFolderPath] renditionType:@"doclib" session:self.session completionBlock:^(NSString *savedFileName, NSError *error) {
                if (!error)
                {
                    [weakSelf.thumbnails setValue:savedFileName forKey:uniqueIdentifier];
                    // update the image view
                    if (searchCell.nodeImageView.image == placeholderImage)
                    {
                        [searchCell.nodeImageView setImageAtPath:savedFileName withFade:YES];
                    }
                }
            }];
        }
        
        NSString *modifiedDateString = relativeDateFromDate(documentNode.modifiedAt);
        searchCell.nodeDetailLabel.text = [NSString stringWithFormat:@"%@ • %@", modifiedDateString, stringForLongFileSize(documentNode.contentLength)];
        searchCell.accessoryView = [self makeDetailDisclosureButton];
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
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:self.tableViewData.count];
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
    CGFloat returnHeight = 0;
    if (tableView == self.searchController.searchResultsTableView)
    {
        returnHeight = kSearchCellHeight;
    }
    else
    {
        if ([indexPath isEqual:self.expandedCellIndexPath])
        {
            returnHeight = SitesCellExpandedHeight;
        }
        else
        {
            returnHeight = SitesCellDefaultHeight;
        }
    }
    
    return returnHeight;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.tableView)
    {
        self.expandedCellIndexPath = nil;
        
        AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:indexPath.row];
        
        [self showHUD];
        [self.siteService retrieveDocumentLibraryFolderForSite:selectedSite.shortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
            [self hideHUD];
            if (folder)
            {
                [self showHUD];
                [self.documentService retrievePermissionsOfNode:folder completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
                    [self hideHUD];
                    if (permissions)
                    {
                        FileFolderListViewController *browserListViewController = [[FileFolderListViewController alloc] initWithFolder:folder folderPermissions:permissions folderDisplayName:selectedSite.title session:self.session];
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
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.documentlibrary.failed", @"Doc Library Retrieval"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
    }
    else
    {
        AlfrescoNode *selectedNode = [self.searchResults objectAtIndex:indexPath.row];
        
        [self showHUD];
        
        NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:selectedNode.name];
        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadDestinationPath append:NO];
        
        [self.documentService retrievePermissionsOfNode:selectedNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            [self.documentService retrieveContentOfDocument:(AlfrescoDocument *)selectedNode outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                if (succeeded)
                {
                    PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:(AlfrescoDocument *)selectedNode documentPermissions:permissions contentFilePath:downloadDestinationPath session:self.session displayOverlayCloseButton:NO];
                    [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
                }
                else
                {
                    // display an error
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                // progress indicator update
            }];
        }];
    }
}

#pragma mark - Custom Setters

- (void)setExpandedCellIndexPath:(NSIndexPath *)expandedCellIndexPath
{
    SitesCell *siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:_expandedCellIndexPath];
    [siteCell.expandButton setImage:[UIImage imageNamed:@"grey-accessory-down.png"] forState:UIControlStateNormal];
    
    _expandedCellIndexPath = expandedCellIndexPath;
    
    siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:expandedCellIndexPath];
    if (siteCell)
    {
        [siteCell.expandButton setImage:[UIImage imageNamed:@"grey-accessory-up.png"] forState:UIControlStateNormal];
    }
    
    // Save the contentOffset (iOS 5.1 scrolling issue, see MOBILE-1621 for details)
    CGPoint contentOffset = self.tableView.contentOffset;
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    self.tableView.contentOffset = contentOffset;
    
    // If an image with a consistant shadow can be produced, then the rotation of the button can be used.
    // for more information, please refer to MOBILE-1600 ( https://issues.alfresco.com/jira/browse/MOBILE-1600 )
//    void (^rotateExpandButton)(SitesCell *siteCell, CGFloat angle) = ^(SitesCell *siteCell, CGFloat angle) {
//        [UIView animateWithDuration:0.3 animations:^{
//            siteCell.expandButton.transform = CGAffineTransformMakeRotation(angle);
//        }];
//    };
//    
//    CGFloat rotationAngle = 0.0f;
//    
//    // get previous cell and and reset the expand view
//    SitesCell *siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:_expandedCellIndexPath];
//    rotateExpandButton(siteCell, rotationAngle);
//    
//    // update the expanded cell index path
//    _expandedCellIndexPath = expandedCellIndexPath;
//    
//    rotationAngle = M_PI;
//    siteCell = (SitesCell *)[self.tableView cellForRowAtIndexPath:_expandedCellIndexPath];
//    if (siteCell)
//    {
//        rotateExpandButton(siteCell, rotationAngle);
//    }
//    
//    [self.tableView beginUpdates];
//    [self.tableView endUpdates];
}

#pragma mark - Private Functions

- (void)loadSitesForSelectedSegment:(id)sender
{
    self.expandedCellIndexPath = nil;
    
    self.selectedListType = (SiteListType)self.segmentedControl.selectedSegmentIndex;
    
    [self showHUD];
    [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        [self reloadTableViewWithPagingResult:pagingResult error:error];
        [self hidePullToRefreshView];
    }];
}

- (void)loadSitesForSiteType:(SiteListType)siteType
              listingContext:(AlfrescoListingContext *)listingContext
         withCompletionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        switch (siteType)
        {
            case SiteListTypeMySites:
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
                
            case SiteListTypeFavouriteSites:
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
                
            case SiteListTypeAllSites:
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
        [self loadSitesForSiteType:self.selectedListType listingContext:self.defaultListingContext withCompletionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
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
    FileFolderCell *selectedCell = (FileFolderCell *)accessoryButton.superview;
    NSIndexPath *indexPathToSelectedCell = nil;
    
    AlfrescoNode *selectedNode = nil;
    indexPathToSelectedCell = [self.searchController.searchResultsTableView indexPathForCell:selectedCell];
    selectedNode = [self.searchResults objectAtIndex:indexPathToSelectedCell.row];
    
    [self.searchController.searchResultsTableView selectRowAtIndexPath:indexPathToSelectedCell animated:YES scrollPosition:UITableViewScrollPositionNone];
    
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

- (UIImage *)thumbnailFromDiskForDocumentUniqueIdentifier:(NSString *)uniqueIdentifier
{
    UIImage *returnImage = nil;
    
    NSString *savedFileName = [self.thumbnails objectForKey:uniqueIdentifier];
    if (savedFileName)
    {
        NSString *filePathToFile = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:savedFileName];
        NSURL *fileURL = [NSURL fileURLWithPath:filePathToFile];
        NSData *imageData = [[AlfrescoFileManager sharedManager] dataWithContentsOfURL:fileURL];
        
        returnImage = [UIImage imageWithData:imageData];
    }
    return returnImage;
}

- (void)saveThumbnailMapping
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *mappingsFolderPath = [fileManager thumbnailsMappingFolderPath];
    
    if (![fileManager fileExistsAtPath:mappingsFolderPath])
    {
        NSError *folderCreationError = nil;
        [fileManager createDirectoryAtPath:mappingsFolderPath withIntermediateDirectories:YES attributes:nil error:&folderCreationError];
        
        if (folderCreationError)
        {
            AlfrescoLogError([folderCreationError localizedDescription]);
        }
    }
    
    NSError *dictionarySavingError = nil;
    NSString *completeFilePath = [mappingsFolderPath stringByAppendingPathComponent:kSitesPreviousSearchThumbnailMappingsFileName];
    NSData *thumbnailDictionaryData = [NSKeyedArchiver archivedDataWithRootObject:self.thumbnails];
    
    [fileManager createFileAtPath:completeFilePath contents:thumbnailDictionaryData error:&dictionarySavingError];
    
    if (dictionarySavingError)
    {
        AlfrescoLogError([dictionarySavingError localizedDescription]);
    }
}

- (void)loadThumbnailMappings
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    NSString *mappingsFolderPath = [fileManager thumbnailsMappingFolderPath];
    NSURL *completeFilePathURL = [NSURL fileURLWithPath:[mappingsFolderPath stringByAppendingPathComponent:kSitesPreviousSearchThumbnailMappingsFileName]];
    NSData *thumbnailDictionaryData = [fileManager dataWithContentsOfURL:completeFilePathURL];
    
    if (thumbnailDictionaryData)
    {
        self.thumbnails = (NSMutableDictionary *)[NSKeyedUnarchiver unarchiveObjectWithData:thumbnailDictionaryData];
    }
    else
    {
        self.thumbnails = [NSMutableDictionary dictionary];
    }
}

- (void)showSearchProgressHUD
{
    self.searchProgressHUD = [[MBProgressHUD alloc] initWithView:self.searchController.searchResultsTableView];
    [self.searchController.searchResultsTableView addSubview:self.searchProgressHUD];
    [self.searchProgressHUD show:YES];
}

- (void)hideSearchProgressHUD
{
    [self.searchProgressHUD hide:YES];
    self.searchProgressHUD = nil;
}

#pragma mark - UISearchBarDelegate Functions

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [self showSearchProgressHUD];
    [self.documentService retrieveNodeWithFolderPath:kSitesFolderLocation completionBlock:^(AlfrescoNode *node, NSError *error) {
        [self hideSearchProgressHUD];
        if (node)
        {
            AlfrescoKeywordSearchOptions *searchOptions = [[AlfrescoKeywordSearchOptions alloc] initWithFolder:(AlfrescoFolder *)node includeDescendants:YES];
            [self showSearchProgressHUD];
            [self.searchService searchWithKeywords:searchBar.text options:searchOptions completionBlock:^(NSArray *array, NSError *error) {
                [self hideSearchProgressHUD];
                if (array)
                {
                    self.searchResults = array;
                    [self.searchController.searchResultsTableView reloadData];
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
}

#pragma mark - UISearchDisplayDelegate Functions

- (void)searchDisplayControllerWillBeginSearch:(UISearchDisplayController *)controller;
{
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.origin.y -= kSegmentControllerHeight;
    self.tableView.frame = tableViewFrame;
}

- (void)searchDisplayControllerWillEndSearch:(UISearchDisplayController *)controller;
{
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.origin.y += kSegmentControllerHeight;
    self.tableView.frame = tableViewFrame;
    [self saveThumbnailMapping];
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
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
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
    SiteListType siteListShowingAtSelection = self.selectedListType;
    
    if (selectedSite.isFavorite)
    {
        [self.siteService removeFavoriteSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            favoriteButton.enabled = YES;
            
            if (site)
            {
                // if the favourites are displayed, remove from the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeFavouriteSites)
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
                if (weakSelf.selectedListType == SiteListTypeFavouriteSites)
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
    SiteListType siteListShowingAtSelection = self.selectedListType;
    
    if (!selectedSite.isMember && !selectedSite.isPendingMember)
    {
        [self.siteService joinSite:selectedSite completionBlock:^(AlfrescoSite *site, NSError *error) {
            joinButton.enabled = YES;
            
            if (site)
            {
                // if my sites are displayed, add the cell to the table view, otherwise replace the site with the updated one
                if (weakSelf.selectedListType == SiteListTypeMySites)
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
                if (weakSelf.selectedListType == SiteListTypeAllSites)
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
                if (weakSelf.selectedListType == SiteListTypeMySites)
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

@end
