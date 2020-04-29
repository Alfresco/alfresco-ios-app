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

#import "FilteredTaskViewController.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "TasksCell.h"
#import "TaskGroupItem.h"
#import "TaskDetailsViewController.h"
#import "UniversalDevice.h"
#import "TaskTypeViewController.h"

static NSString * const kDateFormat = @"dd MMMM yyyy";
static NSString * const kActivitiReview = @"activitiReview";
static NSString * const kActivitiParallelReview = @"activitiParallelReview";
static NSString * const kActivitiToDo = @"activitiAdhoc";
static NSString * const kActivitiInviteNominated = @"activitiInvitationNominated";
static NSString * const kJBPMReview = @"wf:review";
static NSString * const kJBPMParallelReview = @"wf:parallelreview";
static NSString * const kJBPMToDo = @"wf:adhoc";
static NSString * const kJBPMInviteNominated = @"wf:invitationNominated";
static NSString * const kSupportedTasksPredicateFormat = @"processDefinitionIdentifier CONTAINS %@ AND NOT (processDefinitionIdentifier CONTAINS[c] 'pooled')";
static NSString * const kAdhocProcessTypePredicateFormat = @"SELF CONTAINS[cd] %@";

static NSString * const kTaskCellIdentifier = @"FilteredTaskCell";

@interface FilteredTaskViewController ()

@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSPredicate *supportedTasksPredicate;
@property (nonatomic, strong) NSPredicate *adhocProcessTypePredicate;
@property (nonatomic, strong) NSPredicate *inviteProcessTypePredicate;
@property (nonatomic, strong) TaskViewFilter *activeTaskFilter;
@property (nonatomic, strong) TaskGroupItem *tasksGroupItem;
@property (nonatomic, weak) UIBarButtonItem *filterButton;

@end

@implementation FilteredTaskViewController

- (id)initWithFilter:(TaskViewFilter *)filter listingContext:(AlfrescoListingContext *)listingContext session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.activeTaskFilter = filter;
        
        if (listingContext)
        {
            self.defaultListingContext = listingContext;
        }
    }
    return self;
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass(self.class) andSession:session];
    if (self)
    {
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:kDateFormat];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskListDidChange:) name:kAlfrescoWorkflowTaskListDidChangeNotification object:nil];
        [self createWorkflowServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"tasks.title", @"Tasks Title");
    self.tableView.emptyMessage = NSLocalizedString(@"ui.refreshcontrol.refreshing", @"Loading...");
    
    UIBarButtonItem *addTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTask:)];
    self.navigationItem.rightBarButtonItem = addTaskButton;
    
    UINib *cellNib = [UINib nibWithNibName:@"TasksCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kTaskCellIdentifier];
    
    if (self.session)
    {
        [self showHUD];
        [self loadTasksWithListingContext:self.defaultListingContext forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            self.tableView.emptyMessage = NSLocalizedString(@"tasks.empty", @"No Tasks");
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)createTask:(id)sender
{
    TaskTypeViewController *taskTypeController = [[TaskTypeViewController alloc] initWithSession:self.session];
    UINavigationController *newTaskNavigationController = [[UINavigationController alloc] initWithRootViewController:taskTypeController];
    newTaskNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:newTaskNavigationController animated:YES completion:nil];
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    if (self.session)
    {
        [self createWorkflowServicesWithSession:session];
        [self.tasksGroupItem clearAllTasks];
        
        if ([self shouldRefresh])
        {
            [self loadTasksWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self hideHUD];
                [self hidePullToRefreshView];
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }];
        }
    }
}

- (void)taskListDidChange:(NSNotification *)notification
{
    [self reloadDataForAllTaskFilters];
}

- (void)reloadDataForAllTaskFilters
{
}

