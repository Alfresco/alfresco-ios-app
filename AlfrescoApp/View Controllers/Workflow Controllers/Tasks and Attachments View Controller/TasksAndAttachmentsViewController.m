//
//  WorkflowAttachmentsViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 05/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "TasksAndAttachmentsViewController.h"
#import "SyncManager.h"
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "Utility.h"
#import "DocumentPreviewViewController.h"
#import "TableviewUnderlinedHeaderView.h"

#import "AvatarManager.h"
#import "AlfrescoNodeCell.h"
#import "ProcessTasksCell.h"

static NSString * const kStartTaskRemovalPredicateFormat = @"NOT SELF.identifier CONTAINS '$start'";

@interface TasksAndAttachmentsViewController ()

// Services
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;
// Data Models
@property (nonatomic, strong) AlfrescoWorkflowProcess *process;
@property (nonatomic, strong) AlfrescoWorkflowTask *task;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, assign) TaskFilter taskType;
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSMutableArray *attachments;

@end

@implementation TasksAndAttachmentsViewController

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session
{
    self = [self initWithTaskFilter:TaskFilterTask session:session];
    if (self)
    {
        self.task = task;
    }
    return self;
}

- (instancetype)initWithProcess:(AlfrescoWorkflowProcess *)process session:(id<AlfrescoSession>)session
{
    self = [self initWithTaskFilter:TaskFilterProcess session:session];
    if (self)
    {
        self.process = process;
    }
    return self;
}

- (instancetype)initWithTaskFilter:(TaskFilter)taskType session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.session = session;
        self.taskType = taskType;
        self.attachments = [NSMutableArray array];
        self.tasks = [NSMutableArray array];
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
    
    [self disablePullToRefresh];
    
    if (self.session)
    {
        [self populateTableView];
    }
    
    // register cells
    UINib *attachmentCellNib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
    [self.tableView registerNib:attachmentCellNib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
    
    UINib *processTaskCellNib = [UINib nibWithNibName:NSStringFromClass([ProcessTasksCell class]) bundle:nil];
    [self.tableView registerNib:processTaskCellNib forCellReuseIdentifier:[ProcessTasksCell cellIdentifier]];
}

#pragma mark - Custom Setters

- (void)setTableViewInsets:(UIEdgeInsets)tableViewInsets
{
    _tableViewInsets = tableViewInsets;
    
    self.tableView.contentInset = tableViewInsets;
}

#pragma mark - Private Functions

