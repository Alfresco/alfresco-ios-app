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
 
#import "AlfrescoNodeCell.h"
#import "SyncNodeStatus.h"
#import "RealmSyncManager.h"
#import "AlfrescoNode+Sync.h"
#import "FavouriteManager.h"

static NSString * const kAlfrescoNodeCellIdentifier = @"AlfrescoNodeCellIdentifier";

static CGFloat const kFavoriteIconWidth = 14.0f;
static CGFloat const kFavoriteIconRightSpace = 8.0f;
static CGFloat const kTopLevelIconWidth = 14.0f;
static CGFloat const kTopLevelIconRightSpace = 8.0f;
static CGFloat const kSyncIconWidth = 14.0f;
static CGFloat const kSyncIconRightSpace = 8.0f;

static CGFloat const kStatusIconsAnimationDuration = 0.2f;

@interface AlfrescoNodeCell()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) SyncNodeStatus *nodeStatus;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isTopLevelNode;
@property (nonatomic, assign) BOOL isSyncNode;
@property (nonatomic, strong) NSString *nodeDetails;

@property (nonatomic, strong) IBOutlet UIImageView *favoriteStatusImageView;
@property (nonatomic, strong) IBOutlet UIImageView *topLevelStatusImageView;
@property (nonatomic, strong) IBOutlet UIImageView *syncStatusImageView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topLevelIconWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconWidthConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconRightSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topLevelIconRightSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconRightSpaceConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconTopSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *topLevelIconTopSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconTopSpaceConstraint;

@property (nonatomic, assign) BOOL shouldHideAccessoryView;

@end

@implementation AlfrescoNodeCell

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    if (self)
    {
        
    }
    return self;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusChanged:)
                                                 name:kSyncStatusChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddNodeToFavorites:)
                                                 name:kFavouritesDidAddNodeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveNodeFromFavorites:)
                                                 name:kFavouritesDidRemoveNodeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddNodeToSync:)
                                                 name:kTopLevelSyncDidAddNodeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveNodeFromSync:)
                                                 name:kTopLevelSyncDidRemoveNodeNotification
                                               object:nil];
}

- (void)removeNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus
{
    self.node = node;
    self.nodeStatus = nodeStatus;
    self.filename.text = node.name;
    [self updateNodeDetails:nodeStatus];
}

- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite animate:(BOOL)animate
{
    self.isFavorite = isFavorite;
    self.isTopLevelNode = [self.node isTopLevelSyncNode];
    self.isSyncNode = isSyncNode;
    
    self.favoriteStatusImageView.image = nil;
    self.favoriteStatusImageView.highlightedImage = nil;
    self.topLevelStatusImageView.image = nil;
    self.topLevelStatusImageView.highlightedImage = nil;
    self.syncStatusImageView.image = nil;
    self.syncStatusImageView.highlightedImage = nil;
    
    void (^updateStatusIcons)(void) = ^{
        [self updateFavoriteIcon];
        [self updateTopLevelIcon];
        [self updateSyncedStatusIcon];
        
        [self layoutIfNeeded];
    };
    
    if (animate)
    {
        [UIView animateWithDuration:kStatusIconsAnimationDuration animations:^{
            updateStatusIcons();
        }];
    }
    else
    {
        updateStatusIcons();
    }
    
    [self updateCellWithNodeStatus:self.nodeStatus propertyChanged:kSyncStatus];
}

- (void)updateFavoriteIcon
{
    if (self.isFavorite)
    {
        self.favoriteStatusImageView.image = [UIImage imageNamed:@"status-favourite.png"];
        self.favoriteStatusImageView.highlightedImage = [UIImage imageNamed:@"status-favourite-highlighted.png"];
        
        self.favoriteIconWidthConstraint.constant = kFavoriteIconWidth;
        self.favoriteIconRightSpaceConstraint.constant = kFavoriteIconRightSpace;
        self.favoriteIconTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.favoriteStatusImageView.hidden = NO;
    }
    else
    {
        self.favoriteIconWidthConstraint.constant = 0;
        self.favoriteIconRightSpaceConstraint.constant = 0;
        self.favoriteIconTopSpaceConstraint.priority = UILayoutPriorityRequired;
        self.favoriteStatusImageView.hidden = YES;
    }
}

- (void)updateTopLevelIcon
{
    if (self.isTopLevelNode)
    {
        self.topLevelStatusImageView.image = [UIImage imageNamed:@"status-synced.png"];
        self.topLevelStatusImageView.highlightedImage = [UIImage imageNamed:@"status-synced-highlighted.png"];
        
        self.topLevelIconWidthConstraint.constant = kTopLevelIconWidth;
        self.topLevelIconRightSpaceConstraint.constant = kTopLevelIconRightSpace;
        self.topLevelIconTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.topLevelStatusImageView.hidden = NO;
    }
    else
    {
        self.topLevelIconWidthConstraint.constant = 0;
        self.topLevelIconRightSpaceConstraint.constant = 0;
        self.topLevelIconTopSpaceConstraint.priority = UILayoutPriorityRequired;
        self.topLevelStatusImageView.hidden = YES;
    }
}

