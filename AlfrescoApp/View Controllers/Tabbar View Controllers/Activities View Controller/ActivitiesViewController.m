//
//  ActivitiesViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ActivitiesViewController.h"
#import "ActivitiesTableViewCellController.h"
#import "PreviewViewController.h"
#import "MetaDataViewController.h"
#import "UniversalDevice.h"
#import "Utility.h"
#import "LoginManager.h"

NSString * const kActivityTableSectionToday = @"activities.section.today";
NSString * const kActivityTableSectionYesterday = @"activities.section.yesterday";
NSString * const kActivityTableSectionOlder = @"activities.section.older";

@interface ActivitiesViewController ()

@property (nonatomic, strong) AlfrescoActivityStreamService *activityService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) NSMutableArray *tableSectionHeaders;

@end

@implementation ActivitiesViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    
    if (self)
    {
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if (self.session)
    {
        [self loadActivities];
    }
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
    
    [self.tableView setAllowsSelection:NO];
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
    if (self.tableSectionHeaders)
    {
        return [self.tableViewData [indexPath.section][indexPath.row] heightForCellAtIndexPath:indexPath inTableView:tableView];
    }
    else
    {
        return [self.tableViewData [indexPath.row] heightForCellAtIndexPath:indexPath inTableView:tableView];
    }
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
    
    if (activityController.isActivityTypeDocument && activity.data[kActivityNodeRef] != nil)
    {
        [self showHUD];
        if (activityController.activityDocument)
        {
            [self displayDocument:activityController.activityDocument forActivityController:activityController];
        }
        else
        {
            [self.documentService retrieveNodeWithIdentifier:activity.data[kActivityNodeRef] completionBlock:^(AlfrescoNode *node, NSError *error) {
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.alfresco.node.notfound", @"node not found"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                    [self hideHUD];
                }
                else
                {
                    AlfrescoDocument *document = (AlfrescoDocument *)node;
                    activityController.activityDocument = document;
                    
                    [self displayDocument:document forActivityController:activityController];
                }
            }];
        }
    }
}

- (void)displayDocument:(AlfrescoDocument *)document forActivityController:(ActivitiesTableViewCellController *)activityController
{
    if (document)
    {
        NSString *downloadDestinationPath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:document.name];
        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadDestinationPath append:NO];
        
        [self.documentService retrievePermissionsOfNode:document completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
            [self.documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                [self hideHUD];
                if (succeeded)
                {
                    PreviewViewController *previewController = [[PreviewViewController alloc] initWithDocument:document documentPermissions:permissions contentFilePath:downloadDestinationPath session:self.session];
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
    else
    {
        [self hideHUD];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    [self.tableView selectRowAtIndexPath:indexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    
    ActivitiesTableViewCellController *activityController = self.tableViewData[indexPath.section][indexPath.row];
    AlfrescoActivityEntry *activity = activityController.activity;
    
    if (activityController.activityDocument)
    {
        MetaDataViewController *metaDataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:activityController.activityDocument showingVersionHistoryOption:YES session:self.session];
        [UniversalDevice pushToDisplayViewController:metaDataViewController usingNavigationController:self.navigationController animated:YES];
    }
    else
    {
        if (activityController.isActivityTypeDocument && activity.data[kActivityNodeRef] != nil)
        {
            [self.documentService retrieveNodeWithIdentifier:activity.data[kActivityNodeRef] completionBlock:^(AlfrescoNode *node, NSError *error) {
                
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.alfresco.node.notfound", @"node not found"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                    [self hideHUD];
                }
                else
                {
                    AlfrescoDocument *document = (AlfrescoDocument *)node;
                    activityController.activityDocument = document;
                    
                    MetaDataViewController *metaDataViewController = [[MetaDataViewController alloc] initWithAlfrescoNode:activityController.activityDocument showingVersionHistoryOption:YES session:self.session];
                    [UniversalDevice pushToDisplayViewController:metaDataViewController usingNavigationController:self.navigationController animated:YES];
                }
            }];
        }
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
        [self.tableSectionHeaders removeAllObjects];
        [self.tableView reloadData];
        if (error || [pagingResult.objects count] == 0)
        {
            [self constructErrorCellWithError:nil];
            
            if (error)
            {
                [Notifier notifyWithAlfrescoError:error];
            }
        }
        else
        {
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

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView*)view
{
    if (self.session)
    {
        [self loadActivities];
    }
    else
    {
        [self hidePullToRefreshView];
        [[LoginManager sharedManager] attemptLogin];
    }
}

@end
