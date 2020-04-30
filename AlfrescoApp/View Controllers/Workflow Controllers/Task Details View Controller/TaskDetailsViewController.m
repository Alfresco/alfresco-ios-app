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
 
#import "TaskDetailsViewController.h"
#import "TaskHeaderView.h"
#import "PagedScrollView.h"
#import "ThumbnailManager.h"
#import "AlfrescoNodeCell.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "DocumentPreviewViewController.h"
#import "ErrorDescriptions.h"
#import "TextView.h"
#import "TasksAndAttachmentsViewController.h"
#import "UniversalDevice.h"
#import "PeoplePicker.h"
#import "WorkflowHelper.h"

static CGFloat const kMaxCommentTextViewHeight = 60.0f;
static UILayoutPriority const kHighPriority = 950;
static UILayoutPriority const kLowPriority = 250;

@interface TaskDetailsViewController () <TextViewDelegate, UIGestureRecognizerDelegate, PeoplePickerDelegate>

//// Layout Constraints ////
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *textViewContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpacingOfTextViewContainerConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *horizontalSpaceFromDoneButtonToCommentTextConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *trailingSpaceFromCommentTextToContainerConstraint;

//// Data Models ////
// Models
@property (nonatomic, strong) AlfrescoWorkflowProcess *process;
@property (nonatomic, strong) AlfrescoWorkflowTask *task;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) PeoplePicker *peoplePicker;
@property (nonatomic, assign, getter=isDisplayingTask) BOOL displayingTask;
// Services
@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;

//// Views ////
// Header
@property (nonatomic, weak) TaskHeaderView *taskHeaderView;
@property (nonatomic, weak) IBOutlet UIView *taskHeaderViewContainer;
// Container
@property (nonatomic, weak) IBOutlet UIView *detailsContainerView;
// Comments
@property (nonatomic, weak) IBOutlet TextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *doneButton;
@property (nonatomic, weak) IBOutlet UIButton *approveButton;
@property (nonatomic, weak) IBOutlet UIButton *rejectButton;
@property (nonatomic, weak) IBOutlet UIButton *cancelButton;

@end

@implementation TaskDetailsViewController

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.task = task;
        self.displayingTask = YES;
    }
    return self;
}

- (instancetype)initWithProcess:(AlfrescoWorkflowProcess *)process session:(id<AlfrescoSession>)session
{
    self = [self initWithSession:session];
    if (self)
    {
        self.process = process;
        self.displayingTask = NO;
    }
    return self;
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.session = session;
        [self createServicesWithSession:session];
        [self registerForNotifications];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // configure the view
    [self configure];
    
    // Add reassign button for tasks, but not tasks that are invitations.
    if (self.task && (![self isAnInvitePendingTask:self.task] && ![self isAnInviteAcceptedOrRejectedTask:self.task]))
    {
        UIBarButtonItem *reassignButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"task.reassign.button.title", @"Reassign") style:UIBarButtonItemStylePlain target:self action:@selector(pressedReassignButton:)];
        self.navigationItem.rightBarButtonItem = reassignButton;
    }

    [self.cancelButton addTarget:self action:@selector(cancelCommentAction:) forControlEvents:UIControlEventTouchUpInside];

    // Dismiss keyboard gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
    
    // Localise UI
    [self localiseUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewTaskDetails];
}

#pragma mark - Private Functions

- (void)localiseUI
{
    self.textView.placeholderText = NSLocalizedString(@"tasks.textview.addcomment.placeholder", @"Add comment placeholder");
    [self.cancelButton setTitle:NSLocalizedString(@"Cancel", @"Cancel") forState:UIControlStateNormal];
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionRefreshedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillshowAnimated:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createServicesWithSession:session];
}

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.workflowService = [[AlfrescoWorkflowService alloc] initWithSession:session];
}

