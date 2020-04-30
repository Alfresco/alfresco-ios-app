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
 
#import "CreateTaskViewController.h"
#import "TextFieldCell.h"
#import "LabelCell.h"
#import "SwitchCell.h"
#import "TaskPriorityCell.h"
#import "TaskApproversCell.h"
#import "ErrorDescriptions.h"

static CGFloat const kNavigationBarHeight = 44.0f;
static CGFloat const kMinimumPrioritySegmentWidth = 64.0f;

typedef NS_ENUM(NSInteger, CreateTaskRowType)
{
    CreateTaskRowTypeTitle,
    CreateTaskRowTypeDueDate,
    CreateTaskRowTypeAssignees,
    CreateTaskRowTypeApprovers,
    CreateTaskRowTypeAttachments,
    CreateTaskRowTypePriority,
    CreateTaskRowTypeEmailNotification
};

@interface CreateTaskViewController ()

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;

@property (nonatomic, assign) WorkflowType workflowType;
@property (nonatomic, strong) NSArray *tableViewGroups;
@property (nonatomic, strong) NodePicker *nodePicker;
@property (nonatomic, strong) PeoplePicker *peoplePicker;
@property (nonatomic, strong) NSMutableArray *assignees;
@property (nonatomic, strong) NSMutableArray *attachments;
@property (nonatomic) BOOL documentReview;
@property (nonatomic, strong) DatePickerViewController *datePickerViewController;
@property (nonatomic, strong) UINavigationController *datePickerNavigationViewController;
@property (nonatomic, strong) NSDate *dueDate;
@property (nonatomic, strong) UIBarButtonItem *createTaskButton;

@property (nonatomic, strong) UITextField *titleField;
@property (nonatomic, strong) UILabel *dueDateLabel;
@property (nonatomic, strong) UILabel *assigneesLabel;
@property (nonatomic, strong) UILabel *attachmentsLabel;
@property (nonatomic, strong) UISwitch *emailNotificationSwitch;
@property (nonatomic, strong) UISegmentedControl *prioritySegmentControl;
@property (nonatomic, strong) TaskApproversCell *approversCell;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation CreateTaskViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session workflowType:(WorkflowType)workflowType
{
    return [self initWithSession:session workflowType:workflowType attachments:nil];
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session workflowType:(WorkflowType)workflowType attachments:(NSArray *)attachments
{
    return [self initWithSession:session workflowType:workflowType attachments:attachments documentReview:NO];
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session workflowType:(WorkflowType)workflowType attachments:(NSArray *)attachments documentReview: (BOOL) documentReview
{
    self = [self init];
    if (self)
    {
        _session = session;
        _workflowType = workflowType;
        _workflowService = [[AlfrescoWorkflowService alloc] initWithSession:session];
        _attachments = [attachments mutableCopy];
        _documentReview = documentReview;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"task.create.title", @"Create Task");
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonTapped:)];
    
    self.createTaskButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"task.create.button", @"Create")
                                                             style:UIBarButtonItemStyleDone
                                                            target:self
                                                            action:@selector(createTaskButtonTapped:)];
    self.createTaskButton.enabled = NO;
    
    self.navigationItem.leftBarButtonItem = cancelButton;
    self.navigationItem.rightBarButtonItem = self.createTaskButton;
    
    self.nodePicker = [[NodePicker alloc] initWithSession:self.session navigationController:self.navigationController];
    self.nodePicker.delegate = self;
    self.peoplePicker = [[PeoplePicker alloc] initWithSession:self.session navigationController:self.navigationController];
    self.peoplePicker.delegate = self;
    
    [self createTableViewGroups];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.tableView reloadData];
    [self validateForm];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewTaskCreateForm];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _tableView.delegate = nil;
}

#pragma mark - Private Methods

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    self.workflowService = [[AlfrescoWorkflowService alloc] initWithSession:self.session];
}

