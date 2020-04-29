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
 
#import "FolderPreviewViewController.h"
#import "MetaDataViewController.h"
#import "PagedScrollView.h"
#import "CommentViewController.h"
#import "ActionCollectionView.h"
#import "FavouriteManager.h"
#import "RealmSyncManager.h"
#import "ActionViewHandler.h"
#import "ConnectivityManager.h"
#import "AccountManager.h"

static CGFloat sActionViewHeight = 0;
static CGFloat segmentControlHeight = 0;
static CGFloat const kAnimationSpeed = 0.3;
static CGFloat const kActionViewAdditionalTextRowHeight = 15.0f;

typedef NS_ENUM(NSUInteger, PagingScrollViewSegmentFolderType)
{
    PagingScrollViewSegmentFolderTypeMetadata = 0,
    PagingScrollViewSegmentFolderTypeComments,
    PagingScrollViewSegmentFolderType_MAX
};

@interface FolderPreviewViewController () <CommentViewControllerDelegate, PagedScrollViewDelegate, ActionViewDelegate>

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *segmentControlHeightConstraint;
@property (nonatomic, strong) AlfrescoFolder *folder;
@property (nonatomic, strong) AlfrescoPermissions *permissions;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) AlfrescoRatingService *ratingService;
@property (nonatomic, strong) NSMutableArray *pagingControllers;
@property (nonatomic, strong) NSMutableArray *displayedPagingControllers;
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
        self.displayedPagingControllers = [NSMutableArray array];
        self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
        self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:self.folder session:session controller:self];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setAccessibilityIdentifiers];
    self.pagedScrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    
    [self actionViewHeightFromPreferredLanguage];
    sActionViewHeight = self.actionViewHeightConstraint.constant;
    
    [self setupPagingScrollView];
    [self localiseUI];
    [self refreshViewController];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateActionButtons) name:kFavoritesListUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateActionViewVisibility) name:kAlfrescoConnectivityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.navigationController.navigationBar.translucent = NO;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Functions

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kBaseDocumentPreviewVCViewIdentifier;
    self.segmentControl.accessibilityIdentifier = kBaseDocumentPreviewVCSegmentedControlIdentifier;
}

- (void)showHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.view addSubview:self.progressHUD];
        }
        [self.progressHUD showAnimated:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideAnimated:YES];
    });
}

- (void)localiseUI
{
    if (IS_IPAD)
    {
        [self.segmentControl setTitle:NSLocalizedString(@"document.segment.metadata.title", @"Metadata Segment Title") forSegmentAtIndex:PagingScrollViewSegmentFolderTypeMetadata];
        [self.segmentControl setTitle:NSLocalizedString(@"document.segment.nocomments.title", @"Comments Segment Title") forSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments];
    }
}

- (void)refreshViewController
{
    self.title = self.folder.name;
    
    [self refreshPagingScrollView];
    [self setupActionCollectionView];
    [self updateActionButtons];
    [self updateActionViewVisibility];
    
    if (self.displayedPagingControllers.count <= 1)
    {
        self.segmentControlHeightConstraint.constant = 0;
        self.segmentControl.hidden = YES;
    }
    else
    {
        self.segmentControlHeightConstraint.constant = segmentControlHeight;
        self.segmentControl.hidden = NO;
    }
    
    [self localiseUI];
}

- (void)setupPagingScrollView
{
    MetaDataViewController *metaDataController = [[MetaDataViewController alloc] initWithAlfrescoNode:self.folder session:self.session];
    [self.pagingControllers insertObject:metaDataController atIndex:PagingScrollViewSegmentFolderTypeMetadata];
    CommentViewController *commentViewController = [[CommentViewController alloc] initWithAlfrescoNode:self.folder permissions:self.permissions session:self.session delegate:self];
    [self.pagingControllers insertObject:commentViewController atIndex:PagingScrollViewSegmentFolderTypeComments];
    
    segmentControlHeight = self.segmentControlHeightConstraint.constant;
}