- (void)configure
{
    [self createTaskHeaderView];
    
    TasksAndAttachmentsViewController *attachmentViewController = nil;
    
    if (self.isDisplayingTask)
    {
        /**
         * Task-oriented view
         */
        
        [self.workflowService retrieveProcessWithIdentifier:self.task.processIdentifier completionBlock:^(AlfrescoWorkflowProcess *process, NSError *error) {
            if (process && self.taskHeaderView)
            {
                self.taskHeaderView.taskInitiator = process.initiatorUsername;
            }
            else
            {
                displayErrorMessage([ErrorDescriptions descriptionForError:error]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
        
        // configure the header view for the task
        [self.taskHeaderView configureViewForTask:self.task];
        
        // configure the transition buttons
        [self configureTransitionButtonsForTask:self.task];
        
        // init the attachment controller
        attachmentViewController = [[TasksAndAttachmentsViewController alloc] initWithTask:self.task session:self.session];
        
        // set the tableview inset to ensure the content isn't behind the comment view
        attachmentViewController.tableViewInsets = UIEdgeInsetsMake(0, 0, self.textViewContainerHeightConstraint.constant, 0);
    }
    else
    {
        /**
         * Process-oriented view
         */

        // configure the header view for the process
        [self.taskHeaderView configureViewForProcess:self.process];
        
        // init the attachment controller
        attachmentViewController = [[TasksAndAttachmentsViewController alloc] initWithProcess:self.process session:self.session];
        
        // hide the comment view
        self.textViewContainerHeightConstraint.constant = 0;
    }
    
    // add the attachment controller
    [self addChildViewController:attachmentViewController];
    attachmentViewController.view.translatesAutoresizingMaskIntoConstraints = NO;
    [self.detailsContainerView addSubview:attachmentViewController.view];
    [attachmentViewController didMoveToParentViewController:self];
    
    // setup the constraints to the container view
    NSDictionary *views = @{@"childView" : attachmentViewController.view};
    NSArray *verticalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[childView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    [self.detailsContainerView addConstraints:verticalConstraints];
    [self.detailsContainerView addConstraints:horizontalConstraints];
    
    // setup the comments text view
    self.textView.maximumHeight = kMaxCommentTextViewHeight;
    self.textView.layer.cornerRadius = 4.0f;
    self.textView.layer.borderColor = [[UIColor borderGreyColor] CGColor];
    self.textView.layer.borderWidth = 1;
}

- (void)configureTransitionButtonsForTask:(AlfrescoWorkflowTask *)task
{
    if ([self shouldDisplayApproveAndRejectButtonsForTask:task])
    {
        self.doneButton.hidden = YES;
        [Utility createBorderedButton:self.approveButton label:NSLocalizedString(@"task.transition.approve", @"Approve") color:[UIColor taskTransitionApproveColor]];
        [Utility createBorderedButton:self.rejectButton label:NSLocalizedString(@"task.transition.reject", @"Reject") color:[UIColor taskTransitionRejectColor]];
    }
    else
    {
        self.approveButton.hidden = YES;
        self.rejectButton.hidden = YES;
        [Utility createBorderedButton:self.doneButton label:NSLocalizedString(@"task.transition.done", @"Done") color:[UIColor taskTransitionApproveColor]];

        // Bump the priority of this constraint to tie the text box to the Done button (iPad layout only)
        self.horizontalSpaceFromDoneButtonToCommentTextConstraint.priority = kHighPriority;
    }

    [self.view layoutIfNeeded];
}

- (BOOL)isAnInvitePendingTask:(AlfrescoWorkflowTask *)task
{
    return [task.type isEqualToString:kActivitiInvitePendingTask] || [task.type isEqualToString:kJBPMInvitePendingTask];
}

- (BOOL)isAnInviteAcceptedOrRejectedTask:(AlfrescoWorkflowTask *)task
{
    BOOL isInvitedAcceptedTask = [task.type isEqualToString:kActivitiInviteAcceptedTask] || [task.type isEqualToString:kJBPMInviteAcceptedTask];
    BOOL isInviteRejectedTask = [task.type isEqualToString:kActivitiInviteRejectedTask] || [task.type isEqualToString:kJBPMInviteRejectedTask];
    
    return isInvitedAcceptedTask || isInviteRejectedTask;
}

- (BOOL)isAReviewTask:(AlfrescoWorkflowTask *)task
{
    return [task.type isEqualToString:kJBPMReviewTask] || [task.type isEqualToString:kActivitiReviewTask];
}

- (BOOL)shouldDisplayApproveAndRejectButtonsForTask:(AlfrescoWorkflowTask *)task
{
    // Require approve and reject buttons for review or invite tasks
    BOOL isReviewTask = [self isAReviewTask:task];
    BOOL isInvitePendingTask = [self isAnInvitePendingTask:task];
    
    return isReviewTask || isInvitePendingTask;
}

- (void)keyboardWillshowAnimated:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    NSNumber *animationSpeed = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    CGRect keyboardRectForScreen = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGRect keyboardRectForView = [self.view convertRect:keyboardRectForScreen fromView:self.view.window];

    CGSize kbSize = keyboardRectForView.size;
    
    [UIView animateWithDuration:animationSpeed.doubleValue delay:0.0f options:animationCurve.unsignedIntegerValue animations:^{
        self.bottomSpacingOfTextViewContainerConstraint.constant = kbSize.height;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Shrink the comment text view to make room for the cancel button (iPhone only)
        self.trailingSpaceFromCommentTextToContainerConstraint.priority = kLowPriority;
        self.cancelButton.hidden = NO;
        [self.view layoutIfNeeded];
    }];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    NSNumber *animationSpeed = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:animationSpeed.doubleValue delay:0.0f options:animationCurve.unsignedIntegerValue animations:^{
        self.bottomSpacingOfTextViewContainerConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:^(BOOL finished) {
        // Allow the comment text view to stretch to the container width (iPhone only)
        self.trailingSpaceFromCommentTextToContainerConstraint.priority = kHighPriority;
        self.cancelButton.hidden = YES;
        [self.view layoutIfNeeded];
    }];
}

- (void)createTaskHeaderView
{
    TaskHeaderView *taskHeaderView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TaskHeaderView class]) owner:self options:nil] lastObject];
    [self.taskHeaderViewContainer addSubview:taskHeaderView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(taskHeaderView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    NSArray *verticalContraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    
    [self.taskHeaderViewContainer addConstraints:horizontalConstraints];
    [self.taskHeaderViewContainer addConstraints:verticalContraints];
    self.taskHeaderView = taskHeaderView;
}

- (void)completeTaskWithProperties:(NSDictionary *)properties
{
    __block MBProgressHUD *completingProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:completingProgressHUD];
    [completingProgressHUD showAnimated:YES];
    
    [self enableActionButtons:NO];
    [self.textView resignFirstResponder];
    
    __weak typeof(self) weakSelf = self;
    [self.workflowService completeTask:self.task variables:properties completionBlock:^(AlfrescoWorkflowTask *task, NSError *error) {
        [completingProgressHUD hideAnimated:YES];
        completingProgressHUD = nil;
        [weakSelf enableActionButtons:YES];
        
        if (error)
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.workflow.unable.to.complete.process", @"Unable To Complete Task Process"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
            [weakSelf.textView becomeFirstResponder];
        }
        else
        {
            displayInformationMessage(NSLocalizedString(@"task.completed.success.message", @"Task completed"));
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoWorkflowTaskListDidChangeNotification object:task];
            [UniversalDevice clearDetailViewController];
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryBPM
                                                              action:kAnalyticsEventActionComplete
                                                               label:weakSelf.task.type
                                                               value:@1];
        }
    }];
}