- (void)createTableViewGroups
{
    NSArray *group1 = @[@(CreateTaskRowTypeTitle), @(CreateTaskRowTypeDueDate)];
    
    NSArray *group2 = nil;
    if (self.workflowType == WorkflowTypeAdHoc)
    {
        group2 = @[@(CreateTaskRowTypeAssignees), @(CreateTaskRowTypeAttachments)];
    }
    else
    {
        group2 = @[@(CreateTaskRowTypeAssignees), @(CreateTaskRowTypeApprovers), @(CreateTaskRowTypeAttachments)];
    }
    
    NSArray *group3 = @[@(CreateTaskRowTypePriority), @(CreateTaskRowTypeEmailNotification)];
    
    self.tableViewGroups = @[group1, group2, group3];
}

- (void)cancelButtonTapped:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)createTaskButtonTapped:(id)sender
{
    NSString *processDefinitionKey = [WorkflowHelper processDefinitionKeyForWorkflowType:self.workflowType numberOfAssignees:self.assignees.count session:self.session];
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:self.tableView];
    [progressHUD showAnimated:YES];
    
    [self.workflowService retrieveProcessDefinitionWithKey:processDefinitionKey completionBlock:^(AlfrescoWorkflowProcessDefinition *processDefinition, NSError *error) {
        
        if (processDefinition)
        {
            NSString *title = [self.titleField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
            NSNumber *priority = @(self.prioritySegmentControl.selectedSegmentIndex + 1);
            NSNumber *sendNotification = @(self.emailNotificationSwitch.isOn);
            NSDictionary *variables = nil;
            
            if (self.workflowType == WorkflowTypeReview)
            {
                NSInteger approvalRate = round((self.approversCell.stepper.value / self.assignees.count) * 100);
                variables = @{kAlfrescoWorkflowVariableProcessApprovalRate : @(approvalRate)};
            }
            
            __weak typeof(self) weakSelf = self;
            [self.workflowService startProcessForProcessDefinition:processDefinition
                                                              name:title
                                                          priority:priority
                                                           dueDate:self.dueDate
                                             sendEmailNotification:sendNotification
                                                         assignees:self.assignees
                                                         variables:variables
                                                       attachments:self.attachments
                                                   completionBlock:^(AlfrescoWorkflowProcess *process, NSError *error) {
                                                       __strong typeof(self) strongSelf = weakSelf;
                                                       
                                                       [progressHUD hideAnimated:YES];
                                                       if (error)
                                                       {
                                                           displayErrorMessageWithTitle(NSLocalizedString(@"task.create.error", @"Failed to create Task"), [ErrorDescriptions descriptionForError:error]);
                                                       }
                                                       else
                                                       {
                                                           [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoWorkflowTaskListDidChangeNotification object:process];
                                                           [self dismissViewControllerAnimated:YES completion:^{
                                                               displayInformationMessage(NSLocalizedString(@"task.create.created", @"Task Created"));
                                                           }];
                                                           
                                                           if (strongSelf->_documentReview)
                                                           {
                                                               AlfrescoDocument *document = strongSelf.attachments.firstObject;
                                                               NSString *mimeType = document.contentMimeType;
                                                               
                                                               [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                                                                 action:kAnalyticsEventActionSendForReview
                                                                                                                  label:mimeType
                                                                                                                  value:@1];
                                                           }
                                                           else
                                                           {
                                                               [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryBPM
                                                                                                                 action:kAnalyticsEventActionCreate
                                                                                                                  label:process.processDefinitionIdentifier
                                                                                                                  value:@1];
                                                           }
                                                       }
                                                   }];
        }
        else
        {
            [progressHUD hideAnimated:YES];
            displayErrorMessageWithTitle(NSLocalizedString(@"task.create.error", @"Failed to create Task"), [ErrorDescriptions descriptionForError:error]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

- (void)stepperPressed:(id)sender
{
    [self updateApproversCellInfo];
}

- (void)updateApproversCellInfo
{
    NSInteger numberOfApprovers = self.approversCell.stepper.value;
    if (numberOfApprovers == 0)
    {
        numberOfApprovers = 1;
    }
    else if (numberOfApprovers > self.assignees.count)
    {
        numberOfApprovers = self.assignees.count;
    }
    
    if (self.assignees.count == 0)
    {
        self.approversCell.stepper.minimumValue = 0;
        self.approversCell.stepper.maximumValue = 0;
        self.approversCell.stepper.enabled = NO;
        self.approversCell.titleLabel.text = NSLocalizedString(@"task.create.approvers", @"Approvers");
    }
    else
    {
        self.approversCell.stepper.enabled = YES;
        self.approversCell.stepper.minimumValue = 1;
        self.approversCell.stepper.maximumValue = self.assignees.count;
        
        if (self.assignees.count == 1)
        {
            self.approversCell.titleLabel.text = [NSString stringWithFormat:@"%li of %li %@", (long)numberOfApprovers, (long)self.assignees.count, NSLocalizedString(@"task.create.approver", @"Approver")];
        }
        else
        {
            self.approversCell.titleLabel.text = [NSString stringWithFormat:@"%li of %li %@", (long)numberOfApprovers, (long)self.assignees.count, NSLocalizedString(@"task.create.approvers", @"Approvers")];
        }
    }
}

- (void)validateForm
{
    self.createTaskButton.enabled = ((self.assignees.count > 0) && (self.titleField.text.length >= 1));
}

- (void)showDatePicker:(CGRect)positionInTableView
{
    self.datePickerViewController = [[DatePickerViewController alloc] initWithDate:self.dueDate];
    self.datePickerViewController.delegate = self;
    
    if (IS_IPAD)
    {
        CGSize datePickerViewSize = self.datePickerViewController.view.frame.size;
        self.datePickerViewController.preferredContentSize = CGSizeMake(datePickerViewSize.width, datePickerViewSize.height + kNavigationBarHeight);
        
        CGRect popoverRect = [self.view convertRect:positionInTableView fromView:self.tableView];
        
        self.datePickerNavigationViewController = [[UINavigationController alloc] initWithRootViewController:self.datePickerViewController];
        self.datePickerNavigationViewController.modalPresentationStyle = UIModalPresentationPopover;
        self.datePickerNavigationViewController.popoverPresentationController.sourceView = self.view;
        self.datePickerNavigationViewController.popoverPresentationController.sourceRect = popoverRect;
        self.datePickerNavigationViewController.popoverPresentationController.permittedArrowDirections = UIPopoverArrowDirectionUp;

        [self presentViewController:self.datePickerNavigationViewController animated:YES completion:nil];
    }
    else
    {
        [self.navigationController pushViewController:self.datePickerViewController animated:YES];
    }
}

#pragma mark - DatePicker Delegate Method

- (void)datePicker:(DatePickerViewController *)datePicker selectedDate:(NSDate *)date
{
    if (self.datePickerViewController != nil)
    {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSUInteger preservedComponents = (NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay);
        self.dueDate = [calendar dateFromComponents:[calendar components:preservedComponents fromDate:date]];
        self.datePickerViewController = nil;
        [self.tableView reloadData];
        
        if (!IS_IPAD)
        {
            [self.navigationController popViewControllerAnimated:YES];
        }
    }
    
    if (self.datePickerNavigationViewController)
    {
        [self.datePickerNavigationViewController dismissViewControllerAnimated:YES completion:nil];
        self.datePickerNavigationViewController = nil;
    }
}

#pragma mark - TableView Delegate and Datasource Methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewGroups[section] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CreateTaskRowType rowType = [self.tableViewGroups[indexPath.section][indexPath.row] integerValue];
    
    UITableViewCell *cell = nil;
    switch (rowType)
    {
        case CreateTaskRowTypeTitle:
        {
            TextFieldCell *titleCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
            titleCell.titleLabel.text = NSLocalizedString(@"task.create.taskTitle", @"Task Title");
            if (self.titleField.text.length > 0)
            {
                titleCell.valueTextField.text = self.titleField.text;
            }
            else
            {
                titleCell.valueTextField.placeholder = NSLocalizedString(@"task.create.taskTitle.placeholder", @"required");
            }
            titleCell.valueTextField.returnKeyType = UIReturnKeyDone;
            titleCell.valueTextField.delegate = self;
            titleCell.shouldBecomeFirstResponder = YES;
            self.titleField = titleCell.valueTextField;
            cell = titleCell;
            break;
        }
        case CreateTaskRowTypeDueDate:
        {
            LabelCell *dueDateCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
            dueDateCell.titleLabel.text = NSLocalizedString(@"task.create.duedate", @"Due On");
            if (self.dueDate)
            {
                NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
                dateFormatter.dateStyle = NSDateFormatterMediumStyle;
                dueDateCell.valueLabel.text = [dateFormatter stringFromDate:self.dueDate];
            }
            else
            {
                dueDateCell.valueLabel.text = NSLocalizedString(@"task.create.duedate.placeholder", @"Due Date");
            }
            self.dueDateLabel = dueDateCell.valueLabel;
            dueDateCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = dueDateCell;
            break;
        }
        case CreateTaskRowTypeAssignees:
        {
            LabelCell *assigneesCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
            assigneesCell.titleLabel.text = self.workflowType == WorkflowTypeAdHoc ? NSLocalizedString(@"task.create.assignee", @"Assignee") : NSLocalizedString(@"task.create.assignees", @"Assignees");
            if (self.assignees && self.assignees.count > 0)
            {
                if (self.assignees.count > 1)
                {
                    assigneesCell.valueLabel.text = [NSString stringWithFormat:@"%li %@", (long)self.assignees.count, [NSLocalizedString(@"task.create.assignees", @"Assignees") lowercaseString]];
                }
                else
                {
                    assigneesCell.valueLabel.text = [self.assignees.firstObject fullName];
                }
            }
            else
            {
                assigneesCell.valueLabel.text = NSLocalizedString(@"task.create.assignee.placeholder", @"No Assignees");
            }
            self.assigneesLabel = assigneesCell.valueLabel;
            assigneesCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = assigneesCell;
            break;
        }
        case CreateTaskRowTypeAttachments:
        {
            LabelCell *attachmentsCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
            attachmentsCell.titleLabel.text = NSLocalizedString(@"task.create.attachments", @"attachements");
            if (self.attachments && self.attachments.count > 0)
            {
                if (self.attachments.count > 1)
                {
                    attachmentsCell.valueLabel.text = [NSString stringWithFormat:@"%li %@", (long)self.attachments.count, [NSLocalizedString(@"task.create.attachments", @"Attachments") lowercaseString]];
                }
                else
                {
                    attachmentsCell.valueLabel.text = [self.attachments.firstObject name];
                }
            }
            else
            {
                attachmentsCell.valueLabel.text = NSLocalizedString(@"task.create.attachments.placeholder", @"No Attachments");
            }
            self.attachmentsLabel = attachmentsCell.valueLabel;
            attachmentsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell = attachmentsCell;
            break;
        }
        case CreateTaskRowTypePriority:
        {
            TaskPriorityCell *priorityCell = (TaskPriorityCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TaskPriorityCell class]) owner:self options:nil] lastObject];
            priorityCell.titleLabel.text = NSLocalizedString(@"task.create.priority", @"Priority");
            
            UISegmentedControl *segmentedControl = priorityCell.segmentControl;
            NSString *segmentTitle = NSLocalizedString(@"task.create.priority.high", @"High");
            NSString *longestTitle = segmentTitle;
            [segmentedControl setTitle:segmentTitle forSegmentAtIndex:0];
            
            segmentTitle = NSLocalizedString(@"task.create.priority.medium", @"Medium");
            longestTitle = (segmentTitle.length > longestTitle.length) ? segmentTitle : longestTitle;
            [segmentedControl setTitle:segmentTitle forSegmentAtIndex:1];
            
            segmentTitle = NSLocalizedString(@"task.create.priority.low", @"Low");
            longestTitle = (segmentTitle.length > longestTitle.length) ? segmentTitle : longestTitle;
            [segmentedControl setTitle:segmentTitle forSegmentAtIndex:2];
 
            CGFloat longestTitleWidth = [longestTitle sizeWithAttributes:[segmentedControl titleTextAttributesForState:UIControlStateNormal]].width;
            if (longestTitleWidth < kMinimumPrioritySegmentWidth)
            {
                segmentedControl.apportionsSegmentWidthsByContent = NO;
                for (NSUInteger index = 0; index < segmentedControl.numberOfSegments; index++)
                {
                    [segmentedControl setWidth:kMinimumPrioritySegmentWidth forSegmentAtIndex:index];
                }
            }
            
            if (self.prioritySegmentControl)
            {
                [segmentedControl setSelectedSegmentIndex:self.prioritySegmentControl.selectedSegmentIndex];
            }
            
            self.prioritySegmentControl = segmentedControl;
            cell = priorityCell;
            break;
        }
        case CreateTaskRowTypeEmailNotification:
        {
            SwitchCell *emailNotificationCell = (SwitchCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SwitchCell class]) owner:self options:nil] lastObject];
            emailNotificationCell.titleLabel.text = NSLocalizedString(@"task.create.emailnotification", @"Email Notification");
            
            if (self.emailNotificationSwitch)
            {
                [emailNotificationCell.valueSwitch setOn:self.emailNotificationSwitch.isOn animated:NO];
            }
            
            self.emailNotificationSwitch = emailNotificationCell.valueSwitch;
            cell = emailNotificationCell;
            break;
        }
        case CreateTaskRowTypeApprovers:
        {
            TaskApproversCell *approversCell = (TaskApproversCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TaskApproversCell class]) owner:self options:nil] lastObject];
            approversCell.stepper.value = self.approversCell.stepper.value;
            
            self.approversCell = approversCell;
            [self.approversCell.stepper addTarget:self action:@selector(stepperPressed:) forControlEvents:UIControlEventValueChanged];
            [self updateApproversCellInfo];
            cell = self.approversCell;
            break;
        }
        default:
        {
            cell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
            break;
        }
    }
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    CreateTaskRowType rowType = [self.tableViewGroups[indexPath.section][indexPath.row] integerValue];
    
    if (rowType != CreateTaskRowTypeTitle)
    {
        [self.titleField resignFirstResponder];
    }
    
    switch (rowType)
    {
        case CreateTaskRowTypeAttachments:
        {
            [self.nodePicker startWithNodes:self.attachments type:NodePickerTypeDocuments mode:NodePickerModeMultiSelect];
            break;
        }
        case CreateTaskRowTypeAssignees:
        {
            PeoplePickerMode peoplePickerMode = (self.workflowType == WorkflowTypeAdHoc) ? PeoplePickerModeSingleSelectAutoConfirm : PeoplePickerModeMultiSelect;
            [self.peoplePicker startWithPeople:self.assignees mode:peoplePickerMode modally:NO];
            break;
        }
        case CreateTaskRowTypeDueDate:
        {
            LabelCell *dueDateCell = (LabelCell *)[self.tableView cellForRowAtIndexPath:indexPath];
            CGRect dueDateLabelPosition = [self.tableView convertRect:dueDateCell.valueLabel.frame fromView:dueDateCell];
            [self showDatePicker:dueDateLabelPosition];
            break;
        }
        default:
            break;
    }
}

#pragma mark - UITextField Notification

- (void)textFieldDidChange:(NSNotification *)notification
{
    [self validateForm];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.titleField resignFirstResponder];
    return YES;
}

#pragma mark - NodePicker, PeoplePicker Delegate Methods

- (void)nodePicker:(NodePicker *)nodePicker didSelectNodes:(NSArray *)selectedNodes
{
    self.attachments = [selectedNodes mutableCopy];
}

- (void)peoplePicker:(PeoplePicker *)peoplePicker didSelectPeople:(NSArray *)selectedPeople
{
    self.assignees = [selectedPeople mutableCopy];
}

@end
