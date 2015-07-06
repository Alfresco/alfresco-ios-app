/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "FileFolderCollectionViewCell.h"
#import "SyncNodeStatus.h"
#import "BaseLayoutAttributes.h"

static NSString * const kAlfrescoNodeCellIdentifier = @"AlfrescoNodeCellIdentifier";

static CGFloat const FavoriteIconWidth = 14.0f;
static CGFloat const FavoriteIconRightSpace = 8.0f;
static CGFloat const SyncIconWidth = 14.0f;
static CGFloat const SyncIconRightSpace = 8.0f;

static CGFloat const kStatusIconsAnimationDuration = 0.2f;

@interface FileFolderCollectionViewCell ()

@property (nonatomic, strong) AlfrescoNode *node;
@property (nonatomic, strong) SyncNodeStatus *nodeStatus;
@property (nonatomic, assign) BOOL isFavorite;
@property (nonatomic, assign) BOOL isSyncNode;
@property (nonatomic, strong) NSString *nodeDetails;

@property (nonatomic, assign) BOOL isShowingDelete;
@property (nonatomic, assign) BOOL isSelectedInEditMode;

@property (nonatomic, strong) IBOutlet UIImageView *syncStatusImageView;
@property (nonatomic, strong) IBOutlet UIImageView *favoriteStatusImageView;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconWidthConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconWidthConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconRightSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconRightSpaceConstraint;

@property (nonatomic, strong) IBOutlet NSLayoutConstraint *favoriteIconTopSpaceConstraint;
@property (nonatomic, strong) IBOutlet NSLayoutConstraint *syncIconTopSpaceConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *leadingContentViewContraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trainlingContentViewContraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *accessoryViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *trailingAccessoryViewConstraint;
@property (weak, nonatomic) IBOutlet UIButton *accessoryViewButton;

@end


@implementation FileFolderCollectionViewCell

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

- (void)showDeleteAction:(BOOL)showDelete animated:(BOOL)animated
{
    double shiftAmount;
    if(showDelete)
    {
        shiftAmount = self.actionsViewWidthContraint.constant;
    }
    else
    {
        shiftAmount = 0.0;
    }
    
    [self layoutIfNeeded];
    self.leadingContentViewContraint.constant = -shiftAmount;
    self.trainlingContentViewContraint.constant = shiftAmount;
    
    if(animated)
    {
        [UIView animateWithDuration:0.40 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutIfNeeded];
        } completion:^(BOOL finished) {
            self.isShowingDelete = showDelete;
        }];
    }
    else
    {
        [self layoutIfNeeded];
    }
}

- (void)revealActionViewWithAmount:(CGFloat)amount
{
    [self layoutIfNeeded];
    self.leadingContentViewContraint.constant = amount;
    if(self.leadingContentViewContraint.constant > 0.0f)
    {
        self.leadingContentViewContraint.constant = 0.0f;
    }
    self.trainlingContentViewContraint.constant = -amount;
    if(self.trainlingContentViewContraint.constant < 0.0f)
    {
        self.trainlingContentViewContraint.constant = 0.0f;
    }
    [UIView animateWithDuration:0.20 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutIfNeeded];
    } completion:nil];
}

- (void)resetView
{
    [self layoutIfNeeded];
    self.leadingContentViewContraint.constant = 0.0;
    self.trainlingContentViewContraint.constant = 0.0;
    [UIView animateWithDuration:0.20 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.isShowingDelete = NO;
    }];
}

- (void)showEditMode:(BOOL)showEdit selected:(BOOL)isSelected animated:(BOOL)animated
{
    double shiftAmount;
    if(showEdit)
    {
        shiftAmount = 40.0;
    }
    else
    {
        shiftAmount = 0.0;
    }
    
    [self wasSelectedInEditMode:isSelected];
    [self layoutIfNeeded];
    self.leadingContentViewContraint.constant = shiftAmount;
    self.trainlingContentViewContraint.constant = -shiftAmount;
    
    if(animated)
    {
        [UIView animateWithDuration:0.40 delay:0.0 options:UIViewAnimationOptionCurveEaseInOut animations:^{
            [self layoutIfNeeded];
        } completion:nil];
    }
    else
    {
        [self layoutIfNeeded];
    }
}

