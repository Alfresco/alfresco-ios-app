//
//  TaskDetailsViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TaskDetailsViewController.h"
#import "TaskHeaderView.h"
#import "MBProgressHUD.h"
#import "PagedScrollView.h"
#import "ThumbnailDownloader.h"
#import "Utility.h"
#import "AlfrescoNodeCell.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "DocumentPreviewViewController.h"
#import "Utility.h"
#import "ErrorDescriptions.h"
#import "TextView.h"
#import "UIColor+Custom.h"

static CGFloat const kMaxCommentTextViewHeight = 60.0f;

typedef NS_ENUM(NSUInteger, TaskType)
{
    TaskTypeTask = 0,
    TaskTypeWorkflow
};

@interface TaskDetailsViewController () <TextViewDelegate, UIGestureRecognizerDelegate>

//// Layout Constraints ////
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *pagingSegmentControlContainerHeightConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *bottomSpacingOfTextViewContainerConstraint;

//// Data Models ////
// Models
@property (nonatomic, strong) AlfrescoWorkflowTask *task;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, assign) TaskType taskType;
@property (nonatomic, strong) NSArray *attachmentNodes;
// Services
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoWorkflowTaskService *taskService;
@property (nonatomic, strong) AlfrescoWorkflowProcessDefinitionService *processDefinitionService;

//// Views ////
// Header
@property (nonatomic, weak) TaskHeaderView *taskHeaderView;
@property (nonatomic, weak) IBOutlet UIView *taskHeaderViewContainer;
// Paging Segment
@property (nonatomic, weak) IBOutlet UIView *pagingSegmentControlContainer;
@property (nonatomic, weak) IBOutlet UISegmentedControl *pagingSegmentControl;
// Paging
@property (nonatomic, weak) IBOutlet PagedScrollView *pagedScrollView;
// Attachments
@property (nonatomic, weak) IBOutlet UIView *attachmentContainerView;
@property (nonatomic, weak) IBOutlet UILabel *noAttachmentLabel;
@property (nonatomic, weak) IBOutlet UITableView *attachmentsTableView;
// Comments
@property (nonatomic, weak) IBOutlet TextView *textView;
@property (nonatomic, weak) IBOutlet UIButton *approveButton;
@property (nonatomic, weak) IBOutlet UIButton *declineButton;
// Other
@property (nonatomic, strong) MBProgressHUD *progressHUD;

@end

@implementation TaskDetailsViewController

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.task = task;
        self.session = session;
        self.taskType = TaskTypeTask;
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
    
    if (self.taskType == TaskTypeTask)
    {
        self.title = self.task.name;
        self.pagingSegmentControlContainerHeightConstraint.constant = 0;
        [self.pagedScrollView addSubview:self.attachmentContainerView];
        [self retrieveProcessDefinitionNameForIdentifier:self.task.processDefinitionIdentifier];
    }
    else
    {
        
    }
    
    if (self.session)
    {
        [self showHUD];
        [self loadAttachmentsWithCompletionBlock:^(NSArray *array, NSError *error) {
            [self hideHUD];
            if (array && array.count > 0)
            {
                self.attachmentsTableView.hidden = NO;
                self.attachmentNodes = array;
                [self.attachmentsTableView reloadData];
            }
        }];
    }
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
    [self.attachmentsTableView registerNib:nib forCellReuseIdentifier:kAlfrescoNodeCellIdentifier];
    
    [self createTaskHeaderView];
    
    self.textView.maximumHeight = kMaxCommentTextViewHeight;
    self.textView.layer.cornerRadius = 5.0f;
    self.textView.layer.borderColor = [[UIColor lineSeparatorColor] CGColor];
    self.textView.layer.borderWidth = 0.5f;
    self.textView.font = [UIFont systemFontOfSize:12.0f];
    
    [self localiseUI];
    
    // tap gesture
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(didTapView:)];
    tapGesture.delegate = self;
    [self.view addGestureRecognizer:tapGesture];
}

#pragma mark - Private Functions

- (void)localiseUI
{
    self.textView.placeholderText = @"Add comment here - localise me";
    self.noAttachmentLabel.text = @"No Attachments - Localise me";
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
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
    self.taskService = [[AlfrescoWorkflowTaskService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.processDefinitionService = [[AlfrescoWorkflowProcessDefinitionService alloc] initWithSession:session];
}

- (void)keyboardWillShow:(NSNotification *)notification
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
    } completion:nil];
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    NSDictionary *info = [notification userInfo];
    
    NSNumber *animationSpeed = [info objectForKey:UIKeyboardAnimationDurationUserInfoKey];
    NSNumber *animationCurve = [info objectForKey:UIKeyboardAnimationCurveUserInfoKey];
    
    [UIView animateWithDuration:animationSpeed.doubleValue delay:0.0f options:animationCurve.unsignedIntegerValue animations:^{
        self.bottomSpacingOfTextViewContainerConstraint.constant = 0;
        [self.view layoutIfNeeded];
    } completion:nil];
}

- (void)showHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        [self.progressHUD show:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hide:YES];
    });
}