- (void)refreshPagingScrollView
{
    NSUInteger currentlySelectedTabIndex = self.pagedScrollView.selectedPageIndex;
    
    // Remove all existing views in the scroll view
    NSArray *shownControllers = [NSArray arrayWithArray:self.displayedPagingControllers];
    
    for (UIViewController *displayedController in shownControllers)
    {
        [displayedController willMoveToParentViewController:nil];
        [displayedController.view removeFromSuperview];
        [displayedController removeFromParentViewController];
        
        [self.displayedPagingControllers removeObject:displayedController];
    }
    
    // Add them back and refresh the segment control.
    // If the document object is nil, we must not disiplay the MetaDataViewController
    for (UIViewController *pagingController in self.pagingControllers)
    {
        if (self.folder == nil ||
            ([pagingController isKindOfClass:[CommentViewController class]] && ![ConnectivityManager sharedManager].hasInternetConnection))
        {
            break;
        }
        [self addChildViewController:pagingController];
        [self.pagedScrollView addSubview:pagingController.view];
        [pagingController didMoveToParentViewController:self];
        
        [self.displayedPagingControllers addObject:pagingController];
    }
    
    self.segmentControl.selectedSegmentIndex = currentlySelectedTabIndex;
    [self.pagedScrollView scrollToDisplayViewAtIndex:currentlySelectedTabIndex animated:NO];
}

- (void)setupActionCollectionView
{
    NSMutableArray *items = [NSMutableArray array];
    
    if([AccountManager sharedManager].selectedAccount.isSyncOn)
    {
        [items addObject:[ActionCollectionItem syncItem]];
    }
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
    //check node is synced
    BOOL isSynced = [self.folder isTopLevelSyncNode];
    NSString *actionIdentifier = isSynced ? kActionCollectionIdentifierUnsync : kActionCollectionIdentifierSync;
    NSString *titleKey = isSynced ? NSLocalizedString(@"action.unsync", @"Unsync Action") : NSLocalizedString(@"action.sync", @"Sync Action");
    NSString *imageKey = isSynced ? @"actionsheet-unsync.png" : @"actionsheet-sync.png";
    
    if (actionIdentifier && titleKey && imageKey)
    {
        NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : actionIdentifier,
                                   kActionCollectionItemUpdateItemTitleKey : titleKey,
                                   kActionCollectionItemUpdateItemImageKey : imageKey};
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:isSynced ? kActionCollectionIdentifierSync : kActionCollectionIdentifierUnsync userInfo:userInfo];
    }
    
    // check node is favourited
    [[FavouriteManager sharedManager] isNodeFavorite:self.folder session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        if (isFavorite)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnfavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unfavourite", @"Unfavourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unfavorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierFavourite userInfo:userInfo];
        }
        else
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierFavourite,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.favourite", @"Favourite Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-favorite.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierUnfavourite userInfo:userInfo];
        }
    }];
    
    // check and update the like node
    [self.ratingService isNodeLiked:self.folder completionBlock:^(BOOL succeeded, BOOL isLiked, NSError *error) {
        if (succeeded && isLiked)
        {
            NSDictionary *userInfo = @{kActionCollectionItemUpdateItemIndentifier : kActionCollectionIdentifierUnlike,
                                       kActionCollectionItemUpdateItemTitleKey : NSLocalizedString(@"action.unlike", @"Unlike Action"),
                                       kActionCollectionItemUpdateItemImageKey : @"actionsheet-unlike.png"};
            [[NSNotificationCenter defaultCenter] postNotificationName:kActionCollectionItemUpdateNotification object:kActionCollectionIdentifierLike userInfo:userInfo];
        }
    }];
}

- (void)updateActionViewVisibility
{
    CGFloat currentHeight = self.actionViewHeightConstraint.constant;
    CGFloat requiredHeight = [[ConnectivityManager sharedManager] hasInternetConnection] ? sActionViewHeight : 0;
    
    if (currentHeight != requiredHeight)
    {
        [UIView animateWithDuration:kAnimationSpeed animations:^{
            self.actionViewHeightConstraint.constant = requiredHeight;
            [self.actionView layoutIfNeeded];
        }];
    }
}

