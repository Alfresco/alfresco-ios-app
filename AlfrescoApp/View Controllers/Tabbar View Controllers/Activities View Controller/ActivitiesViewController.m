//
//  ActivitiesViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivitiesViewController.h"
#import "ActivitiesTableViewCellController.h"
#import "ActivityTableViewCell.h"
#import "DocumentPreviewViewController.h"
#import "FolderPreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "Utility.h"
#import "LoginManager.h"
#import "AccountManager.h"

NSString * const kActivityTableSectionToday = @"activities.section.today";
NSString * const kActivityTableSectionYesterday = @"activities.section.yesterday";
NSString * const kActivityTableSectionOlder = @"activities.section.older";
static NSString * const kActivitiesInterface = @"ActivityViewController";

@interface ActivitiesViewController ()

@property (nonatomic, strong) AlfrescoActivityStreamService *activityService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSMutableArray *tableSectionHeaders;

@end

@implementation ActivitiesViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:kActivitiesInterface andSession:session];
    
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"activities.title", @"Activities Title");
    
    if (self.session)
    {
        [self loadActivities];
    }
    
    UINib *cellNib = [UINib nibWithNibName:@"ActivityTableViewCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kActivityCellIdentifier];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self selectIndexPathForAlfrescoNodeInDetailView];
}

- (NSMutableArray *)constructTableGroups:(AlfrescoPagingResult *)pagingResult
{
    NSMutableArray *tableSections = (self.tableViewData) ? self.tableViewData : [[NSMutableArray alloc] init];
    
    if (!self.tableSectionHeaders)
    {
        self.tableSectionHeaders = [[NSMutableArray alloc] init];
    }
    
    for (AlfrescoActivityEntry *activity in pagingResult.objects)
    {
        ActivitiesTableViewCellController *activityController = [[ActivitiesTableViewCellController alloc] initWithSession:self.session];
        activityController.activity = activity;
        activityController.tableView = self.tableView;
        
        NSString *sectionHeader = [self groupHeaderForActivity:activity];
        
        if (![self.tableSectionHeaders containsObject:sectionHeader])
        {
            NSMutableArray *tableSection = [[NSMutableArray alloc] init];
            [self.tableSectionHeaders addObject:sectionHeader];
            [tableSection addObject:activityController];
            [tableSections addObject:tableSection];
        }
        else
        {
            NSInteger index = [self.tableSectionHeaders indexOfObject:sectionHeader];
            [tableSections[index] addObject:activityController];
        }
    }
    
    return tableSections;
}

- (void)constructErrorCellWithError:(NSError *)error
{
    ActivitiesTableViewCellController *activityController = [[ActivitiesTableViewCellController alloc] init];
    
    [self.tableViewData removeAllObjects];
    [self.tableSectionHeaders removeAllObjects];
    
    [self.tableViewData addObject:activityController];
    [self.tableView reloadData];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.tableViewData count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(self.tableSectionHeaders[section], @"section header");
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (self.tableSectionHeaders)
    {
        return [self.tableViewData[section] count];
    }
    else
    {
        return self.tableViewData.count;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivitiesTableViewCellController *cellController = self.tableSectionHeaders ? self.tableViewData[indexPath.section][indexPath.row] : self.tableViewData [indexPath.row];
    return [cellController heightForCellAtIndexPath:indexPath inTableView:tableView withSections:self.tableSectionHeaders];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivitiesTableViewCellController *activityController = nil;
    
    if (self.tableSectionHeaders)
    {
        activityController = self.tableViewData[indexPath.section][indexPath.row];
        return [activityController createActivityTableViewCellInTableView:self.tableView];
    }
    else
    {
        activityController = self.tableViewData[indexPath.row];
        return [activityController createActivityErrorTableViewCellInTableView:self.tableView];
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.tableSectionHeaders)
    {
        // the last row index of the table data
        NSUInteger lastSiteRowIndex = [[self.tableViewData lastObject] count] - 1;
        
        // if the last cell is about to be drawn, check if there are more sites
        if (indexPath.row == lastSiteRowIndex)
        {
            int totalTableViewItemsCount = 0;
            for (id sect in self.tableViewData)
            {
                totalTableViewItemsCount += [sect count];
            }
            
            AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:totalTableViewItemsCount];
            if (self.moreItemsAvailable)
            {
                // show more items are loading ...
                UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
                [spinner startAnimating];
                self.tableView.tableFooterView = spinner;
                
                [self.activityService retrieveActivityStreamWithListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    NSMutableArray *temp = [self constructTableGroups:pagingResult];
                    [self addMoreToTableViewWithPagingResult:pagingResult data:temp error:error];
                    self.tableView.tableFooterView = nil;
                    
                    [self selectIndexPathForAlfrescoNodeInDetailView];
                }];
            }
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ActivitiesTableViewCellController *activityController = self.tableViewData[indexPath.section][indexPath.row];
    AlfrescoActivityEntry *activity = activityController.activity;
    
    BOOL isFileOrFolder = (activityController.isActivityTypeDocument || activityController.isActivityTypeFolder);
    BOOL nodeRefExists = (activity.data[kActivityNodeRef] != nil) || (activity.data[kActivityObjectId] != nil);
    
    if (isFileOrFolder && nodeRefExists)
    {
        [self showHUD];
        if (activityController.activityNode)
        {
            [self displayDocument:activityController.activityNode forActivityController:activityController];
        }
        else
        {
            NSString *nodeIdentifier = activity.data[kActivityNodeRef] ? activity.data[kActivityNodeRef] : activity.data[kActivityObjectId];
            [self.documentService retrieveNodeWithIdentifier:nodeIdentifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.alfresco.node.notfound", @"node not found"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                    [self hideHUD];
                }
                else
                {
                    activityController.activityNode = node;
                    [self displayDocument:node forActivityController:activityController];
                }
            }];
        }
    }
}

