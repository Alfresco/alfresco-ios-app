//
//  SyncNodeStatus.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncNodeStatus.h"

static NSString * const kNodeIdKey = @"nodeId";
static NSString * const kPropertyChangedKey = @"propertyChanged";

NSString * const kSyncStatus = @"syncStatus";
NSString * const kSyncActivityType = @"syncActivityType";
NSString * const kSyncBytesTransfered = @"syncBytesTransfered";

@implementation SyncNodeStatus

- (id)initWithNodeId:(NSString *)nodeId
{
    self = [super init];
    if (self)
    {
        self.nodeId = nodeId;
        self.status = SyncStatusDisabled;
        self.activityType = SyncActivityTypeIdle;
    }
    return self;
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kSyncStatus])
    {
        [self sendNotificationForPropertyChange:kSyncStatus];
    }
    else if ([keyPath isEqualToString:kSyncActivityType])
    {
        [self sendNotificationForPropertyChange:kSyncActivityType];
    }
    else if ([keyPath isEqualToString:kSyncBytesTransfered])
    {
        [self sendNotificationForPropertyChange:kSyncBytesTransfered];
    }
}

- (void)sendNotificationForPropertyChange:(NSString *)property
{
    NSDictionary *info = @{kNodeIdKey : self.nodeId, kPropertyChangedKey : property};
    [[NSNotificationCenter defaultCenter] postNotificationName:kSyncStatusChangeNotification object:self userInfo:info];
}

@end
