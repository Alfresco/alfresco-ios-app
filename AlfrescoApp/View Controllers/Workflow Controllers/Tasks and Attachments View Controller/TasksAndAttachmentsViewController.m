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
 
#import "TasksAndAttachmentsViewController.h"
#import "SyncManager.h"
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "DocumentPreviewViewController.h"
#import "TableviewUnderlinedHeaderView.h"
#import "AvatarManager.h"
#import "AttributedLabelCell.h"
#import "AlfrescoNodeCell.h"
#import "ProcessTasksCell.h"

static NSString * const kStartTaskRemovalPredicateFormat = @"NOT SELF.identifier CONTAINS '$start'";
static NSString * const kNoAttachmentsCellIdentifier = @"NoAttachmentsCellIdentifier";

typedef NS_ENUM(NSUInteger, TableSections)
{
    TableSectionDetails,
    TableSectionTasks,
    TableSectionAttachments,
    TableSections_MAX
};

@interface TasksAndAttachmentsViewController ()

// Services
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoWorkflowService *workflowService;
// Data Models
@property (nonatomic, strong) AlfrescoWorkflowProcess *process;
@property (nonatomic, strong) AlfrescoWorkflowTask *task;
@property (nonatomic, assign, getter=isDisplayingTask) BOOL displayingTask;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSMutableArray *tasks;
@property (nonatomic, strong) NSMutableArray *attachments;

@end

@implementation TasksAndAttachmentsViewController

@dynamic session;

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
    self = [super initWithSession:session];
    if (self)
    {
        self.session = session;
        self.attachments = [NSMutableArray array];
        self.tasks = [NSMutableArray array];
        [self createServicesWithSession:session];
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
    
    self.allowsPullToRefresh = NO;
    
    if (self.session)
    {
        [self populateTableView];
    }
    
    // Register cells
    UINib *detailCellNib = [UINib nibWithNibName:@"AttributedLabelCell" bundle:nil];
    [self.tableView registerNib:detailCellNib forCellReuseIdentifier:[AttributedLabelCell cellIdentifier]];
    
    UINib *attachmentCellNib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:attachmentCellNib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];

    UINib *noAttachmentsCellNib = [UINib nibWithNibName:@"AttributedLabelCell" bundle:nil];
    [self.tableView registerNib:noAttachmentsCellNib forCellReuseIdentifier:kNoAttachmentsCellIdentifier];

    UINib *processTaskCellNib = [UINib nibWithNibName:@"ProcessTasksCell" bundle:nil];
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
    
    [self loadAttachmentsWithCompletionBlock:^(NSArray *array, NSError *error) {
        if (array && array.count > 0)
        {
            weakSelf.attachments = [array mutableCopy];
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:TableSectionAttachments] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
    
    [self loadTasksWithCompletionBlock:^(NSArray *array, NSError *error) {
        if (array)
        {
            NSPredicate *filteredArrayPredicate = [NSPredicate predicateWithFormat:kStartTaskRemovalPredicateFormat];
            weakSelf.tasks = [[array filteredArrayUsingPredicate:filteredArrayPredicate] mutableCopy];
            [weakSelf.tableView reloadSections:[NSIndexSet indexSetWithIndex:TableSectionTasks] withRowAnimation:UITableViewRowAnimationAutomatic];
        }
    }];
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
    if (self.isDisplayingTask)
    {
        [self.workflowService retrieveAttachmentsForTask:self.task completionBlock:completionBlock];
    }
    else
    {
        [self.workflowService retrieveAttachmentsForProcess:self.process completionBlock:completionBlock];
    }
}

- (void)loadTasksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    if (!self.isDisplayingTask)
    {
        [self.workflowService retrieveTasksForProcess:self.process completionBlock:completionBlock];
    }
}

