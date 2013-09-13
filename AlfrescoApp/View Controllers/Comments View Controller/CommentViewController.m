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

@interface CommentViewController ()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) AlfrescoCommentService *commentService;

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
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"comments.title", @"Comments Title");
    
    if (self.permissions.canComment)
    {
        UIBarButtonItem *addCommentButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                          target:self
                                                                                          action:@selector(addComment:)];
        self.navigationItem.rightBarButtonItem = addCommentButton;
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
    [self.commentService retrieveCommentsForNode:self.node listingContext:requestListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self hideHUD];
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
            [self tableView:self.tableView titleForFooterInSection:0];
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

- (CGFloat)heightForRowUsingCell:(UITableViewCell *)cell maxWidth:(CGFloat)maxWidth
{
    CommentCell *commentCell = (CommentCell *)cell;
    CGFloat maxHeight = 4000;

    CGSize cellSize = [commentCell.contentTextLabel.text sizeWithFont:commentCell.contentTextLabel.font
                                                    constrainedToSize:CGSizeMake(maxWidth, maxHeight)
                                                        lineBreakMode:NSLineBreakByWordWrapping];
    
    cellSize.height += commentCell.contentTextLabel.frame.origin.y + 10.0f;
    
    return cellSize.height;
}

- (void)addComment:(id)sender
{
    AddCommentViewController *addCommentViewController = [[AddCommentViewController alloc] initWithAlfrescoNode:self.node session:self.session delegate:self];
    
    [self.navigationController pushViewController:addCommentViewController animated:YES];
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
    
    // config the cell here...
    AlfrescoComment *currentComment = [self.tableViewData objectAtIndex:indexPath.row];
    
    cell.authorTextLabel.text = currentComment.createdBy;
    cell.timeTextLabel.text = relativeDateFromDate(currentComment.createdAt);
    cell.contentTextLabel.text = stringByRemovingHTMLTagsFromString(currentComment.content);
    
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
    UILabel *footer = [[UILabel alloc] init];
    
    footer.text = [self tableView:tableView titleForFooterInSection:section];
    footer.font = [UIFont systemFontOfSize:14.0f];
    footer.backgroundColor = [UIColor whiteColor];
    footer.textAlignment = NSTextAlignmentCenter;
    
    return footer;
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *footerText = nil;
    
    switch (self.tableViewData.count)
    {
        case 1:
        {
            footerText = NSLocalizedString(@"comments.footer.one.comment", @"1 Comment");
            break;
        }
        default:
        {
            footerText = [NSString stringWithFormat:NSLocalizedString(@"comments.footer.multiple.comments", @"%i Comments"), self.tableViewData.count];
            break;
        }
    }
    
    return footerText;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CommentCell *cell = (CommentCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];
    
    return [self heightForRowUsingCell:cell maxWidth:tableView.frame.size.width];
}

#pragma mark - EGORefreshTableHeaderDelegate Methods

- (void)egoRefreshTableHeaderDidTriggerRefresh:(EGORefreshTableHeaderView *)view
{
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

#pragma mark - AddCommentViewControllerDelegate Functions

- (void)didSuccessfullyAddComment:(AlfrescoComment *)comment
{
    if (!self.moreItemsAvailable)
    {
        [self.tableViewData addObject:comment];
        [self.tableView reloadData];
    }
}

@end
