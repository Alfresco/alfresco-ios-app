//
//  FolderPreviewViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 06/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "FolderPreviewViewController.h"
#import "MetaDataViewController.h"
#import "PagedScrollView.h"
#import "CommentViewController.h"
#import "ActionCollectionView.h"
#import "FavouriteManager.h"
#import "ActionViewHandler.h"
#import "ConnectivityManager.h"

static NSUInteger const kActionViewHeight = 110;

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentFolderType)
{
    PagingScrollViewSegmentFolderTypeMetadata = 0,
    PagingScrollViewSegmentFolderTypeComments,
    PagingScrollViewSegmentFolderType_MAX
};

@interface FolderPreviewViewController () <CommentViewControllerDelegate, PagedScrollViewDelegate, ActionViewDelegate>

@property (nonatomic, strong) AlfrescoFolder *folder;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;
@property (nonatomic, strong) NSMutableArray *pagingControllers;
@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) ActionViewHandler *actionHandler;
@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentControl;
@property (nonatomic, weak) IBOutlet PagedScrollView *pagedScrollView;
@property (nonatomic, weak) IBOutlet ActionCollectionView *actionView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *actionViewHeightConstraint;

@end

@implementation FolderPreviewViewController

- (instancetype)initWithAlfrescoFolder:(AlfrescoFolder *)folder permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session
{
    self = [self init];
    if (self)
    {
        self.folder = folder;
        self.permissions = permissions;
        self.session = session;
        self.pagingControllers = [NSMutableArray array];
        self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
        self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:self.folder session:session controller:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.folder.name;
    
    [self localiseUI];
    
    [self setupActionCollectionView];
    
    [self setupPagingScrollView];
    
    [self updateActionButtons];
    [self updateActionViewVisibility];
}

#pragma mark - Private Functions

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

- (void)localiseUI
{
    [self.segmentControl setTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentFolderTypeMetadata];
    [self.segmentControl setTitle:NSLocalizedString(@"document.segment.nocomments.title", @"Comments Segment Title") forSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments];
}

- (void)setupPagingScrollView
{
    MetaDataViewController *metaDataController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.folder session:self.session];
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.folder permissions:self.permissions session:self.session delegate:self];
        for (int i = 0; i < PagingScrollViewSegmentFolderType_MAX; i++)
        {
            [self.pagingControllers addObject:[NSNull null]];
        }
        
        [self.pagingControllers insertObject:metaDataController atIndex:PagingScrollViewSegmentFolderTypeMetadata];
        [self.pagingControllers insertObject:commentViewController atIndex:PagingScrollViewSegmentFolderTypeComments];
    }
    else
    {
        [self.segmentControl removeSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments animated:NO];
        [self.pagingControllers insertObject:metaDataController atIndex:PagingScrollViewSegmentFolderTypeMetadata];
    }
    
    for (int i = 0; i < self.pagingControllers.count; i++)
    {
        if (![self.pagingControllers[i] isKindOfClass:[NSNull class]])
        {
            UIViewController *currentController = self.pagingControllers[i];
            [self.pagedScrollView addSubview:currentController.view];
        }
    }
}

- (void)setupActionCollectionView
{
    NSMutableArray *items = [NSMutableArray array];
    
    [items addObject:[ActionCollectionItem favouriteItem]];
    [items addObject:[ActionCollectionItem likeItem]];
    
    if (self.permissions.canComment)
    {
        [items addObject:[ActionCollectionItem commentItem]];
    }
    
    if (self.permissions.canAddChildren)
    {
        [items addObject:[ActionCollectionItem subfolderItem]];
        [items addObject:[ActionCollectionItem uploadItem]];
    }
    
    if (self.permissions.canDelete)
    {
        [items addObject:[ActionCollectionItem deleteItem]];
    }
    
    self.actionView.items = items;
}

- (void)updateActionButtons
{
    // check node is favourited
    [[FavouriteManager sharedManager] isNodeFavorite:self.folder session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        if (isFavorite)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favourited.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
        }
    }];
    
    // check and update the like node
    [self.ratingService isNodeLiked:self.folder completionBlock:^(BOOL succeeded, BOOL isLiked, NSError *error) {
        if (succeeded && isLiked)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-liked.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
    }];
}

