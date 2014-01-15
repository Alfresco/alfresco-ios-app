//
//  CommentViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CommentViewController.h"
#import "Utility.h"
#import "CommentCell.h"
#import "AvatarManager.h"
#import "AUIAutoGrowingTextView.h"

static CGFloat const kMaxCommentTextViewHeight = 100.0f;

@interface CommentViewController ()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) AlfrescoCommentService *commentService;
@property (nonatomic, weak) IBOutlet UIView *addCommentContainerView;
@property (nonatomic, weak) IBOutlet AUIAutoGrowingTextView *addCommentTextView;
@property (nonatomic, weak) IBOutlet UIButton *postCommentButton;
@property (nonatomic, strong) UILabel *sectionFooterLabel;

@end

@implementation CommentViewController

- (id)initWithAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        self.node = node;
        self.permissions = permissions;
        [self createAlfrescoServicesWithSession:session];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
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
    
    self.title = NSLocalizedString(@"comments.title", @"Comments Title");
    
    if (!self.permissions.canComment)
    {
        [self.view removeConstraints:self.view.constraints];
        [self.addCommentContainerView removeFromSuperview];
        UITableView *tableView = self.tableView;
        NSDictionary *views = NSDictionaryOfVariableBindings(tableView);
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"|[tableView]|" options:NSLayoutFormatAlignAllTop | NSLayoutFormatAlignAllBottom metrics:nil views:views]];
        [self.view addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[tableView]|" options:NSLayoutFormatAlignAllBaseline metrics:nil views:views]];
    }

    [self loadCommentsForNode:self.node listingContext:nil completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
    
    self.addCommentTextView.maxHeight = kMaxCommentTextViewHeight;
    
    [self localiseUI];
}

#pragma mark - Private Functions

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
    
    [self showHUD];
    [self.commentService retrieveCommentsForNode:self.node listingContext:requestListingContext latestFirst:YES completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
            [self updateCommentCountFooter];
        }
    }];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self createAlfrescoServicesWithSession:session];
    
    if ([self shouldRefresh])
    {
        [self loadCommentsForNode:self.node listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
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
        [self.navigationController popToRootViewControllerAnimated:YES];
    }
}

- (NSString *)placeholderText
{
    return NSLocalizedString(@"comments.placeholder.text", @"Placeholder Text");
}

- (void)localiseUI
{
    self.addCommentTextView.text = [self placeholderText];
    [self.postCommentButton setTitle:NSLocalizedString(@"comments.post.button", @"Post Button") forState:UIControlStateNormal];
}

#pragma mark - Public Functions

- (void)focusCommentEntry
{
    [self.addCommentTextView becomeFirstResponder];
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
    
    cell.authorTextLabel.text = [NSString stringWithFormat:@"%@, %@", currentComment.createdBy, relativeDateFromDate(currentComment.createdAt)];
    cell.contentTextLabel.text = stringByRemovingHTMLTagsFromString(currentComment.content);
    
    if ([currentComment.createdBy isEqualToString:self.session.personIdentifier])
    {
        cell.contentTextLabel.backgroundColor = [UIColor lightGrayColor];
    }
    else
    {
        cell.contentTextLabel.backgroundColor = [UIColor blueColor];
    }
    
    AlfrescoContentFile *avatarContentFile = [[AvatarManager sharedManager] avatarForUsername:currentComment.createdBy];
        
    if (avatarContentFile)
    {
        [cell.avatarImageView setImageAtPath:avatarContentFile.fileUrl.path withFade:NO];
    }
    else
    {
        UIImage *placeholderImage = [UIImage imageNamed:@"stop-transfer.png"];
        cell.avatarImageView.image = placeholderImage;
        [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:currentComment.createdBy session:self.session completionBlock:^(AlfrescoContentFile *avatarContentFile, NSError *avatarError) {
            if (avatarContentFile)
            {
                [cell.avatarImageView setImageAtPath:avatarContentFile.fileUrl.path withFade:YES];
            }
        }];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    // the last row index of the table data
    NSUInteger lastSiteRowIndex = self.tableViewData.count - 1;
    
    // if the last cell is about to be drawn, check if there are more comments
    if (indexPath.row == lastSiteRowIndex)
    {
        AlfrescoListingContext *moreListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:self.tableViewData.count];
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

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (!self.sectionFooterLabel)
    {
        self.sectionFooterLabel = [[UILabel alloc] init];
        self.sectionFooterLabel.font = [UIFont systemFontOfSize:14.0f];
        self.sectionFooterLabel.backgroundColor = [UIColor whiteColor];
        self.sectionFooterLabel.textAlignment = NSTextAlignmentCenter;
        [self updateCommentCountFooter];
    }
    
    return self.sectionFooterLabel;
}

- (NSString *)titleForCommentsInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    if (self.tableViewData.count == 0)
    {
        footerText = [NSString stringWithFormat:NSLocalizedString(@"comments.footer.multiple.comments", @"%i Comments"), self.tableViewData.count];
    }
    
    return footerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentCell *cell = (CommentCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    // Get the actual height required for the cell
    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return height;
}

- (void)updateCommentCountFooter
{
    self.sectionFooterLabel.text = [self titleForCommentsInSection:0];
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
        [postingCommentHUD show:YES];
        
        self.postCommentButton.enabled = NO;
        __weak typeof(self) weakSelf = self;
        [self.commentService addCommentToNode:self.node content:self.addCommentTextView.text title:nil completionBlock:^(AlfrescoComment *comment, NSError *error) {
            [postingCommentHUD hide:YES];
            postingCommentHUD = nil;
            weakSelf.postCommentButton.enabled = YES;
            
            if (comment)
            {
                [weakSelf.tableViewData insertObject:comment atIndex:0];
                NSIndexPath *insertIndexPath = [NSIndexPath indexPathForRow:0 inSection:0];
                [weakSelf.tableView insertRowsAtIndexPaths:@[insertIndexPath] withRowAnimation:UITableViewRowAnimationTop];
                [weakSelf updateCommentCountFooter];
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

#pragma mark - UITextViewDelegate Functions

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    if ([textView.text isEqualToString:[self placeholderText]])
    {
        textView.text = @"";
    }
}

- (void)textViewDidChange:(UITextView *)textView
{
    NSString *trimmedText = [textView.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (trimmedText.length > 0 && ![trimmedText isEqualToString:[self placeholderText]])
    {
        self.postCommentButton.enabled = YES;
    }
    else
    {
        self.postCommentButton.enabled = NO;
    }
}

- (void)textViewDidEndEditing:(UITextView *)textView
{
    if (textView.text.length == 0)
    {
        textView.text = [self placeholderText];
    }
}

@end