- (void)createWorkflowServicesWithSession:(id<AlfrescoSession>)session
{
    self.workflowService = [[AlfrescoWorkflowService alloc] initWithSession:session];
    
    if (!self.supportedTasksPredicate)
    {
        NSArray *supportedProcessIdentifiers = @[kActivitiReview, kActivitiParallelReview, kActivitiInviteNominated, kActivitiToDo, kJBPMReview, kJBPMParallelReview, kJBPMToDo, kJBPMInviteNominated];
        NSMutableArray *tasksSubpredicates = [[NSMutableArray alloc] init];
        [supportedProcessIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [tasksSubpredicates addObject:[NSPredicate predicateWithFormat:kSupportedTasksPredicateFormat, obj]];
        }];
        
        self.supportedTasksPredicate = [NSCompoundPredicate orPredicateWithSubpredicates:tasksSubpredicates];
    }
    
    if (!self.adhocProcessTypePredicate)
    {
        NSArray *supportedProcessIdentifiers = @[kActivitiToDo, kJBPMToDo];
        NSMutableArray *tasksSubpredicates = [[NSMutableArray alloc] init];
        [supportedProcessIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [tasksSubpredicates addObject:[NSPredicate predicateWithFormat:kAdhocProcessTypePredicateFormat, obj]];
        }];
        
        self.adhocProcessTypePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:tasksSubpredicates];
    }
    
    if (!self.inviteProcessTypePredicate)
    {
        NSArray *supportedProcessIdentifiers = @[kActivitiInviteNominated, kJBPMInviteNominated];
        NSMutableArray *tasksSubpredicates = [[NSMutableArray alloc] init];
        [supportedProcessIdentifiers enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            [tasksSubpredicates addObject:[NSPredicate predicateWithFormat:kAdhocProcessTypePredicateFormat, obj]];
        }];
        
        self.inviteProcessTypePredicate = [NSCompoundPredicate orPredicateWithSubpredicates:tasksSubpredicates];
    }
    
    self.tasksGroupItem = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title", @"Tasks") filteringPredicate:self.supportedTasksPredicate];
}

- (void)loadTasksWithListingContext:(AlfrescoListingContext *)listingContext forceRefresh:(BOOL)forceRefresh completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    if (forceRefresh)
    {
        listingContext = nil;
        [self.tasksGroupItem clearAllTasks];
    }
    
    if (listingContext == nil)
    {
        listingContext = self.defaultListingContext;
        listingContext.listingFilter = [self.activeTaskFilter listingFilter];
    }

    [self.workflowService retrieveTasksWithListingContext:listingContext completionBlock:completionBlock];
}

#pragma mark - Overridden Functions

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        [self.tasksGroupItem clearAllTasks];
        [self addMoreToTableViewWithPagingResult:pagingResult error:error];
    }
}

- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        [self.tasksGroupItem addAndApplyFilteringToTasks:pagingResult.objects];
        
        //There're some cases in older versions of Alfresco when the server sends an incorrect hasMoreItems value. In order to prevent an infinite loop of fetching new pages, we test if the current pagingResults contains any objects. See https://issues.alfresco.com/jira/browse/MNT-13567
        self.tasksGroupItem.hasMoreItems = pagingResult.hasMoreItems && pagingResult.objects.count;
        self.tableViewData = [self.tasksGroupItem.tasksAfterFiltering mutableCopy];
        
        [self.tableView reloadData];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TasksCell *cell = [tableView dequeueReusableCellWithIdentifier:kTaskCellIdentifier];
    
    AlfrescoWorkflowTask *currentTask = [self.tableViewData objectAtIndex:indexPath.row];
    cell.title = currentTask.summary;
    cell.dueDate = currentTask.dueAt;
    cell.priority = currentTask.priority;
    cell.processType = currentTask.name;
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSUInteger lastRowIndex = self.tasksGroupItem.numberOfTasksAfterFiltering - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastRowIndex)
    {
        int maxItems = self.defaultListingContext.maxItems;
        int skipCount = self.defaultListingContext.skipCount + (int)[self.tasksGroupItem numberOfTasksBeforeFiltering];
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:maxItems skipCount:skipCount];
        moreListingContext.listingFilter = self.activeTaskFilter.listingFilter;
        
        if ([self.tasksGroupItem hasMoreItems])
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            [self loadTasksWithListingContext:moreListingContext forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoWorkflowTask *selectedTask = [self.tableViewData objectAtIndex:indexPath.row];
    TaskDetailsViewController *taskDetailsViewController = [[TaskDetailsViewController alloc] initWithTask:selectedTask session:self.session];
    [UniversalDevice pushToDisplayViewController:taskDetailsViewController usingNavigationController:self.navigationController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TasksCell *cell = (TasksCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    [cell layoutIfNeeded];
    // "4.0f" hack value to resolve an issue between UILabel sizing and auto-layout
    return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height + 4.0f;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadTasksWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
            [self hidePullToRefreshView];
        }];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (successful)
            {
                [self loadTasksWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self reloadTableViewWithPagingResult:pagingResult error:error];
                }];
            }
        }];
    }
}

@end
