//
//  TaskViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "TaskViewController.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "TasksCell.h"
#import "TaskGroupItem.h"
#import "UIColor+Custom.h"
#import "Utility.h"
#import "TaskDetailsViewController.h"
#import "UniversalDevice.h"

static NSString * const kDateFormat = @"dd MMM";
static NSString * const kActivitiReview = @"activitiReview";
static NSString * const kActivitiParallelReview = @"activitiParallelReview";
static NSString * const kActivitiToDo = @"activitiAdhoc";
static NSString * const kSupportedTasksPredicateFormat = @"(processDefinitionIdentifier CONTAINS %@) OR (processDefinitionIdentifier CONTAINS %@) OR (processDefinitionIdentifier CONTAINS %@)";
static NSString * const kInitiatorWorkflowsPredicateFormat = @"initiatorUsername like %@";

@interface TaskViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;
@property (nonatomic, strong) NSDateFormatter *dateFormatter;
@property (nonatomic, assign) TaskType displayedTaskType;
@property (nonatomic, strong) TaskGroupItem *myTasks;
@property (nonatomic, strong) TaskGroupItem *tasksIStarted;
@property (nonatomic, weak) UIBarButtonItem *filterButton;

@end

@implementation TaskViewController

- (id)initWithSession:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.session = session;
        self.dateFormatter = [[NSDateFormatter alloc] init];
        [self.dateFormatter setDateFormat:kDateFormat];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(taskCompleted:)
                                                     name:kAlfrescoWorkflowTaskDidComplete
                                                   object:nil];
        [self createWorkflowServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"tasks.title", @"Tasks Title");
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"task_filter.png"] style:UIBarButtonItemStylePlain target:self action:@selector(displayActionSheet:event:)];
    [self.navigationItem setRightBarButtonItem:filterButton];
    self.filterButton = filterButton;
    
    if (self.session)
    {
        [self showHUD];
        [self loadTasksForTaskType:self.displayedTaskType listingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self hidePullToRefreshView];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
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
        
        [self loadTasksForTaskType:TaskTypeTask listingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self hidePullToRefreshView];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
}

- (void)taskCompleted:(NSNotification *)notification
{
    // reload tasks and workflows following completion
    __weak typeof(self) weakSelf = self;

    [self showHUD];
    AlfrescoListingContext *tasksListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:self.myTasks.tasksBeforeFiltering.count skipCount:0];
    [self loadTasksWithListingContext:tasksListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [weakSelf hideHUD];
        if (pagingResult)
        {
            [weakSelf.myTasks clearAllTasks];
            [weakSelf.myTasks addAndApplyFilteringToTasks:pagingResult.objects];
            
            // currently being displayed, refresh the tableview.
            if (weakSelf.displayedTaskType == TaskTypeTask)
            {
                weakSelf.tableViewData = weakSelf.myTasks.tasksAfterFiltering;
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }];
    
    AlfrescoListingContext *workflowListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:self.tasksIStarted.tasksBeforeFiltering.count skipCount:0];
    [self loadWorkflowProcessesWithListingContext:workflowListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [weakSelf hideHUD];
        if (pagingResult)
        {
            [weakSelf.tasksIStarted clearAllTasks];
            [weakSelf.tasksIStarted addAndApplyFilteringToTasks:pagingResult.objects];
            
            // currently being displayed, refresh the tableview.
            if (weakSelf.displayedTaskType == TaskTypeProcess)
            {
                weakSelf.tableViewData = weakSelf.tasksIStarted.tasksAfterFiltering;
                [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }
    }];
}

- (void)createWorkflowServicesWithSession:(id<AlfrescoSession>)session
{
    self.workflowService = [[AlfrescoWorkflowService alloc] initWithSession:session];
    
    NSPredicate *myTasksPredicate = [NSPredicate predicateWithFormat:kSupportedTasksPredicateFormat, kActivitiReview, kActivitiParallelReview, kActivitiToDo];
    NSPredicate *tasksIStartedPredicate = [NSPredicate predicateWithFormat:kInitiatorWorkflowsPredicateFormat, self.session.personIdentifier];
    self.myTasks = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title")
                                     filteringPredicate:myTasksPredicate];
    self.tasksIStarted = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title")
                                           filteringPredicate:[NSCompoundPredicate andPredicateWithSubpredicates:@[myTasksPredicate, tasksIStartedPredicate]]];
}

