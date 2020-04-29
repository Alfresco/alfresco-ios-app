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
        self.status = SyncStatusSuccessful;
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
    
    dispatch_async(dispatch_get_main_queue(), ^{
        [[NSNotificationCenter defaultCenter] postNotificationName:kSyncStatusChangeNotification object:self userInfo:info];
    });
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
