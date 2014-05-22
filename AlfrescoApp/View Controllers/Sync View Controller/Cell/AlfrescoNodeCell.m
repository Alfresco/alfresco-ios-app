//
//  AlfrescoNodeCell.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 28/01/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AlfrescoNodeCell.h"
#import "SyncNodeStatus.h"
#import "Utility.h"

static NSString * const kAlfrescoNodeCellIdentifier = @"AlfrescoNodeCellIdentifier";

static CGFloat const FavoriteIconWidth = 14.0f;
static CGFloat const FavoriteIconRightSpace = 8.0f;
static CGFloat const SyncIconWidth = 14.0f;
static CGFloat const SyncIconRightSpace = 8.0f;

static CGFloat const kStatusIconsAnimationDuration = 0.2f;

@interface AlfrescoNodeCell()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) SyncNodeStatus *nodeStatus;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isSyncNode;
@property (nonatomic, strong) NSString *nodeDetails;

@property (nonatomic, strong) IBOutlet UIImageView *syncStatusImageView;
@property (nonatomic, strong) IBOutlet UIImageView *favoriteStatusImageView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconWidthConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconRightSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconRightSpaceConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconTopSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconTopSpaceConstraint;

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
    self.isSyncNode = isSyncNode;
    self.isFavorite = isFavorite;
    
    self.syncStatusImageView.image = nil;
    self.syncStatusImageView.highlightedImage = nil;
    self.favoriteStatusImageView.image = nil;
    self.favoriteStatusImageView.highlightedImage = nil;
    
    void (^updateStatusIcons)(void) = ^{
        
        if (self.isFavorite)
        {
            self.favoriteStatusImageView.image = [UIImage imageNamed:@"status-favourite.png"];
            self.favoriteStatusImageView.highlightedImage = [UIImage imageNamed:@"status-favourite-highlighted.png"];
            
            self.favoriteIconWidthConstraint.constant = FavoriteIconWidth;
            self.favoriteIconRightSpaceConstraint.constant = FavoriteIconRightSpace;
            self.favoriteIconTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        }
        else
        {
            self.favoriteIconWidthConstraint.constant = 0;
            self.favoriteIconRightSpaceConstraint.constant = 0;
            self.favoriteIconTopSpaceConstraint.priority = UILayoutPriorityDefaultLow;
        }
        
        if (self.isSyncNode)
        {
            self.syncIconWidthConstraint.constant = SyncIconWidth;
            self.syncIconRightSpaceConstraint.constant = SyncIconRightSpace;
            self.syncIconTopSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
        }
        else
        {
            self.syncIconWidthConstraint.constant = 0;
            self.syncIconRightSpaceConstraint.constant = 0;
            self.syncIconTopSpaceConstraint.priority = UILayoutPriorityDefaultLow;
        }
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
    
    self.syncStatusImageView.image = [UIImage imageNamed:statusImageName];
    self.syncStatusImageView.highlightedImage = [UIImage imageNamed:[statusImageName stringByAppendingString:@"-highlighted"]];
}

- (void)setAccessoryViewForState:(SyncStatus)status
{
    if (self.node.isFolder)
    {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
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
        modifiedDateString = nodeStatus.localModificationDate ? relativeDateFromDate(nodeStatus.localModificationDate) : relativeDateFromDate(self.node.modifiedAt);
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