- (void)createTaskHeaderView
{
    TaskHeaderView *taskHeaderView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TaskHeaderView class]) owner:self options:nil] lastObject];
    [taskHeaderView configureViewForTask:self.task];
    [self.taskHeaderViewContainer addSubview:taskHeaderView];
    
    NSDictionary *views = NSDictionaryOfVariableBindings(taskHeaderView);
    NSArray *horizontalConstraints = [NSLayoutConstraint constraintsWithVisualFormat:@"|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    NSArray *verticalContraints = [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[taskHeaderView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views];
    
    [self.taskHeaderViewContainer addConstraints:horizontalConstraints];
    [self.taskHeaderViewContainer addConstraints:verticalContraints];
    self.taskHeaderView = taskHeaderView;
}

- (void)retrieveProcessDefinitionNameForIdentifier:(NSString *)identifier
{
    [self.processDefinitionService retrieveProcessDefinitionWithIdentifier:identifier completionBlock:^(AlfrescoWorkflowProcessDefinition *processDefinition, NSError *error) {
        if (processDefinition)
        {
            [self.taskHeaderView updateTaskTypeLabelToString:processDefinition.name];
        }
    }];
}

- (void)loadAttachmentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    if (self.taskType == TaskTypeTask)
    {
        [self.taskService retrieveAttachmentsForTask:self.task completionBlock:completionBlock];
    }
    else if (self.taskType == TaskTypeWorkflow)
    {
        // TODO
    }
}

- (void)completeTaskWithProperties:(NSDictionary *)properties
{
    __block MBProgressHUD *completingProgressHUD = [[MBProgressHUD alloc] initWithView:self.view];
    [self.view addSubview:completingProgressHUD];
    [completingProgressHUD show:YES];
    
    self.approveButton.enabled = NO;
    self.declineButton.enabled = NO;
    [self.textView resignFirstResponder];
    
    __weak typeof(self) weakSelf = self;
    [self.taskService completeTask:self.task properties:properties completionBlock:^(AlfrescoWorkflowTask *task, NSError *error) {
        [completingProgressHUD hide:YES];
        completingProgressHUD = nil;
        weakSelf.approveButton.enabled = YES;
        weakSelf.declineButton.enabled = YES;
        
        if (error)
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.add.comment.failed", @"Adding Comment Failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
            [weakSelf.textView becomeFirstResponder];
        }
        else
        {
            weakSelf.textView.text = @"Add comment here - localise me";
            // TODO
        }
    }];
}

- (void)didTapView:(UITapGestureRecognizer *)gesture
{
    [self.textView resignFirstResponder];
}

#pragma mark - IBActions

- (IBAction)pressedApproveButton:(id)sender
{
    NSMutableDictionary *properties = [@{kAlfrescoTaskReviewOutcome : kAlfrescoTaskApprove} mutableCopy];
    
    if (self.textView.hasText)
    {
        [properties setObject:self.textView.text forKey:kAlfrescoTaskComment];
    }
    
    [self completeTaskWithProperties:properties];
}

- (IBAction)pressedRejectButton:(id)sender
{
    NSMutableDictionary *properties = [@{kAlfrescoTaskReviewOutcome : kAlfrescoTaskReject} mutableCopy];
    
    if (self.textView.hasText)
    {
        [properties setObject:self.textView.text forKey:kAlfrescoTaskComment];
    }
    
    [self completeTaskWithProperties:properties];
}

#pragma mark - PagedScrollViewDelegate Functions

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging
{
    if (dragging)
    {
        [self.pagingSegmentControl setSelectedSegmentIndex:viewIndex];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.attachmentNodes.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = [self.attachmentsTableView dequeueReusableCellWithIdentifier:kAlfrescoNodeCellIdentifier];
    
    AlfrescoNode *currentNode = [self.attachmentNodes objectAtIndex:indexPath.row];
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    BOOL isSyncNode = [syncManager isNodeInSyncList:currentNode];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
    [cell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus];
    [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
    
    [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [cell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
    }];
    
    if ([currentNode isKindOfClass:[AlfrescoFolder class]])
    {
        cell.image.image = smallImageForType(@"folder");
    }
    else
    {
        AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
        
        UIImage *thumbnail = [[ThumbnailDownloader sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
        if (thumbnail)
        {
            [cell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            UIImage *placeholderImage = smallImageForType([documentNode.name pathExtension]);
            cell.image.image = placeholderImage;
            [[ThumbnailDownloader sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    [cell.image setImage:image withFade:YES];
                }
            }];
        }
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *cell = (AlfrescoNodeCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    AlfrescoDocument *selectedDocument = [self.attachmentNodes objectAtIndex:indexPath.row];
    [self.documentService retrievePermissionsOfNode:selectedDocument completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (permissions)
        {
            DocumentPreviewViewController *documentPreviewController = [[DocumentPreviewViewController alloc] initWithAlfrescoDocument:selectedDocument permissions:permissions contentFilePath:nil documentLocation:InAppDocumentLocationFilesAndFolders session:self.session];
            [self.navigationController pushViewController:documentPreviewController animated:YES];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission failed to be retrieved"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

#pragma mark - TextViewDelegate Functions

- (void)textViewHeightDidChange:(TextView *)textView
{
    [self.view sizeToFit];
}

#pragma mark UIGestureRecognizerDelegate methods

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch
{
    BOOL shouldRecognise = YES;
    
    if ([touch.view isDescendantOfView:self.attachmentsTableView])
    {
        shouldRecognise = NO;
    }
    
    return shouldRecognise;
}

@end
