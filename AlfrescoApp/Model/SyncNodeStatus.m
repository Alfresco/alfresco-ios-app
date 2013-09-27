//
//  SyncNodeStatus.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncNodeStatus.h"

static NSString * const kNodeIdKey = @"nodeId";
static NSString * const kPropertyChangedKey = @"propertyChange";

NSString * const kStatus = @"status";
NSString * const kActivityType = @"activityType";
NSString * const kBytesTransfered = @"bytesTransfered";

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
    if ([keyPath isEqualToString:kStatus])
    {
        [self sendNotificationForPropertyChange:kStatus];
    }
    else if ([keyPath isEqualToString:kActivityType])
    {
        [self sendNotificationForPropertyChange:kActivityType];
    }
    else if ([keyPath isEqualToString:kBytesTransfered])
    {
        [self sendNotificationForPropertyChange:kBytesTransfered];
    }
}

- (void)sendNotificationForPropertyChange:(NSString *)property
{
    NSDictionary *info = @{kNodeIdKey : self.nodeId, kPropertyChangedKey : property};
    [[NSNotificationCenter defaultCenter] postNotificationName:kSyncStatusChangeNotification object:self userInfo:info];
}

@end