- (TaskGroupItem *)taskGroupItemForType:(TaskType)taskType
{
    TaskGroupItem *returnGroupItem = nil;
    switch (taskType)
    {
        case TaskTypeTask:
            returnGroupItem = self.myTasks;
            break;

        case TaskTypeProcess:
            returnGroupItem = self.tasksIStarted;
            break;
    }
    return returnGroupItem;
}

- (void)loadTasksForTaskType:(TaskType)taskType listingContext:(AlfrescoListingContext *)listingContext forceRefresh:(BOOL)forceRefresh completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    TaskGroupItem *groupToSwitchTo = [self taskGroupItemForType:taskType];
    
    self.displayedTaskType = taskType;
    self.title = groupToSwitchTo.title;
    
    if (groupToSwitchTo.hasDisplayableTasks == NO || forceRefresh || groupToSwitchTo.hasMoreItems)
    {
        if (forceRefresh)
        {
            listingContext = nil;
            [groupToSwitchTo clearAllTasks];
        }
        
        switch (taskType)
        {
            case TaskTypeTask:
            {
                [self loadTasksWithListingContext:listingContext completionBlock:completionBlock];
            }
            break;
                
            case TaskTypeProcess:
            {
                [self loadWorkflowProcessesWithListingContext:listingContext completionBlock:completionBlock];
            }
            break;
        }
    }
    else
    {
        self.tableViewData = groupToSwitchTo.tasksAfterFiltering;
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
    AlfrescoListingFilter *filter = [[AlfrescoListingFilter alloc] initWithFilter:kAlfrescoFilterByWorkflowState value:kAlfrescoFilterValueWorkflowStateActive];
    AlfrescoListingContext *filteredListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:listingContext.maxItems
                                                                                            skipCount:listingContext.skipCount
                                                                                         sortProperty:listingContext.sortProperty
                                                                                        sortAscending:listingContext.sortAscending
                                                                                        listingFilter:filter];
    
    [self.workflowService retrieveProcessesWithListingContext:filteredListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (error)
        {
            AlfrescoLogError(@"Error: %@", error.localizedDescription);
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(pagingResult, error);
            }
        }
    }];
}

- (void)loadTasksWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    [self.workflowService retrieveTasksWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (error)
        {
            AlfrescoLogError(@"Error: %@", error.localizedDescription);
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(pagingResult, error);
            }
        }
    }];
}

- (void)displayActionSheet:(id)sender event:(UIEvent *)event
{
    UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:nil destructiveButtonTitle:nil otherButtonTitles:nil];
    
    [actionSheet addButtonWithTitle:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title")];
    [actionSheet addButtonWithTitle:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title")];
    [actionSheet setCancelButtonIndex:[actionSheet addButtonWithTitle:NSLocalizedString(@"Cancel", @"Cancel")]];
    
    if (IS_IPAD)
    {
        [actionSheet showFromBarButtonItem:sender animated:YES];
    }
    else
    {
        [actionSheet showInView:self.view];
    }
    
    // UIActionSheet button titles don't pick up the global tint color by default
    [Utility colorButtonsForActionSheet:actionSheet tintColor:[UIColor appTintColor]];

    self.filterButton.enabled = NO;
}

#pragma mark - Overridden Functions

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        switch (self.displayedTaskType)
        {
            case TaskTypeTask:
            {
                [self.myTasks addAndApplyFilteringToTasks:pagingResult.objects];
                self.myTasks.hasMoreItems = pagingResult.hasMoreItems;
                self.tableViewData = self.myTasks.tasksAfterFiltering;
            }
            break;
                
            case TaskTypeProcess:
            {
                [self.tasksIStarted addAndApplyFilteringToTasks:pagingResult.objects];
                self.tasksIStarted.hasMoreItems = pagingResult.hasMoreItems;
                self.tableViewData = self.tasksIStarted.tasksAfterFiltering;
            }
            break;
        }
        
        [self.tableView reloadData];
    }
}

- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        TaskGroupItem *currentGroupedItem = [self taskGroupItemForType:self.displayedTaskType];
        [currentGroupedItem addAndApplyFilteringToTasks:pagingResult.objects];;
        currentGroupedItem.hasMoreItems = pagingResult.hasMoreItems;
        self.tableViewData = currentGroupedItem.tasksAfterFiltering;
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
    static NSString *CellIdentifier = @"Cell";
    TasksCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = (TasksCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TasksCell class]) owner:self options:nil] lastObject];
    }
    
    switch (self.displayedTaskType)
    {
        case TaskTypeTask:
        {
            AlfrescoWorkflowTask *currentTask = [self.tableViewData objectAtIndex:indexPath.row];
            NSString *taskTitle = (currentTask.name) ? currentTask.name : NSLocalizedString(@"tasks.process.unnamed", @"Unnamed process");
            cell.taskNameTextLabel.text = taskTitle;
            cell.taskDueDateTextLabel.text = [self.dateFormatter stringFromDate:currentTask.dueAt];
            [cell setPriorityLevel:currentTask.priority];
        }
        break;
            
        case TaskTypeProcess:
        {
            AlfrescoWorkflowProcess *currentProcess = [self.tableViewData objectAtIndex:indexPath.row];
            NSString *processTitle = (currentProcess.name) ? currentProcess.name : NSLocalizedString(@"tasks.process.unnamed", @"Unnamed process");
            cell.taskNameTextLabel.text = processTitle;
            cell.taskDueDateTextLabel.text = [self.dateFormatter stringFromDate:currentProcess.dueAt];
            [cell setPriorityLevel:currentProcess.priority];
        }
        break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    TaskGroupItem *currentTaskGroup = [self taskGroupItemForType:self.displayedTaskType];
    
    NSUInteger lastRowIndex = currentTaskGroup.numberOfTasksAfterFiltering - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:currentTaskGroup.numberOfTasksBeforeFiltering];
        if ([currentTaskGroup hasMoreItems])
        {
            // show more items are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;

            [self loadTasksForTaskType:self.displayedTaskType listingContext:moreListingContext forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
    
    if (self.displayedTaskType == TaskTypeTask)
    {
        taskDetailsViewController = [[TaskDetailsViewController alloc] initWithTask:(AlfrescoWorkflowTask *)selectedObject session:self.session];
    }
    else if (self.displayedTaskType == TaskTypeProcess)
    {
        taskDetailsViewController = [[TaskDetailsViewController alloc] initWithProcess:(AlfrescoWorkflowProcess *)selectedObject session:self.session];
    }
    
    [UniversalDevice pushToDisplayViewController:taskDetailsViewController usingNavigationController:self.navigationController animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TasksCell *cell = (TasksCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return (height < [TasksCell minimumCellHeight]) ? [TasksCell minimumCellHeight] : height;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    if (self.session)
    {
        [self loadTasksForTaskType:self.displayedTaskType listingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self hidePullToRefreshView];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
    else
    {
        [self hidePullToRefreshView];
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        [[LoginManager sharedManager] attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
    }
}

#pragma mark - UIActionSheetDelegate Functions

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
    NSString *buttonTitle = [actionSheet buttonTitleAtIndex:buttonIndex];
    [actionSheet dismissWithClickedButtonIndex:0 animated:YES];
    self.filterButton.enabled = YES;
    
    if ([buttonTitle isEqualToString:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title")])
    {
        [self loadTasksForTaskType:TaskTypeTask listingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title")])
    {
        [self loadTasksForTaskType:TaskTypeProcess listingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
}

- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == actionSheet.cancelButtonIndex)
    {
        self.filterButton.enabled = YES;
    }
}

@end