- (void)displayDocument:(AlfrescoNode *)node forActivityController:(ActivitiesTableViewCellController *)activityController
{
    if (node)
    {
        [self.documentService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            
            [self hideHUD];
            if (!error)
            {
                if (node.isDocument)
                {
                    DocumentPreviewViewController *previewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:(AlfrescoDocument *)node
                                                                                                                           permissions:permissions
                                                                                                                       contentFilePath:nil
                                                                                                                      documentLocation:InAppDocumentLocationFilesAndFolders
                                                                                                                               session:self.session];
                    previewController.hidesBottomBarWhenPushed = YES;
                    [UniversalDevice pushToDisplayViewController:previewController usingNavigationController:self.navigationController animated:YES];
                }
                else
                {
                    FolderPreviewViewController *folderPreviewController = [[FolderPreviewViewController alloc] initWithAlfrescoFolder:(AlfrescoFolder *)node permissions:permissions session:self.session];
                    [UniversalDevice pushToDisplayViewController:folderPreviewController usingNavigationController:self.navigationController animated:YES];
                }
            }
            else
            {
                // display an error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [self hideHUD];
    }
}

- (NSString *)groupHeaderForActivity:(AlfrescoActivityEntry *)activityEntry
{
    NSCalendar *cal = [NSCalendar currentCalendar];
    
    NSDateComponents *postDateComponents = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:activityEntry.createdAt];
    NSDateComponents *todayComponents = [cal components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    NSDate *today = [cal dateFromComponents:todayComponents];
    NSDate *postDateDay = [cal dateFromComponents:postDateComponents];
    
    NSTimeInterval interval = [today timeIntervalSinceDate:postDateDay];
    
    if (interval == 0)
    {
        return kActivityTableSectionToday;
    }
    else if (interval ==  60*60*24)
    {
        return kActivityTableSectionYesterday;
    }
    else
    {
        return kActivityTableSectionOlder;
    }
}

#pragma mark - Private Functions

- (void)loadActivities
{
    [self showHUD];
    [self.activityService retrieveActivityStreamWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self.tableViewData removeAllObjects];
        self.tableSectionHeaders = nil;
        [self.tableView reloadData];
        if (error || [pagingResult.objects count] == 0)
        {
            [self constructErrorCellWithError:nil];
            [self.tableView setAllowsSelection:NO];
            
            if (error)
            {
                [Notifier notifyWithAlfrescoError:error];
            }
        }
        else
        {
            [self.tableView setAllowsSelection:YES];
            NSMutableArray *tableGroupsArray = [self constructTableGroups:pagingResult];
            [self reloadTableViewWithPagingResult:pagingResult data:tableGroupsArray error:error];
        }
        [self hidePullToRefreshView];
        [self hideHUD];
        
        // introduce delay for tableview to settle before cell is selected
        [self performSelector:@selector(selectIndexPathForAlfrescoNodeInDetailView) withObject:nil afterDelay:0.2];
    }];
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.activityService = [[AlfrescoActivityStreamService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    if ([self shouldRefresh])
    {
        [self loadActivities];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)selectIndexPathForAlfrescoNodeInDetailView
{
    NSIndexPath *indexPath = nil;
    
    for (NSArray *sections in self.tableViewData)
    {
        if (self.tableSectionHeaders.count > 0)
        {
            for (ActivitiesTableViewCellController *activityController in sections)
            {
                if (activityController.isActivityTypeDocument && activityController.activity.data[kActivityNodeRef] != nil)
                {
                    if ([[UniversalDevice detailViewItemIdentifier] hasPrefix:activityController.activity.data[kActivityNodeRef]])
                    {
                        indexPath = [NSIndexPath indexPathForRow:[sections indexOfObject:activityController] inSection:[self.tableViewData indexOfObject:sections]];
                        [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
                        return;
                    }
                }
            }
        }
    }
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadActivities];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
    }
}

@end