- (void)actionViewHeightFromPreferredLanguage
{
    NSArray *preferredLocalisations = [[NSBundle mainBundle] preferredLocalizations];
    NSArray *localisationRequiringTwoRows = [Utility localisationsThatRequireTwoRowsInActionView];
    
    if ([localisationRequiringTwoRows containsObject:preferredLocalisations.firstObject])
    {
        self.actionViewHeightConstraint.constant += kActionViewAdditionalTextRowHeight;
    }
}

- (void) shouldFocusComments:(BOOL)shouldFocusComments
{
    CommentViewController *commentsViewController = [self.pagingControllers objectAtIndex:PagingScrollViewSegmentFolderTypeComments];
    [commentsViewController focusCommentEntry:shouldFocusComments];
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:self.session];
    self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:self.folder session:self.session controller:self];
}

#pragma mark - IBActions

- (IBAction)segmentValueChanged:(id)sender
{
    PagingScrollViewSegmentFolderType selectedSegment = self.segmentControl.selectedSegmentIndex;
    [self.pagedScrollView scrollToDisplayViewAtIndex:selectedSegment animated:YES];
    
    if(selectedSegment != PagingScrollViewSegmentFolderTypeComments)
    {
        [self shouldFocusComments:NO];
    }
}

#pragma mark - ActionCollectionViewDelegate Functions

- (void)didPressActionItem:(ActionCollectionItem *)actionItem cell:(UICollectionViewCell *)cell inView:(UICollectionView *)view
{
    BOOL shouldFocusComments = NO;
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
        shouldFocusComments = YES;
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
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierSync])
    {
        [self.actionHandler pressedSyncActionItem:actionItem];
    }
    else if ([actionItem.itemIdentifier isEqualToString:kActionCollectionIdentifierUnsync])
    {
        [self.actionHandler pressedUnsyncActionItem:actionItem];
    }
    
    [self shouldFocusComments:shouldFocusComments];
}

#pragma mark - CommentsViewControllerDelegate Functions

- (void)commentViewController:(CommentViewController *)controller didUpdateCommentCount:(NSUInteger)commentDisplayedCount hasMoreComments:(BOOL)hasMoreComments
{
    if (IS_IPAD)
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
    else
    {
        NSString *imageName = (commentDisplayedCount > 0) ? @"segment-icon-comments.png" : @"segment-icon-comments-none.png";
        [self.segmentControl setImage:[UIImage imageNamed:imageName] forSegmentAtIndex:PagingScrollViewSegmentFolderTypeComments];
    }
}

#pragma mark - PagedScrollViewDelegate Functions

- (void)pagedScrollViewDidScrollToFocusViewAtIndex:(NSInteger)viewIndex whilstDragging:(BOOL)dragging
{
    // only want to update the segment control on each call if we are swiping and not using the segemnt control
    if (dragging)
    {
        [self.segmentControl setSelectedSegmentIndex:viewIndex];
        
        if(viewIndex != PagingScrollViewSegmentFolderTypeComments)
        {
            [self shouldFocusComments:NO];
        }
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
    self.ratingService = [[AlfrescoRatingService alloc] initWithSession:session];
    self.actionHandler = [[ActionViewHandler alloc] initWithAlfrescoNode:node session:session controller:self];
    
    [self refreshViewController];
    
    for (UIViewController *pagingController in self.displayedPagingControllers)
    {
        if ([pagingController conformsToProtocol:@protocol(NodeUpdatableProtocol)])
        {
            UIViewController<NodeUpdatableProtocol> *conformingController = (UIViewController<NodeUpdatableProtocol> *)pagingController;
            [conformingController updateToAlfrescoNode:node permissions:permissions session:session];
        }
    }
}

@end