- (void)updateActionViewVisibility
{
    if (![[ConnectivityManager sharedManager] hasInternetConnection])
    {
        self.actionViewHeightConstraint.constant = 0;
    }
    else
    {
        self.actionViewHeightConstraint.constant = kActionViewHeight;
    }
}

#pragma mark - IBActions

- (IBAction)segmentValueChanged:(id)sender
{
    PagingScrollViewSegmentFolderType selectedSegment = self.segmentControl.selectedSegmentIndex;
    [self.pagedScrollView scrollToDisplayViewAtIndex:selectedSegment animated:YES];
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierLike])
    {
        [self.actionHandler pressedLikeActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnlike])
    {
        [self.actionHandler pressedUnlikeActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierFavourite])
    {
        [self.actionHandler pressedFavouriteActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnfavourite])
    {
        [self.actionHandler pressedUnfavouriteActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierComment])
    {
        self.segmentControl.selectedSegmentIndex = PagingScrollViewSegmentFolderTypeComments;
        [self.pagedScrollView scrollToDisplayViewAtIndex:PagingScrollViewSegmentFolderTypeComments animated:YES];
        CommentViewController *commentsViewController = [self.pagingControllers objectAtIndex:PagingScrollViewSegmentFolderTypeComments];
        [commentsViewController focusCommentEntry];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierDelete])
    {
        [self.actionHandler pressedDeleteActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierCreateSubfolder])
    {
        [self.actionHandler pressedCreateSubFolderActionItem:actionItem inFolder:self.folder];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUploadDocument])
    {
        [self.actionHandler pressedUploadActionItem:actionItem presentFromView:cell inView:view];
    }
}

#pragma mark - CommentsViewControllerDelegate Functions

- (void)commentViewController:(CommentViewController *)controller didUpdateCommentCount:(NSUInteger)commentDisplayedCount hasMoreComments:(BOOL)hasMoreComments
{
    NSString *segmentCommentText = nil;
    
    if (hasMoreComments && commentDisplayedCount >= kMaxItemsPerListingRetrieve)
    {
        segmentCommentText = [NSString stringWithFormat:NSLocalizedString(@"document.segment.comments.hasmore.title", @"Comments Segment Title - Has More"), kMaxItemsPerListingRetrieve];
    }
    else if (commentDisplayedCount > 0)
    {
        segmentCommentText = [NSString stringWithFormat:NSLocalizedString(@"document.segment.comments.title", @"Comments Segment Title - Count"), commentDisplayedCount];
    }
    else if (commentDisplayedCount == 0)
    {
        segmentCommentText = NSLocalizedString(@"document.segment.nocomments.title", @"Comments Segment Title");
    }
    else
    {
        segmentCommentText = [self.segmentControl titleForSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments];
    }
    
    [self.segmentControl setTitle:segmentCommentText forSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments];
}

#pragma mark - PagedScrollViewDelegate Functions

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging
{
    // only want to update the segment control on each call if we are swiping and not using the segemnt control
    if (dragging)
    {
        [self.segmentControl setSelectedSegmentIndex:viewIndex];
    }
}

#pragma mark - ActionViewHandlerDelegate Functions

- (void)displayProgressIndicator
{
    [self showHUD];
}

- (void)hideProgressIndicator
{
    [self hideHUD];
}

#pragma mark - NodeUpdatableProtocol Function Implementation

- (void)updateToAlfrescoNode:(AlfrescoNode *)node permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;
{
    self.folder = (AlfrescoFolder *)node;
    self.permissions = permissions;
    self.session = session;
    
    self.title = node.name;
    
    self.actionHandler.node = node;
    self.actionHandler.session = session;
    
    [self setupActionCollectionView];
    [self updateActionButtons];
    [self updateActionViewVisibility];
    
    for (UIViewController *pagingController in self.pagingControllers)
    {
        if ([pagingController conformsToProtocol:@protocol(NodeUpdatableProtocol)])
        {
            UIViewController<NodeUpdatableProtocol> *conformingController = (UIViewController<NodeUpdatableProtocol> *)pagingController;
            [conformingController updateToAlfrescoNode:node permissions:permissions session:session];
        }
    }
}

@end