- (void) showEditMode:(BOOL)showEdit animated:(BOOL)animated
{
    [self showEditMode:showEdit selected:NO animated:animated];
}

- (void) wasSelectedInEditMode:(BOOL)wasSelected
{
    self.isSelectedInEditMode = wasSelected;
    if(wasSelected)
    {
        [self.editImageView setImage:[[UIImage imageNamed:@"cell-button-checked-filled.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate]];
        self.editImageView.tintColor = [UIColor appTintColor];
        self.editView.backgroundColor = [UIColor selectedCollectionViewCellBackgroundColor];
        self.content.backgroundColor = [UIColor selectedCollectionViewCellBackgroundColor];
    }
    else
    {
        [self.editImageView setImage:[UIImage imageNamed:@"cell-button-unchecked.png"]];
        self.editView.backgroundColor = [UIColor whiteColor];
        self.content.backgroundColor = [UIColor whiteColor];
    }
    
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
    
    if (statusImageName)
    {
        self.syncStatusImageView.image = [UIImage imageNamed:statusImageName];
        self.syncStatusImageView.highlightedImage = [UIImage imageNamed:[statusImageName stringByAppendingString:@"-highlighted"]];
    }
}

- (void)setAccessoryViewForState:(SyncStatus)status
{
    [self layoutIfNeeded];
    if (self.node.isFolder)
    {
        UIImage *buttonImage = [[UIImage imageNamed:@"cell-button-info.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.accessoryViewButton.tintColor = [UIColor appTintColor];
        [self.accessoryViewButton setTitle:@"" forState:UIControlStateNormal];
        [self.accessoryViewButton setImage:buttonImage forState:UIControlStateNormal];
        [self.accessoryViewButton setShowsTouchWhenHighlighted:YES];
        [self.accessoryViewButton addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
        self.accessoryViewWidthConstraint.constant = 50.0;
    }
    else
    {
        UIImage *buttonImage;
        
        switch (status)
        {
            case SyncStatusLoading:
                buttonImage = [[UIImage imageNamed:@"sync-button-stop.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.accessoryViewButton setTitle:@"" forState:UIControlStateNormal];
                self.accessoryViewButton.tintColor = [UIColor appTintColor];
                break;
                
            case SyncStatusFailed:
                buttonImage = [[UIImage imageNamed:@"sync-button-error.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
                [self.accessoryViewButton setTitle:@"" forState:UIControlStateNormal];
                self.accessoryViewButton.tintColor = [UIColor syncFailedColor];
                break;
                
            default:
                self.accessoryViewWidthConstraint.constant = 0.0;
                break;
        }
        
        if (buttonImage)
        {
            [self.accessoryViewButton setImage:buttonImage forState:UIControlStateNormal];
            [self.accessoryViewButton setShowsTouchWhenHighlighted:YES];
            [self.accessoryViewButton addTarget:self action:@selector(accessoryButtonTapped:withEvent:) forControlEvents:UIControlEventTouchUpInside];
            self.accessoryViewWidthConstraint.constant = buttonImage.size.width;
        }
    }
    [self layoutIfNeeded];
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

#pragma mark - Overriden methods
- (void)applyLayoutAttributes:(BaseLayoutAttributes *)layoutAttributes
{
    [self layoutIfNeeded];
    self.separatorHeightConstraint.constant = 1/[[UIScreen mainScreen] scale];
    [self layoutIfNeeded];
    if(layoutAttributes.showDeleteButton && !layoutAttributes.isEditing)
    {
        [self showDeleteAction:layoutAttributes.showDeleteButton animated:layoutAttributes.animated];
    }
    else
    {
        [self showEditMode:layoutAttributes.isEditing selected:layoutAttributes.isSelectedInEditMode animated:layoutAttributes.animated];
    }
}

#pragma mark - Private Methods

- (void)accessoryButtonTapped:(UIControl *)button withEvent:(UIEvent *)event
{
    [self.accessoryViewDelegate didTapCollectionViewCellAccessorryView:self.node];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end