- (void)updateSyncedStatusIcon
{
    if (self.isSyncNode)
    {
        self.syncIconWidthConstraint.constant = kSyncIconWidth;
        self.syncIconRightSpaceConstraint.constant = kSyncIconRightSpace;
        self.syncIconTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        self.syncStatusImageView.hidden = NO;
    }
    else
    {
        self.syncIconWidthConstraint.constant = 0;
        self.syncIconRightSpaceConstraint.constant = 0;
        self.syncIconTopSpaceConstraint.priority = UILayoutPriorityRequired;
        self.syncStatusImageView.hidden = YES;
    }
}

- (void)setupCellWithNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session
{
    [self setupCellWithNode:node session:session hideAccessoryView:NO];
}

- (void)setupCellWithNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session hideAccessoryView:(BOOL)hideAccessoryView
{
    self.shouldHideAccessoryView = hideAccessoryView;
    
    [self registerForNotifications];
    
    BOOL isNodeInSyncList = [node isNodeInSyncList];
    SyncNodeStatus *nodeStatus = [[RealmSyncManager sharedManager] syncStatusForNodeWithId:node.identifier];
    
    [self updateCellInfoWithNode:node nodeStatus:nodeStatus];
    [self updateStatusIconsIsSyncNode:isNodeInSyncList isFavoriteNode:NO animate:NO];
    
    [[FavouriteManager sharedManager] isNodeFavorite:node session:session completionBlock:^(BOOL isFavorite, NSError *error) {
        [self updateStatusIconsIsSyncNode:isNodeInSyncList isFavoriteNode:isFavorite animate:NO];
    }];
}

+ (NSString *)cellIdentifier
{
    return kAlfrescoNodeCellIdentifier;
}

#pragma mark - Notification Methods

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if ([self.node.identifier hasPrefix:[info objectForKey:kSyncStatusNodeIdKey]])
    {
        SyncNodeStatus *nodeStatus = notification.object;
        self.nodeStatus = nodeStatus;
        NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isSyncNode && nodeStatus.status != SyncStatusRemoved)
            {
                [self updateStatusIconsIsSyncNode:YES isFavoriteNode:self.isFavorite animate:YES];
            }
            if (nodeStatus.status == SyncStatusRemoved)
            {
                self.nodeStatus = nil;
                [self updateStatusIconsIsSyncNode:NO isFavoriteNode:self.isFavorite animate:YES];
            }
            [self updateCellWithNodeStatus:nodeStatus propertyChanged:propertyChanged];
        });
    }
}

- (void)didAddNodeToFavorites:(NSNotification *)notification
{
    AlfrescoNode *nodeFavorited = (AlfrescoNode *)notification.object;
    if ([nodeFavorited.identifier isEqualToString:self.node.identifier])
    {
        [self updateStatusIconsIsSyncNode:self.isSyncNode isFavoriteNode:YES animate:YES];
    }
}

- (void)didRemoveNodeFromFavorites:(NSNotification *)notification
{
    AlfrescoNode *nodeUnFavorited = (AlfrescoNode *)notification.object;
    if ([nodeUnFavorited.identifier isEqualToString:self.node.identifier])
    {
        self.isFavorite = NO;
        [self updateStatusIconsIsSyncNode:self.isSyncNode isFavoriteNode:NO animate:YES];
    }
}

- (void)didAddNodeToSync:(NSNotification *)notification
{
    AlfrescoNode *node = (AlfrescoNode *)notification.object;
    if ([node.identifier isEqualToString:self.node.identifier])
    {
        self.isTopLevelNode = [self.node isTopLevelSyncNode];
        [self updateStatusIconsIsSyncNode:YES isFavoriteNode:self.isFavorite animate:YES];
    }
}

- (void)didRemoveNodeFromSync:(NSNotification *)notification
{
    AlfrescoNode *node = (AlfrescoNode *)notification.object;
    if ([node.identifier isEqualToString:self.node.identifier])
    {
        self.isTopLevelNode = [self.node isTopLevelSyncNode];
        
        //The node could be in another top level folder. In this case, we should only remove the top level and mentain the synced flag.
        RealmSyncNodeInfo *realmSyncNodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:[[RealmManager sharedManager] realmForCurrentThread]];
        self.isSyncNode = realmSyncNodeInfo != nil;
        
        [self updateStatusIconsIsSyncNode:self.isSyncNode isFavoriteNode:self.isFavorite animate:YES];
    }
}

#pragma mark - Private Methods

