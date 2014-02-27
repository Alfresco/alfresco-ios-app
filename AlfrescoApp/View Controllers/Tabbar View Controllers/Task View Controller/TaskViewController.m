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

static NSString * const kDateFormat = @"dd MMM";
static NSString * const kActivitiReview = @"activitiReview";
static NSString * const kActivitiParallelReview = @"activitiParallelReview";
static NSString * const kActivitiToDo = @"activitiAdhoc";

static NSString * const kSupportedTasksPredicateFormat = @"(processDefinitionIdentifier like %@) OR (processDefinitionIdentifier like %@) OR (processDefinitionIdentifier like %@)";
static NSString * const kSupportedWorkflowsPredicateFormat = @"(processDefinitionKey like %@) OR (processDefinitionKey like %@) OR (processDefinitionKey like %@)";
static NSString * const kInitiatorWorkflowsPredicateFormat = @"initiatorUsername like %@";

typedef NS_ENUM(NSUInteger, TaskType)
{
    TaskTypeMyTasks = 0,
    TaskTypeTasksIStarted
};

@interface TaskViewController () <UIActionSheetDelegate>

@property (nonatomic, strong) AlfrescoWorkflowProcessService *processService;
@property (nonatomic, strong) AlfrescoWorkflowTaskService *taskService;
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
        self.myTasks = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.mytasks", @"My Tasks Title")];
        self.tasksIStarted = [[TaskGroupItem alloc] initWithTitle:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title")];
        [self createWorkflowServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"tasks.title", @"Tasks Title");
    
    UIBarButtonItem *filterButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"hamburger.png"] style:UIBarButtonItemStylePlain target:self action:@selector(displayActionSheet:event:)];
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
        
        [self loadTasksForTaskType:TaskTypeMyTasks listingContext:nil forceRefresh:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            [self hidePullToRefreshView];
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
}

- (void)createWorkflowServicesWithSession:(id<AlfrescoSession>)session
{
    self.processService = [[AlfrescoWorkflowProcessService alloc] initWithSession:session];
    self.taskService = [[AlfrescoWorkflowTaskService alloc] initWithSession:session];
}

- (TaskGroupItem *)taskGroupItemForType:(TaskType)taskType
{
    TaskGroupItem *returnGroupItem = nil;
    switch (taskType)
    {
        case TaskTypeMyTasks:
            returnGroupItem = self.myTasks;
            break;

        case TaskTypeTasksIStarted:
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
    
    if (groupToSwitchTo.hasTasks == NO || forceRefresh)
    {
        if (forceRefresh)
        {
            listingContext = nil;
            [groupToSwitchTo clearAllTasks];
        }
        
        switch (taskType)
        {
            case TaskTypeMyTasks:
            {
                [self loadTasksWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self hideHUD];
                    [self hidePullToRefreshView];
                    [self reloadTableViewWithPagingResult:pagingResult error:error];
                }];
            }
            break;
                
            case TaskTypeTasksIStarted:
            {
                [self loadWorkflowProcessesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                    [self hideHUD];
                    [self hidePullToRefreshView];
                    [self reloadTableViewWithPagingResult:pagingResult error:error];
                }];
            }
            break;
        }
    }
    else
    {
        self.tableViewData = groupToSwitchTo.tasks;
        [self.tableView reloadData];
    }
}

- (void)loadWorkflowProcessesWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    [self.processService retrieveProcessesInState:kAlfrescoWorkflowProcessStateActive listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
    
    [self.taskService retrieveTasksWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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

- (NSArray *)supportedTasksFromArray:(NSArray *)unfilteredArray
{
    NSPredicate *supportedPredicate = [NSPredicate predicateWithFormat:kSupportedTasksPredicateFormat, kActivitiReview, kActivitiToDo, kActivitiParallelReview];
    return [unfilteredArray filteredArrayUsingPredicate:supportedPredicate];
}

- (NSArray *)supportedWorkflowsFromArray:(NSArray *)unfilteredArray
{
    NSPredicate *supportedPredicate = [NSPredicate predicateWithFormat:kSupportedWorkflowsPredicateFormat, kActivitiReview, kActivitiToDo, kActivitiParallelReview];
    return [unfilteredArray filteredArrayUsingPredicate:supportedPredicate];
}

- (NSArray *)initiatedWorkflowsFromArray:(NSArray *)unfilteredArray
{
    NSPredicate *startedByMePredicate = [NSPredicate predicateWithFormat:kInitiatorWorkflowsPredicateFormat, self.session.personIdentifier];
    return [unfilteredArray filteredArrayUsingPredicate:startedByMePredicate];
}

#pragma mark - Overridden Functions

- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        switch (self.displayedTaskType)
        {
            case TaskTypeMyTasks:
            {
                [self.myTasks addTasks:[self supportedTasksFromArray:pagingResult.objects]];
                [self.myTasks setHasMoreItems:pagingResult.hasMoreItems];;
                self.tableViewData = self.myTasks.tasks;
            }
            break;
                
            case TaskTypeTasksIStarted:
            {
                NSMutableArray *startedWorkflows = [[self initiatedWorkflowsFromArray:[self supportedWorkflowsFromArray:pagingResult.objects]] mutableCopy];
                [self.tasksIStarted addTasks:startedWorkflows];
                [self.tasksIStarted setHasMoreItems:pagingResult.hasMoreItems];
                self.tableViewData = self.tasksIStarted.tasks;
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
        [currentGroupedItem addTasks:[self supportedTasksFromArray:pagingResult.objects]];
        [currentGroupedItem setHasMoreItems:pagingResult.hasMoreItems];
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
        case TaskTypeMyTasks:
        {
            AlfrescoWorkflowTask *currentTask = [self.tableViewData objectAtIndex:indexPath.row];
            NSString *taskTitle = (currentTask.taskDescription) ? currentTask.taskDescription : NSLocalizedString(@"tasks.process.unnamed", @"Unnamed process");
            cell.taskNameTextLabel.text = taskTitle;
            cell.taskDueDateTextLabel.text = [self.dateFormatter stringFromDate:currentTask.dueAt];
            [cell setPriorityLevel:currentTask.priority];
        }
            break;
            
        case TaskTypeTasksIStarted:
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
    
    NSUInteger lastRowIndex = currentTaskGroup.numberOfTasks - 1;
    
    // if the last cell is about to be drawn, check if there are more sites
    if (indexPath.row == lastRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(currentTaskGroup.numberOfTasks) intValue]];
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
    // TODO
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
        [self loadTasksForTaskType:TaskTypeMyTasks listingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }];
    }
    else if ([buttonTitle isEqualToString:NSLocalizedString(@"tasks.title.taskistarted", @"Tasks I Started Title")])
    {
        [self loadTasksForTaskType:TaskTypeTasksIStarted listingContext:nil forceRefresh:NO completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
