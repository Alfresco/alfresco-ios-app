//
//  VersionHistoryViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "VersionHistoryViewController.h"
#import "AlfrescoDocument.h"
#import "AlfrescoVersionService.h"
#import "Utility.h"
#import "VersionHistoryCell.h"
#import "MetaDataViewController.h"
#import "DownloadManager.h"

static CGFloat kCellHeight = 100.0f;
static CGFloat kStandardCellHeight = 44.0f;
static NSInteger kDownloadLatestVersionSection = 1;
static NSInteger kDownloadLatestVersionSectionRowCount = 1;

@interface VersionHistoryViewController ()

@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) AlfrescoVersionService *versionService;

@end

@implementation VersionHistoryViewController

- (id)initWithDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.document = document;
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // create and configure the table view
    self.tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self disablePullToRefresh];
    
    self.title = NSLocalizedString(@"version.history.title", @"Version History Title");
    
    [self showHUD];
    [self loadVersionsForDocument:self.document listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        if (pagingResult)
        {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.version.history.unable.to.retrieve", @"Version Retrieve Error"), [ErrorDescriptions descriptionForError:error]]);
        }
    }];
}

#pragma mark - Private Functions

- (void)loadVersionsForDocument:(AlfrescoDocument *)document listingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    [self.versionService retrieveAllVersionsOfDocument:document listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
        }
    }];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.versionService = [[AlfrescoVersionService alloc] initWithSession:session];
}

- (UIButton *)makeDetailDisclosureButton
{
    UIButton *button = [UIButton buttonWithType:UIButtonTypeInfoDark];
    [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)accessoryButtonTapped:(UIButton *)accessoryButton withEvent:(UIEvent *)event
{
    VersionHistoryCell *selectedCell = (VersionHistoryCell *)accessoryButton.superview;
    NSIndexPath *indexPathToSelectedCell = [self.tableView indexPathForCell:selectedCell];
    
    AlfrescoDocument *selectedDocument = [self.tableViewData objectAtIndex:indexPathToSelectedCell.row];
    
    MetaDataViewController *metadataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:selectedDocument showingVersionHistoryOption:NO session:self.session];
    [self.navigationController pushViewController:metadataViewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (section == kDownloadLatestVersionSection) ? kDownloadLatestVersionSectionRowCount : self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section > 0)
    {
        return kStandardCellHeight;
    }
    return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *VersionHistoryCellIdentifier = @"VersionHistoryCell";
    static NSString *DownloadLastestCellIdentifier = @"DownloadLatestVersionCell";
    VersionHistoryCell *versionHistoryCell = [tableView dequeueReusableCellWithIdentifier:VersionHistoryCellIdentifier];
    UITableViewCell *downloadLatestVersionCell = [tableView dequeueReusableCellWithIdentifier:DownloadLastestCellIdentifier];
    
    // cell to return
    UITableViewCell *returnCell = nil;
    
    if (!versionHistoryCell)
    {
        versionHistoryCell = (VersionHistoryCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([VersionHistoryCell class]) owner:self options:nil] lastObject];
    }
    
    if (!downloadLatestVersionCell)
    {
        downloadLatestVersionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:DownloadLastestCellIdentifier];
    }
    
    // config the cell here...
    
    if (indexPath.section == 0)
    {
        returnCell = versionHistoryCell;
        
        AlfrescoDocument *currentDocument = [self.tableViewData objectAtIndex:indexPath.row];
        
        versionHistoryCell.versionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version.history.version.cell.text", @"Version Text"), currentDocument.versionLabel];
        NSString *lastModifiedString = relativeDateFromDate(currentDocument.modifiedAt);
        versionHistoryCell.lastModifiedLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version.history.last.modified.cell.text", @"Last Modified Text"), lastModifiedString];
        versionHistoryCell.lastModifiedByLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version.history.last.modified.by.cell.text", @"Last Modified By Text"), currentDocument.modifiedBy];
        versionHistoryCell.commentLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version.history.comment.cell.text", @"Comment Text"), (currentDocument.versionComment) ? currentDocument.versionComment : @""];
        NSString *currentVersionString = (currentDocument.isLatestVersion) ? NSLocalizedString(@"Yes", @"Yes") : NSLocalizedString(@"No", @"No") ;
        versionHistoryCell.currentVersionLabel.text = [NSString stringWithFormat:NSLocalizedString(@"version.history.current.version.cell.text", @"Current Version Text"), currentVersionString];
        
        // disclosure button
        versionHistoryCell.accessoryType = UITableViewCellAccessoryNone;
        versionHistoryCell.accessoryView = [self makeDetailDisclosureButton];
    }
    else
    {
        returnCell = downloadLatestVersionCell;
        downloadLatestVersionCell.textLabel.text = NSLocalizedString(@"version.history.download.latest.text", @"Download Latest Version Text");
        downloadLatestVersionCell.textLabel.textAlignment = NSTextAlignmentCenter;
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
            
            [self loadVersionsForDocument:self.document listingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                if (pagingResult)
                {
                    [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                }
                else
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.version.history.unable.to.retrieve", @"Version Retrieve Error"), [ErrorDescriptions descriptionForError:error]]);
                }
                
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == kDownloadLatestVersionSection && self.tableViewData.count > 0)
    {
        // latest version will always be returned first
        AlfrescoDocument *latestVersionDocument = [self.tableViewData objectAtIndex:0];
        // double check that this is the latest version
        if (latestVersionDocument.isLatestVersion)
        {
            NSString *downloadPath = [[[DownloadManager sharedManager] downloadedDocumentsContentDirectory] stringByAppendingPathComponent:latestVersionDocument.name];
            [[DownloadManager sharedManager] downloadDocument:latestVersionDocument contentPath:downloadPath session:self.session];
        }
        else
        {
            displayErrorMessage(NSLocalizedString(@"error.version.history.no.latest.version", @"Latest Version Not Found"));
        }
    }
}

@end