#pragma mark - UITableView data source

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (self.isDisplayingTask && section == TableSectionTasks)
    {
        return 0;
    }
    return [TableviewUnderlinedHeaderView headerViewHeight];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    TableviewUnderlinedHeaderView *headerView = [[[NSBundle mainBundle] loadNibNamed:@"TableviewUnderlinedHeaderView" owner:self options:nil] lastObject];
    headerView.headerTitleTextLabel.textColor = [UIColor appTintColor];
    
    NSString *headerTitleText = nil;
    switch (section)
    {
        case TableSectionDetails:
            headerTitleText = NSLocalizedString(@"task.details.section.header.details", @"Details Section Header");
            break;
        
        case TableSectionTasks:
            headerTitleText = NSLocalizedString(@"task.details.section.header.tasks", @"Tasks Section Header");
            break;
        
        case TableSectionAttachments:
            headerTitleText = NSLocalizedString(@"task.details.section.header.attachments", @"Attachments Section Header");
            break;
            
        default:
            break;
    }
    
    headerView.headerTitleTextLabel.text = [headerTitleText uppercaseString];
    return headerView;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return TableSections_MAX;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger numberOfRows = 1;

    switch (section)
    {
        case TableSectionTasks:
            numberOfRows = self.isDisplayingTask ? 0 : MAX(1, self.tasks.count);
            break;
            
        case TableSectionAttachments:
            numberOfRows = MAX(1, self.attachments.count);
            break;
            
        default:
            break;
    }
    
    return numberOfRows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = nil;
    
    switch (indexPath.section)
    {
        case TableSectionDetails:
        {
            AttributedLabelCell *detailCell = [tableView dequeueReusableCellWithIdentifier:[AttributedLabelCell cellIdentifier]];
            detailCell.attributedLabel.text = self.isDisplayingTask ? self.task.summary : self.process.summary;
            detailCell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell = detailCell;
        }
            break;
            
        case TableSectionTasks:
        {
            ProcessTasksCell *processTasksCell = [tableView dequeueReusableCellWithIdentifier:[ProcessTasksCell cellIdentifier]];
            
            if (self.tasks.count > 0)
            {
                AlfrescoWorkflowTask *currentTask = self.tasks[indexPath.row];
                
                AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:currentTask.assigneeIdentifier session:self.session];
                [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
                    [processTasksCell.avatarImageView setImage:avatarImage withFade:YES];
                }];
                
                [processTasksCell updateStatusLabelUsingTask:currentTask];
            }
            else
            {
                processTasksCell.textLabel.text = NSLocalizedString(@"tasks.tasks.empty", @"No Tasks");
                processTasksCell.textLabel.textAlignment = NSTextAlignmentCenter;
                processTasksCell.textLabel.font = [UIFont boldSystemFontOfSize:kEmptyListLabelFontSize];
                processTasksCell.textLabel.textColor = [UIColor noItemsTextColor];
            }
            
            processTasksCell.selectionStyle = UITableViewCellSelectionStyleNone;
            cell = processTasksCell;
        }
            break;
            
        case TableSectionAttachments:
        {
            if (self.attachments.count > 0)
            {
                AlfrescoNodeCell *attachmentCell = [tableView dequeueReusableCellWithIdentifier:[AlfrescoNodeCell cellIdentifier]];
                AlfrescoNode *currentNode = self.attachments[indexPath.row];

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
                    [attachmentCell.image setImage:smallImageForType([documentNode.name pathExtension]) withFade:NO];
                    [[ThumbnailManager sharedManager] retrieveImageForDocument:documentNode renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                        if (image)
                        {
                            AlfrescoNodeCell *updateCell = (AlfrescoNodeCell *)[tableView cellForRowAtIndexPath:indexPath];
                            if (updateCell)
                            {
                                [updateCell.image setImage:image withFade:YES];
                            }
                        }
                    }];
                }
                cell = attachmentCell;
            }
            else
            {
                AttributedLabelCell *noAttachmentsCell = [tableView dequeueReusableCellWithIdentifier:kNoAttachmentsCellIdentifier];
                noAttachmentsCell.attributedLabel.text = NSLocalizedString(@"tasks.attachments.empty", @"No Attachments");
                noAttachmentsCell.attributedLabel.textAlignment = NSTextAlignmentCenter;
                noAttachmentsCell.attributedLabel.font = [UIFont systemFontOfSize:kEmptyListLabelFontSize];
                noAttachmentsCell.attributedLabel.textColor = [UIColor noItemsTextColor];
                noAttachmentsCell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell = noAttachmentsCell;
            }
        }
            break;
            
        default:
            break;
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self tableView:tableView cellForRowAtIndexPath:indexPath];
    return [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];

    if (indexPath.section == TableSectionAttachments && self.attachments.count > 0)
    {
        AlfrescoDocument *selectedDocument = [self.attachments objectAtIndex:indexPath.row];
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
