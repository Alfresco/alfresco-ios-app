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

NSString * const kAlfrescoNodeCellIdentifier = @"AlfrescoNodeCellIdentifier";

@interface AlfrescoNodeCell()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) SyncNodeStatus *nodeStatus;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isSyncNode;
@property (nonatomic, strong) NSString *nodeDetails;
@property (nonatomic, strong) UIImageView *infoIcon1;
@property (nonatomic, strong) UIImageView *infoIcon2;
@property (nonatomic, strong) UIImageView *syncStatusImageView;
@property (nonatomic, strong) UIImageView *favoriteStatusImageView;

@end

@implementation AlfrescoNodeCell

- (id)initWithFrame:(CGRect)frame
{
    self = nil;
    NSArray *subViews = [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AlfrescoNodeCell class]) owner:self options:nil];
    if (subViews.count > 0)
    {
        self = (AlfrescoNodeCell *)[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AlfrescoNodeCell class]) owner:self options:nil][0];
        
        static CGFloat const infoIconRightMargin = 8.0f;
        static CGFloat const infoIconTopMargin = 4.0f;
        static CGFloat const infoIconFrameWidth = 14.0f;
        static CGFloat const infoIconFrameHeight = 14.0f;
        static CGFloat const infoIconHorizontalSpace = 6.0f;
        
        CGFloat iconXPosition = frame.size.width;
        
        iconXPosition = iconXPosition - infoIconFrameWidth - infoIconRightMargin;
        _infoIcon1 = [[UIImageView alloc] initWithFrame:CGRectMake(iconXPosition, infoIconTopMargin, infoIconFrameWidth, infoIconFrameHeight)];
        [self addSubview:_infoIcon1];
        
        iconXPosition = iconXPosition - infoIconFrameWidth - infoIconHorizontalSpace;
        _infoIcon2 = [[UIImageView alloc] initWithFrame:CGRectMake(iconXPosition, infoIconTopMargin, infoIconFrameWidth, infoIconFrameHeight)];
        [self addSubview:_infoIcon2];
    }
    return self;
}

- (void)updateCellInfoWithNode:(AlfrescoNode *)node nodeStatus:(SyncNodeStatus *)nodeStatus
{
    self.node = node;
    self.nodeStatus = nodeStatus;
    self.filename.text = node.name;
    [self updateNodeDetails:nodeStatus];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(statusChanged:)
                                                 name:kSyncStatusChangeNotification
                                               object:nil];
}

- (void)updateStatusIconsIsSyncNode:(BOOL)isSyncNode isFavoriteNode:(BOOL)isFavorite
{
    self.isSyncNode = isSyncNode;
    self.isFavorite = isFavorite;
    
    self.infoIcon1.image = nil;
    self.infoIcon1.highlightedImage = nil;
    self.infoIcon2.image = nil;
    self.infoIcon2.highlightedImage = nil;
    
    UIImageView *nextInfoIconView = self.infoIcon1;
    
    if (self.isSyncNode)
    {
        self.syncStatusImageView = nextInfoIconView;
        nextInfoIconView = self.infoIcon2;
    }
    if (self.isFavorite)
    {
        self.favoriteStatusImageView = nextInfoIconView;
        self.favoriteStatusImageView.image = [UIImage imageNamed:@"status-favourite.png"];
        self.favoriteStatusImageView.highlightedImage = [UIImage imageNamed:@"status-favourite-highlighted.png"];
    }
    
    [self updateCellWithNodeStatus:self.nodeStatus propertyChanged:kSyncStatus];
}

#pragma mark - Notification Methods

- (void)statusChanged:(NSNotification *)notification
{
    NSDictionary *info = notification.userInfo;
    if ([[info objectForKey:kSyncStatusNodeIdKey] isEqualToString:self.node.identifier])
    {
        SyncNodeStatus *nodeStatus = notification.object;
        self.nodeStatus = nodeStatus;
        NSString *propertyChanged = [info objectForKey:kSyncStatusPropertyChangedKey];
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!self.isSyncNode)
            {
                [self updateStatusIconsIsSyncNode:YES isFavoriteNode:self.isFavorite];
            }
            [self updateCellWithNodeStatus:nodeStatus propertyChanged:propertyChanged];
        });
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
    else if ([propertyChanged isEqualToString:kSyncIsFavorite])
    {
        [self updateStatusIconsIsSyncNode:self.isSyncNode isFavoriteNode:nodeStatus.isFavorite];
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
    UIImage *buttonImage = nil;
    UIButton *button = nil;
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.accessoryView = nil;
    
    switch (status)
    {
        case SyncStatusLoading:
            buttonImage = [UIImage imageNamed:@"stop-transfer.png"];
            break;
            
        case SyncStatusFailed:
            buttonImage = [UIImage imageNamed:@"ui-button-bar-badge-error.png"];
            break;
            
        default:
            break;
    }
    
    if (buttonImage)
    {
        button = [UIButton buttonWithType:UIButtonTypeCustom];
        [button setFrame:CGRectMake(0, 0, buttonImage.size.width, buttonImage.size.height)];
        [button setImage:buttonImage forState:UIControlStateNormal];
        [button setShowsTouchWhenHighlighted:YES];
        
        [button addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
    }
    
    if (self.node.isFolder)
    {
        self.accessoryType = UITableViewCellAccessoryDetailButton;
    }
    else
    {
        [self setAccessoryView:button];
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
    if (nodeStatus.status == SyncStatusWaiting)
    {
        self.details.text = NSLocalizedString(@"sync.state.waiting-to-sync", @"waiting to sync");
    }
    else if (nodeStatus.status == SyncStatusFailed)
    {
        self.details.text = NSLocalizedString(@"sync.state.failed-to-sync", @"failed to sync");
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