- (void)updateCellWithNodeStatus:(SyncNodeStatus *)nodeStatus propertyChanged:(NSString *)propertyChanged
{
    if ([propertyChanged isEqualToString:kSyncStatus])
    {
        [self setAccessoryViewForState:nodeStatus.status];
        [self updateSyncStatusDetails:nodeStatus];
    }
    else if ([propertyChanged isEqualToString:kSyncTotalSize] || [propertyChanged isEqualToString:kSyncLocalModificationDate])
    {
        [self updateNodeDetails:nodeStatus];
    }
    
    [self updateStatusImageForSyncState:nodeStatus];
    
    if (nodeStatus.status == SyncStatusLoading && nodeStatus.bytesTransfered > 0 && nodeStatus.bytesTransfered < nodeStatus.totalBytesToTransfer)
    {
        self.progressBar.hidden = NO;
        float percentTransfered = (float)nodeStatus.bytesTransfered / (float)nodeStatus.totalBytesToTransfer;
        self.progressBar.progress = percentTransfered;
    }
    else
    {
        self.progressBar.hidden = YES;
    }
}

- (void)updateStatusImageForSyncState:(SyncNodeStatus *)nodeStatus
{
    NSString *statusImageName = nil;
    switch (nodeStatus.status)
    {
        case SyncStatusCancelled:
        case SyncStatusFailed:
            statusImageName = @"status-sync-failed";
            break;
            
        case SyncStatusLoading:
            statusImageName = @"status-sync-loading";
            break;
            
        case SyncStatusOffline:
        case SyncStatusDisabled:
        case SyncStatusWaiting:
            statusImageName = @"status-sync-waiting";
            break;
            
        case SyncStatusSuccessful:
            statusImageName = @"status-sync-synced";
            break;
            
        default:
            break;
    }
    
    if (statusImageName)
    {
        self.syncStatusImageView.image = [UIImage imageNamed:statusImageName];
        self.syncStatusImageView.highlightedImage = [UIImage imageNamed:[statusImageName stringByAppendingString:@"-highlighted"]];
    }
}

- (void)setAccessoryViewForState:(SyncStatus)status
{
    if (self.node.isFolder)
    {
        self.accessoryType = self.shouldHideAccessoryView ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDetailButton;
    }
    else
    {
        self.accessoryType = UITableViewCellAccessoryNone;
        
        UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
        UIImage *buttonImage;
        
        switch (status)
        {
            case SyncStatusLoading:
                buttonImage = [[UIImage imageNamed:@"sync-button-stop.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                button.tintColor = [UIColor appTintColor];
                break;
                
            case SyncStatusFailed:
                buttonImage = [[UIImage imageNamed:@"sync-button-error.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                button.tintColor = [UIColor syncFailedColor];
                break;
                
            default:
                [self setAccessoryView:nil];
                break;
        }
        
        if (buttonImage)
        {
            [button setFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
            [button setImage:buttonImage forState:UIControlStateNormal];
            [button setShowsTouchWhenHighlighted:YES];
            [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
            [self setAccessoryView:button];
        }
    }
}

- (void)updateNodeDetails:(SyncNodeStatus *)nodeStatus
{
    NSString *fileSizeString = nil;
    NSString *modifiedDateString = nil;
    
    if (self.node.isFolder)
    {
        if (nodeStatus.totalSize > 0)
        {
            fileSizeString = stringForLongFileSize(nodeStatus.totalSize);
            self.nodeDetails = fileSizeString;
        }
        else
        {
            self.nodeDetails = @"";
        }
    }
    else
    {
        modifiedDateString = nodeStatus.localModificationDate ? relativeTimeFromDate(nodeStatus.localModificationDate) : relativeTimeFromDate(self.node.modifiedAt);
        fileSizeString = (nodeStatus.totalSize > 0) ? stringForLongFileSize(nodeStatus.totalSize) : stringForLongFileSize(((AlfrescoDocument *)self.node).contentLength);
        self.nodeDetails = [NSString stringWithFormat:@"%@ • %@", modifiedDateString, fileSizeString];
    }
    
    [self updateSyncStatusDetails:nodeStatus];
}

- (void)updateSyncStatusDetails:(SyncNodeStatus *)nodeStatus
{
    self.details.textColor = [UIColor textDefaultColor];
    
    if (nodeStatus.status == SyncStatusWaiting)
    {
        self.details.text = NSLocalizedString(@"sync.state.waiting-to-sync", @"waiting to sync");
    }
    else if (nodeStatus.status == SyncStatusFailed)
    {
        self.details.text = NSLocalizedString(@"sync.state.failed-to-sync", @"failed to sync");
        self.details.textColor = [UIColor syncFailedColor];
    }
    else
    {
        self.details.text = self.nodeDetails;
    }
}

#pragma mark - Private Methods

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    UIView *cell = button.superview;
    
    if (![cell isKindOfClass:[UITableViewCell class]])
    {
        cell = (UITableViewCell *)cell.superview;
    }
    UIView *table = cell.superview;
    
    if (![table isKindOfClass:[UITableView class]])
    {
        table = (UITableView *)table.superview;
    }
    UITableView *tableView = (UITableView *)table;
    
    NSIndexPath *indexPath = [tableView indexPathForCell:(UITableViewCell *)cell];
    [tableView.delegate tableView:tableView accessoryButtonTappedForRowWithIndexPath:indexPath];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
