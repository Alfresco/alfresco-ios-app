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
 
#import "CommentViewController.h"
#import "CommentCell.h"
#import "AvatarManager.h"
#import "TextView.h"
#import "Constants.h"
#import "AccountManager.h"

static CGFloat const kMaxCommentTextViewHeight = 100.0f;

@interface CommentViewController () <TextViewDelegate>

// NSLayoutConstarints
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *addCommentContainerViewHeightConstraint;

// Data Model
@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) AlfrescoCommentService *commentService;
@property (nonatomic, assign) CGFloat addCommentContainerViewHeight;
@property (nonatomic, weak, readwrite) id<CommentViewControllerDelegate> delegate;

// Views
@property (nonatomic, weak) IBOutlet UIView *addCommentContainerView;
@property (nonatomic, weak) IBOutlet TextView *addCommentTextView;
@property (nonatomic, weak) IBOutlet UIButton *postCommentButton;

@end

@implementation CommentViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session delegate:(id<CommentViewControllerDelegate>)delegate
{
    self = [super initWithSession:session];
    if (self)
    {
        self.node = node;
        self.permissions = permissions;
        self.delegate = delegate;
        [self createAlfrescoServicesWithSession:session];
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
    
    [self setAccessibilityIdentifiers];
    
    self.title = NSLocalizedString(@"comments.title", @"Comments");
    self.tableView.emptyMessage = NSLocalizedString(@"comments.empty", @"No Comments");
    
    // save the actual height for future use
    self.addCommentContainerViewHeight = self.addCommentContainerViewHeightConstraint.constant;

    [self updateCommentsContainerViewHeightForNode:self.node];

    if (self.session)
    {
        [self showHUD];
        [self loadCommentsForNode:self.node listingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            if (pagingResult)
            {
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.comments.retrieve.failed", @"Comment retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    
    self.addCommentTextView.maximumHeight = kMaxCommentTextViewHeight;
    self.addCommentTextView.layer.cornerRadius = 5.0f;
    self.addCommentTextView.layer.borderColor = [[UIColor borderGreyColor] CGColor];
    self.addCommentTextView.layer.borderWidth = 0.5f;
    self.addCommentTextView.font = [UIFont systemFontOfSize:12.0f];
    
    [self localiseUI];
}

- (void)updateCommentsContainerViewHeightForNode:(AlfrescoNode *)node
{
    if (!self.permissions.canComment)
    {
        self.addCommentContainerViewHeightConstraint.constant = 0.0f;
    }
    else
    {
        self.addCommentContainerViewHeightConstraint.constant = self.addCommentContainerViewHeight;
    }
}

#pragma mark - Private Functions

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kCommentVCViewIdentifier;
    self.postCommentButton.accessibilityIdentifier = kCommentVCPostButtonIdentifier;
    self.tableView.accessibilityIdentifier = kCommentVCTableViewIdentifier;
    self.addCommentTextView.accessibilityIdentifier = kCommentVCTextviewIdentifier;
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.commentService = [[AlfrescoCommentService alloc] initWithSession:session];
}

- (void)loadCommentsForNode:(AlfrescoNode *)node listingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock
{
    AlfrescoListingContext *requestListingContext = listingContext;
    
    if (!requestListingContext)
    {
        requestListingContext = self.defaultListingContext;
    }
    
    // Workaround for Cloud API rate limiting issues
    NSTimeInterval timeDelay = [self.session isKindOfClass:[AlfrescoCloudSession class]] ? kRateLimitForRequestsOnCloud : 0;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(timeDelay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.commentService retrieveCommentsForNode:self.node listingContext:requestListingContext latestFirst:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            if (completionBlock != NULL)
            {
                completionBlock(pagingResult, error);
                [self updateCommentCount];
            }
        }];
    });
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    if ([self shouldRefresh])
    {
        [self showHUD];
        [self loadCommentsForNode:self.node listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            [self hideHUD];
            if (pagingResult)
            {
                [self reloadTableViewWithPagingResult:pagingResult error:error];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.comments.retrieve.failed", @"Comment retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else if (self == [self.navigationController.viewControllers lastObject])
    {
        if (UserAccountTypeAIMS != [AccountManager sharedManager].selectedAccount.accountType)
        {
            [self.navigationController popToRootViewControllerAnimated:YES];
        }
    }
}

- (NSString *)placeholderText
{
    return NSLocalizedString(@"comments.placeholder.text", @"Placeholder Text");
}

- (void)localiseUI
{
    self.addCommentTextView.placeholderText = [self placeholderText];
    [self.postCommentButton setTitle:NSLocalizedString(@"comments.post.button", @"Post Button") forState:UIControlStateNormal];
}

- (void)updateCommentCount
{
    [self.delegate commentViewController:self didUpdateCommentCount:self.tableViewData.count hasMoreComments:self.moreItemsAvailable];
}

#pragma mark - Public Functions

- (void)focusCommentEntry:(BOOL)shouldFocus
{
    if(shouldFocus)
    {
        [self.addCommentTextView becomeFirstResponder];
    }
    else if([self.addCommentTextView isFirstResponder])
    {
        [self.addCommentTextView resignFirstResponder];
    }
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"CommentCell";
    CommentCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = (CommentCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CommentCell class]) owner:self options:nil] lastObject];
    }
    
    AlfrescoComment *currentComment = [self.tableViewData objectAtIndex:indexPath.row];
    
    cell.authorTextLabel.text = [NSString stringWithFormat:@"%@, %@", currentComment.createdBy, relativeTimeFromDate(currentComment.createdAt)];
    cell.contentTextLabel.text = stringByRemovingHTMLTagsFromString(currentComment.content);
    
    if ([currentComment.createdBy isEqualToString:self.session.personIdentifier])
    {
        UIImage *image = [[[UIImage imageNamed:@"bubble_blue.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 15.0f, 7.0f, 15.0f)];
        cell.speechBubbleImageView.tintColor = [UIColor appTintColor];
        cell.speechBubbleImageView.image = image;
        cell.contentTextLabel.textColor = [UIColor whiteColor];
    }
    else
    {
        UIImage *image = [[UIImage imageNamed:@"bubble_grey.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(7.0f, 15.0f, 7.0f, 15.0f)];
        cell.speechBubbleImageView.image = image;
        cell.contentTextLabel.textColor = [UIColor darkGrayColor];
    }
    
    AvatarConfiguration *configuration = [AvatarConfiguration defaultConfigurationWithIdentifier:currentComment.createdBy session:self.session];
    [[AvatarManager sharedManager] retrieveAvatarWithConfiguration:configuration completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
        [cell.avatarImageView setImage:avatarImage withFade:YES];
    }];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.tableViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more comments
    if (indexPath.row == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:[@(self.tableViewData.count) intValue]];
        if (self.moreItemsAvailable)
        {
            // show more comments are loading ...
            UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
            [spinner startAnimating];
            self.tableView.tableFooterView = spinner;
            
            [self loadCommentsForNode:self.node listingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                [self addMoreToTableViewWithPagingResult:pagingResult error:error];
                self.tableView.tableFooterView = nil;
            }];
        }
    }
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentCell *cell = (CommentCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Get the actual height required for the cell
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self loadCommentsForNode:self.node listingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hidePullToRefreshView];
        if (pagingResult)
        {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.comments.retrieve.failed", @"Comment retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

#pragma mark - IBActions

- (IBAction)postComment:(id)sender
{
    if (self.addCommentTextView.text.length > 0 && ![self.addCommentTextView.text isEqualToString:[self placeholderText]])
    {
        [self.addCommentTextView resignFirstResponder];
        
        __block MBProgressHUD *postingCommentHUD = [[MBProgressHUD alloc] initWithView:self.view];
        [self.view addSubview:postingCommentHUD];
        [postingCommentHUD showAnimated:YES];
        
        self.postCommentButton.enabled = NO;
        __weak typeof(self) weakSelf = self;
        [self.commentService addCommentToNode:self.node content:self.addCommentTextView.text title:nil completionBlock:^(AlfrescoComment *comment, NSError *error) {
            [postingCommentHUD hideAnimated:YES];
            postingCommentHUD = nil;
            weakSelf.postCommentButton.enabled = YES;
            
            if (comment)
            {
                NSString *analyticsLabel = nil;
                
                if ([weakSelf.node isKindOfClass:[AlfrescoDocument class]])
                {
                    analyticsLabel = ((AlfrescoDocument *)weakSelf.node).contentMimeType;
                }
                else if ([weakSelf.node isKindOfClass:[AlfrescoFolder class]])
                {
                    analyticsLabel = kAnalyticsEventLabelFolder;
                }
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionComment
                                                                   label:analyticsLabel
                                                                   value:@1];
                
                [weakSelf.tableViewData insertObject:comment atIndex:0];
                NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [weakSelf.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                [weakSelf updateCommentCount];
                weakSelf.addCommentTextView.text = [weakSelf placeholderText];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.add.comment.failed", @"Adding Comment Failed"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
                [weakSelf.addCommentTextView becomeFirstResponder];
            }
        }];
    }
}

- (IBAction)tappedView:(id)sender
{
    [self.addCommentTextView resignFirstResponder];
}

#pragma mark - TextViewDelegate Functions

- (void)textViewHeightDidChange:(TextView *)textView
{
    [self.view sizeToFit];
}

#pragma mark - NodeUpdatableProtocal Functions

- (void)updateToAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    self.node = node;
    self.permissions = permissions;
    self.session = session;
    [self createAlfrescoServicesWithSession:session];
    
    [self updateCommentsContainerViewHeightForNode:node];
    
    [self showHUD];
    [self loadCommentsForNode:self.node listingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        if (pagingResult)
        {
            [self reloadTableViewWithPagingResult:pagingResult error:error];
        }
        else
        {
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.comments.retrieve.failed", @"Comment retrieve failed"), [ErrorDescriptions descriptionForError:error]]);
            [Notifier notifyWithAlfrescoError:error];
        }
    }];
}

@end
