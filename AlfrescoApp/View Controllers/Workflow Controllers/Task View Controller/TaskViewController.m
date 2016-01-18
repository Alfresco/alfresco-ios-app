/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "TaskViewController.h"
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
static NSString * const kInitiatorWorkflowsPredicateFormat = @"initiatorUsername like %@";

static NSString * const kTaskCellIdentifier = @"TaskCell";

@interface TaskViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, strong) NSPredicate *supportedTasksPredicate;
@property (nonatomic, strong) NSPredicate *adhocProcessTypePredicate;
@property (nonatomic, strong) NSPredicate *inviteProcessTypePredicate;
@property (nonatomic, assign, getter=isDisplayingMyTasks) BOOL displayingMyTasks;
@property (nonatomic, strong) TaskGroupItem *myTasks;
@property (nonatomic, strong) TaskGroupItem *tasksIStarted;
@property (nonatomic, weak) UIBarButtonItem *filterButton;

@end

@implementation TaskViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:NSStringFromClass(self.class) andSession:session];
    if (self)
    {
        self.displayingMyTasks = YES;
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
    self.tableView.emptyMessage = NSLocalizedString(@"tasks.empty", @"No Tasks");
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"tasks.view.button", @"View") style:UIBarButtonItemStylePlain target:self action:@selector(displayTaskFilter:event:)];
    self.filterButton = filterButton;
    
    UIBarButtonItem *addTaskButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createTask:)];

    if (IS_IPAD)
    {
        self.navigationItem.rightBarButtonItem = addTaskButton;
        self.navigationItem.leftBarButtonItem = filterButton;
    }
    else
    {
        self.navigationItem.rightBarButtonItems = @[filterButton, addTaskButton];
    }

    UINib *cellNib = [UINib nibWithNibName:@"TasksCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kTaskCellIdentifier];
    
    if (self.session)
    {
        [self showHUD];
        [self loadDataWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
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
        [self.myTasks clearAllTasks];
        [self.tasksIStarted clearAllTasks];
        
        if ([self shouldRefresh])
        {
            self.displayingMyTasks = YES;
            
            [self loadDataWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
    // reload tasks and workflows following completion
    __weak typeof(self) weakSelf = self;

    [self showHUD];
    [self loadTasksWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [weakSelf hideHUD];
        if (pagingResult)
        {
            [weakSelf.myTasks clearAllTasks];
            [weakSelf.myTasks addAndApplyFilteringToTasks:pagingResult.objects];
            
            // currently being displayed, refresh the tableview.
            if (weakSelf.isDisplayingMyTasks)
            {
                weakSelf.tableViewData = [weakSelf.myTasks.tasksAfterFiltering mutableCopy];
                [weakSelf.tableView reloadData];
            }
        }
    }];
    
    [self loadWorkflowProcessesWithListingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [weakSelf hideHUD];
        if (pagingResult)
        {
            [weakSelf.tasksIStarted clearAllTasks];
            [weakSelf.tasksIStarted addAndApplyFilteringToTasks:pagingResult.objects];
            
            // currently being displayed, refresh the tableview.
            if (!weakSelf.isDisplayingMyTasks)
            {
                weakSelf.tableViewData = [weakSelf.tasksIStarted.tasksAfterFiltering mutableCopy];
                [weakSelf.tableView reloadData];
            }
        }
    }];
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
    
    NSPredicate *initiatorSubpredicate = [NSPredicate predicateWithFormat:kInitiatorWorkflowsPredicateFormat, self.session.personIdentifier];
    NSPredicate *tasksIStartedPredicate = [NSCompoundPredicate andPredicateWithSubpredicates:@[self.supportedTasksPredicate, initiatorSubpredicate]];

    self.myTasks = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title") filteringPredicate:self.supportedTasksPredicate];
    self.tasksIStarted = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title") filteringPredicate:tasksIStartedPredicate];
}

- (TaskGroupItem *)taskGroupItem
{
    return self.isDisplayingMyTasks ? self.myTasks : self.tasksIStarted;
}

- (void)loadDataWithListingContext:(AlfrescoListingContext *)listingContext forceRefresh:(BOOL)forceRefresh completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    TaskGroupItem *groupToSwitchTo = [self taskGroupItem];
    self.title = groupToSwitchTo.title;
    
    if (groupToSwitchTo.hasDisplayableTasks == NO || forceRefresh || groupToSwitchTo.hasMoreItems)
    {
        AlfrescoPagingResultCompletionBlock myCompletionBlock = ^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            if (completionBlock)
            {
                completionBlock(pagingResult, error);
            }
        };
        
        if (forceRefresh)
        {
            listingContext = nil;
            [groupToSwitchTo clearAllTasks];
        }
        
        [self showHUD];
        
        if (self.isDisplayingMyTasks)
        {
            [self loadTasksWithListingContext:listingContext completionBlock:myCompletionBlock];
        }
        else
        {
            [self loadWorkflowProcessesWithListingContext:listingContext completionBlock:myCompletionBlock];
        }
    }
    else
    {
        self.tableViewData = [groupToSwitchTo.tasksAfterFiltering mutableCopy];
        [self.tableView reloadData];
    }
}