- (void)didTapView:(UITapGestureRecognizer *)gesture
{
    [self.textView resignFirstResponder];
}

- (void)enableActionButtons:(BOOL)enabled
{
    self.doneButton.enabled = enabled;
    self.approveButton.enabled = enabled;
    self.rejectButton.enabled = enabled;
}

- (void)cancelCommentAction:(id)sender
{
    self.textView.text = @"";
    [self.view endEditing:YES];
}

- (void)pressedReassignButton:(id)sender
{
    PeoplePicker *peoplePicker = [[PeoplePicker alloc] initWithSession:self.session navigationController:self.navigationController delegate:self];
    peoplePicker.shouldSuppressAutoCloseWhenDone = YES;
    [peoplePicker startWithPeople:nil mode:PeoplePickerModeSingleSelectManualConfirm modally:YES];
    self.peoplePicker = peoplePicker;
}

#pragma mark - IBActions

- (IBAction)pressedDoneButton:(id)sender
{
    NSDictionary *properties = nil;
    
    if (self.textView.hasText)
    {
        properties = [NSDictionary dictionaryWithObject:self.textView.text forKey:kAlfrescoWorkflowVariableTaskComment];
    }
    
    [self completeTaskWithProperties:properties];
}

- (IBAction)pressedApproveButton:(id)sender
{
    NSMutableDictionary *properties = nil;
    if ([self isAnInvitePendingTask:self.task])
    {
        properties = [@{kAlfrescoWorkflowVariableTaskInvitePendingOutcome : [kAlfrescoWorkflowTaskTransitionAccept lowercaseString]} mutableCopy];
    }
    else
    {
        properties = [@{kAlfrescoWorkflowVariableTaskReviewOutcome : kAlfrescoWorkflowTaskTransitionApprove} mutableCopy];
    }
    
    if ([WorkflowHelper isJBPMTask:self.task])
    {
        // JBPM tasks need to have the transitions property set appropriately
        properties[kAlfrescoWorkflowVariableTaskTransition] = [kAlfrescoWorkflowTaskTransitionApprove lowercaseString];
    }
    
    if (self.textView.hasText)
    {
        properties[kAlfrescoWorkflowVariableTaskComment] = self.textView.text;
    }
    
    [self completeTaskWithProperties:properties];
}