- (void)populateTableView
{
    __weak typeof(self) weakSelf = self;
    
    [self showHUD];
    [self loadAttachmentsWithCompletionBlock:^(NSArray *array, NSError *error) {
        [weakSelf hideHUD];
        if (array && array.count > 0)
        {
            [weakSelf.attachments removeAllObjects];
            [weakSelf.attachments addObjectsFromArray:array];
            NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[weakSelf sectionForArray:weakSelf.attachments]];
            [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    if (self.taskType == TaskFilterProcess)
    {
        [self loadTasksWithCompletionBlock:^(NSArray *array, NSError *error) {
            [weakSelf hideHUD];
            if (array)
            {
                [weakSelf.tasks removeAllObjects];
                NSPredicate *filteredArrayPredicate = [NSPredicate predicateWithFormat:kStartTaskRemovalPredicateFormat];
                NSArray *filteredTasks = [array filteredArrayUsingPredicate:filteredArrayPredicate];
                [weakSelf.tasks addObjectsFromArray:filteredTasks];
                NSIndexSet *indexSet = [NSIndexSet indexSetWithIndex:[weakSelf sectionForArray:weakSelf.tasks]];
                [weakSelf.tableView reloadSections:indexSet withRowAnimation:UITableViewRowAnimationAutomatic];
            }
        }];
    }
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
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
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
}

- (void)loadAttachmentsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    if (self.taskType == TaskFilterTask)
    {
        [self.workflowService retrieveAttachmentsForTask:self.task completionBlock:completionBlock];
    }
    else if (self.taskType == TaskFilterProcess)
    {
        [self.workflowService retrieveAttachmentsForProcess:self.process completionBlock:completionBlock];
    }
}

- (void)loadTasksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    if (self.taskType == TaskFilterProcess)
    {
        [self.workflowService retrieveTasksForProcess:self.process completionBlock:completionBlock];
    }
}

- (NSArray *)currentArrayForSection:(NSUInteger)section
{
    NSArray *currentArray = nil;
    
    if (self.taskType == TaskFilterTask)
    {
        currentArray = self.attachments;
    }
    else
    {
        switch (section)
        {
            case 0:
                currentArray = self.tasks;
                break;
                
            case 1:
                currentArray = self.attachments;
                break;
        }
    }
    
    return currentArray;
}

- (NSUInteger)sectionForArray:(NSArray *)array
{
    NSUInteger section = 0;
    
    if (array == self.tasks)
    {
        section = 0;
    }
    else if (array == self.attachments)
    {
        if (self.taskType == TaskFilterTask)
        {
            section = 0;
        }
        else if (self.taskType == TaskFilterProcess)
        {
            section = 1;
        }
    }
    
    return section;
}

#pragma mark - Table view data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return [TableviewUnderlinedHeaderView headerViewHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableviewUnderlinedHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TableviewUnderlinedHeaderView class]) owner:self options:nil] lastObject];
    headerView.headerTitleTextLabel.textColor = [UIColor appTintColor];
    
    NSArray *currentArray = [self currentArrayForSection:section];
    
    NSString *headerTitleText = nil;
    if (currentArray == self.attachments)
    {
        headerTitleText = NSLocalizedString(@"task.details.section.header.attachments", @"Attachments Section Header");
    }
    else if (currentArray == self.tasks)
    {
        headerTitleText = NSLocalizedString(@"task.details.section.header.tasks", @"Tasks Section Header");
    }
    
    headerView.headerTitleTextLabel.text = [headerTitleText uppercaseString];
    
    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return (self.taskType == TaskFilterTask) ? 1 : 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *currentArray = [self currentArrayForSection:section];
    NSInteger numberOfRows = currentArray.count;
    
    if (currentArray.count == 0)
    {
        numberOfRows = 1;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    NSArray *currentArray = [self currentArrayForSection:indexPath.section];
    
    if (currentArray == self.attachments)
    {
        AlfrescoNodeCell *attachmentCell = [tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier]];
        
        if (currentArray.count > 0)
        {
            AlfrescoNode *currentNode = currentArray[indexPath.row];
            
            SyncManager *syncManager = [SyncManager sharedManager];
            FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
            
            BOOL isSyncNode = [syncManager isNodeInSyncList:currentNode];
            SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:currentNode.identifier];
            [attachmentCell updateCellInfoWithNode:currentNode nodeStatus:nodeStatus];
            [attachmentCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:NO animate:NO];
            
            [favoriteManager isNodeFavorite:currentNode session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
                [attachmentCell updateStatusIconsIsSyncNode:isSyncNode isFavoriteNode:isFavorite animate:NO];
            }];
            
            AlfrescoDocument *documentNode = (AlfrescoDocument *)currentNode;
            
            UIImage *thumbnail = [[ThumbnailManager sharedManager] thumbnailForDocument:documentNode renditionType:kRenditionImageDocLib];
            if (thumbnail)
            {
                [attachmentCell.image setImage:thumbnail withFade:NO];
            }
            else
            {
                UIImage *placeholderImage = smallImageForType([documentNode.name pathExtension]);
                attachmentCell.image.image = placeholderImage;
                [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                    if (image)
                    {
                        [attachmentCell.image setImage:image withFade:YES];
                    }
                }];
            }
        }
        else
        {
            attachmentCell.textLabel.text = NSLocalizedString(@"tasks.attachments.empty", @"No Attachments");
            attachmentCell.textLabel.textAlignment = NSTextAlignmentCenter;
            attachmentCell.textLabel.font = [UIFont systemFontOfSize:kNoItemsLabelFontSize];
            attachmentCell.textLabel.textColor = [UIColor noItemsTextColor];
            attachmentCell.selectionStyle = UITableViewCellSelectionStyleNone;
        }
        
        cell = attachmentCell;
    }
    else
    {
        ProcessTasksCell *processTasksCell = [tableView dequeueReusableCellWithIdentifier:[ProcessTasksCell cellIdentifier]];
        
        if (currentArray.count > 0)
        {
            AlfrescoWorkflowTask *currentTask = currentArray[indexPath.row];
            
            UIImage *avatar = [[AvatarManager sharedManager] avatarForIdentifier:currentTask.assigneeIdentifier];
            if (avatar)
            {
                [processTasksCell.avatarImageView setImage:avatar withFade:NO];
            }
            else
            {
                UIImage *placeholderImage = [UIImage imageNamed:@"avatar.png"];
                processTasksCell.avatarImageView.image = placeholderImage;
                [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:currentTask.assigneeIdentifier session:self.session completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
                    if (avatarImage)
                    {
                        [processTasksCell.avatarImageView setImage:avatarImage withFade:YES];
                    }
                }];
            }
            
            [processTasksCell updateStatusLabelUsingTask:currentTask];
        }
        else
        {
            processTasksCell.textLabel.text = NSLocalizedString(@"tasks.tasks.empty", @"No Tasks");
            processTasksCell.textLabel.textAlignment = NSTextAlignmentCenter;
            processTasksCell.textLabel.font = [UIFont boldSystemFontOfSize:kNoItemsLabelFontSize];
            processTasksCell.textLabel.textColor = [UIColor noItemsTextColor];
        }
        
        processTasksCell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        cell = processTasksCell;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *currentArray = [self currentArrayForSection:indexPath.section];
    
    UITableViewCell *cell = nil;
    
    if (currentArray == self.attachments)
    {
        cell = (AlfrescoNodeCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    else if (currentArray == self.tasks)
    {
        cell = (ProcessTasksCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    }
    
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    return height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *currentArray = [self currentArrayForSection:indexPath.section];
    
    if (currentArray == self.attachments && currentArray.count > 0)
    {
        AlfrescoDocument *selectedDocument = [currentArray objectAtIndex:indexPath.row];
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
}

@end
