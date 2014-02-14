//
//  SyncNodeStatus.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncNodeStatus.h"

NSString * const kSyncStatusNodeIdKey = @"nodeId";
NSString * const kSyncStatusPropertyChangedKey = @"propertyChanged";
NSString * const kSyncStatusChangeKey = @"change";

NSString * const kSyncStatus = @"status";
NSString * const kSyncActivityType = @"activityType";
NSString * const kSyncBytesTransfered = @"bytesTransfered";
NSString * const kSyncTotalSize = @"totalSize";
NSString * const kSyncLocalModificationDate = @"localModificationDate";

@implementation SyncNodeStatus

- (id)initWithNodeId:(NSString *)nodeId
{
    self = [super init];
    if (self)
    {
        self.nodeId = nodeId;
        self.status = SyncStatusDisabled;
        self.activityType = SyncActivityTypeIdle;
        self.totalSize = 0;
        
        [self addObserver:self forKeyPath:kSyncStatus options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kSyncActivityType options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kSyncBytesTransfered options:NSKeyValueObservingOptionNew context:nil];
        [self addObserver:self forKeyPath:kSyncTotalSize options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil];
        [self addObserver:self forKeyPath:kSyncLocalModificationDate options:NSKeyValueObservingOptionNew context:nil];
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncStatus])
    {
        [self sendNotificationForPropertyChange:kSyncStatus change:nil];
    }
    else if ([keyPath isEqualToString:kSyncActivityType])
    {
        [self sendNotificationForPropertyChange:kSyncActivityType change:nil];
    }
    else if ([keyPath isEqualToString:kSyncBytesTransfered])
    {
        [self sendNotificationForPropertyChange:kSyncBytesTransfered change:nil];
    }
    else if ([keyPath isEqualToString:kSyncTotalSize])
    {
        [self sendNotificationForPropertyChange:kSyncTotalSize change:change];
    }
    else if ([keyPath isEqualToString:kSyncLocalModificationDate])
    {
        [self sendNotificationForPropertyChange:kSyncLocalModificationDate change:nil];
    }
}

- (void)sendNotificationForPropertyChange:(NSString *)property change:(NSDictionary *)change
{
    NSDictionary *info = nil;
    if (change)
    {
        info = @{kSyncStatusNodeIdKey : self.nodeId, kSyncStatusPropertyChangedKey : property, kSyncStatusChangeKey : change};
    }
    else
    {
        info = @{kSyncStatusNodeIdKey : self.nodeId, kSyncStatusPropertyChangedKey : property};
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:kSyncStatusChangeNotification object:self userInfo:info];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:kSyncStatus];
    [self removeObserver:self forKeyPath:kSyncActivityType];
    [self removeObserver:self forKeyPath:kSyncBytesTransfered];
    [self removeObserver:self forKeyPath:kSyncTotalSize];
    [self removeObserver:self forKeyPath:kSyncLocalModificationDate];
}

@end