- (void)loadWorkflowProcessesWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    // create a new listing context so we can filter the processes
    AlfrescoListingFilter *filter = [[AlfrescoListingFilter alloc] initWithFilter:kAlfrescoFilterByWorkflowStatus value:kAlfrescoFilterValueWorkflowStatusActive];
    AlfrescoListingContext *filteredListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:listingContext.maxItems
                                                                                            skipCount:listingContext.skipCount
                                                                                         sortProperty:listingContext.sortProperty
                                                                                        sortAscending:listingContext.sortAscending
                                                                                        listingFilter:filter];
    
    [self.workflowService retrieveProcessesWithListingContext:filteredListingContext completionBlock:completionBlock];
}

- (void)loadTasksWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    [self.workflowService retrieveTasksWithListingContext:(listingContext ?: self.defaultListingContext) completionBlock:completionBlock];
}

- (void)displayTaskFilter:(id)sender event:(UIEvent *)event
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleActionSheet];

    // "My Tasks" filter
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.displayingMyTasks = YES;
        [self loadDataWithListingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }]];

    // "Tasks I Started" filter
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        self.displayingMyTasks = NO;
        [self loadDataWithListingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }]];
    
    // Cancel
    [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {}]];

    alertController.modalPresentationStyle = UIModalPresentationPopover;
    UIPopoverPresentationController *popoverPresenter = [alertController popoverPresentationController];
    popoverPresenter.barButtonItem = sender;
    [self presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - Overridden Functions

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        if (self.isDisplayingMyTasks)
        {
            [self.myTasks clearAllTasks];
            [self.myTasks addAndApplyFilteringToTasks:pagingResult.objects];
            self.myTasks.hasMoreItems = pagingResult.hasMoreItems;
            self.tableViewData = [self.myTasks.tasksAfterFiltering mutableCopy];
        }
        else
        {
            [self.tasksIStarted clearAllTasks];
            [self.tasksIStarted addAndApplyFilteringToTasks:pagingResult.objects];
            self.tasksIStarted.hasMoreItems = pagingResult.hasMoreItems;
            self.tableViewData = [self.tasksIStarted.tasksAfterFiltering mutableCopy];
        }
        
        [self.tableView reloadData];
    }
}

- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        TaskGroupItem *currentGroupedItem = [self taskGroupItem];
        [currentGroupedItem addAndApplyFilteringToTasks:pagingResult.objects];
        currentGroupedItem.hasMoreItems = pagingResult.hasMoreItems;
        self.tableViewData = [currentGroupedItem.tasksAfterFiltering mutableCopy];
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

    if (self.isDisplayingMyTasks)
    {
        AlfrescoWorkflowTask *currentTask = [self.tableViewData objectAtIndex:indexPath.row];
        cell.title = currentTask.summary;
        cell.dueDate = currentTask.dueAt;
        cell.priority = currentTask.priority;
        cell.processType = currentTask.name;
    }
    else
    {
        AlfrescoWorkflowProcess *currentProcess = [self.tableViewData objectAtIndex:indexPath.row];
        cell.title = currentProcess.summary;
        cell.dueDate = currentProcess.dueAt;
        cell.priority = currentProcess.priority;
        BOOL isAdhocProcessType = [self.adhocProcessTypePredicate evaluateWithObject:currentProcess.processDefinitionIdentifier];
        BOOL isInviteProcessType = [self.inviteProcessTypePredicate evaluateWithObject:currentProcess.processDefinitionIdentifier];
        
        NSString *processType = nil;
        if (isAdhocProcessType)
        {
            processType = NSLocalizedString(@"task.type.workflow.todo", @"Adhoc Process type");
        }
        else if (isInviteProcessType)
        {
            processType = NSLocalizedString(@"task.type.workflow.invitation", @"Invitation Process type");
        }
        else
        {
            processType = NSLocalizedString(@"task.type.workflow.review.and.approve", @"Review & Approve Process type");
        }
        cell.processType = processType;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    TaskGroupItem *currentTaskGroup = [self taskGroupItem];
    
    NSUInteger lastRowIndex = currentTaskGroup.numberOfTasksAfterFiltering - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(currentTaskGroup.numberOfTasksBeforeFiltering) intValue]];
        if ([currentTaskGroup hasMoreItems])
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;

            [self loadDataWithListingContext:moreListingContext forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id selectedObject = [self.tableViewData objectAtIndex:indexPath.row];
    
    TaskDetailsViewController *taskDetailsViewController = nil;
    
    if (self.isDisplayingMyTasks)
    {
        // Sanity check
        if ([selectedObject isKindOfClass:[AlfrescoWorkflowTask class]])
        {
            taskDetailsViewController = [[TaskDetailsViewController alloc] initWithTask:(AlfrescoWorkflowTask *)selectedObject session:self.session];
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    else
    {
        // Sanity check
        if ([selectedObject isKindOfClass:[AlfrescoWorkflowProcess class]])
        {
            taskDetailsViewController = [[TaskDetailsViewController alloc] initWithProcess:(AlfrescoWorkflowProcess *)selectedObject session:self.session];
        }
        else
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
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
        [self loadDataWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
                [self loadDataWithListingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self reloadTableViewWithPagingResult:pagingResult error:error];
                }];
            }
        }];
    }
}

@end