- (IBAction)pressedRejectButton:(id)sender
{
    NSMutableDictionary *properties = nil;
    if ([self isAnInvitePendingTask:self.task])
    {
        properties = [@{kAlfrescoWorkflowVariableTaskInvitePendingOutcome : [kAlfrescoWorkflowTaskTransitionReject lowercaseString]} mutableCopy];
    }
    else
    {
        properties = [@{kAlfrescoWorkflowVariableTaskReviewOutcome : kAlfrescoWorkflowTaskTransitionReject} mutableCopy];
    }
    
    if ([WorkflowHelper isJBPMTask:self.task])
    {
        // JBPM tasks need to have the transitions property set appropriately
        properties[kAlfrescoWorkflowVariableTaskTransition] = [kAlfrescoWorkflowTaskTransitionReject lowercaseString];
    }
    
    if (self.textView.hasText)
    {
        properties[kAlfrescoWorkflowVariableTaskComment] = self.textView.text;
    }
    
    [self completeTaskWithProperties:properties];
}

#pragma mark - TextViewDelegate Functions

- (void)textViewHeightDidChange:(TextView *)textView
{
    [self.view sizeToFit];
}

#pragma mark - UIGestureRecognizerDelegate Functions

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldRecieveTouch = YES;
    
    if ([touch.view isDescendantOfView:self.detailsContainerView])
    {
        shouldRecieveTouch = NO;
    }
    
    return shouldRecieveTouch;
}

#pragma mark - PeoplePickerDelegate Functions

- (void)peoplePicker:(PeoplePicker *)peoplePicker didSelectPeople:(NSArray *)selectedPeople
{
    if (self.task)
    {
        if (selectedPeople.count > 0)
        {
            AlfrescoPerson *reassignee = selectedPeople[0];
            
            [self enableActionButtons:NO];
            __weak typeof(self) weakSelf = self;
            [self.workflowService reassignTask:self.task toAssignee:reassignee completionBlock:^(AlfrescoWorkflowTask *task, NSError *error) {
                if (error)
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.workflow.unable.to.reassign.task", @"Unable to reassign task"), [ErrorDescriptions descriptionForError:error]]);
                    [Notifier notifyWithAlfrescoError:error];
                }
                else
                {
                    [peoplePicker cancelWithCompletionBlock:^(PeoplePicker *peoplePicker) {
                        displayInformationMessage(NSLocalizedString(@"task.reassign.success.message", @"Task reassigned"));
                    }];
                    [weakSelf enableActionButtons:YES];
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoWorkflowTaskListDidChangeNotification object:task];
                    [UniversalDevice clearDetailViewController];
                    
                    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryBPM
                                                                      action:kAnalyticsEventActionReassign
                                                                       label:weakSelf.task.type
                                                                       value:@1];
                }
            }];
        }
    }
    else
    {
        // MOBILE-2990: It appears the task can be set to nil in some circumstances, inform the user the reassign failed.
        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.workflow.unable.to.reassign.task", @"Unable to reassign task"),
                             NSLocalizedString(@"error.generic.title", @"An error occurred")]);
    }
}

@end
