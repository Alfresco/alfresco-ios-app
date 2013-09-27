//
//  SyncNodeStatus.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

extern NSString * const kStatus;
extern NSString * const kActivityType;
extern NSString * const kBytesTransfered;

typedef enum
{
    SyncStatusFailed,
    SyncStatusSuccessful,
    SyncStatusLoading,
    SyncStatusWaiting,
    SyncStatusOffline,
    SyncStatusCancelled,
    SyncStatusDisabled,
} Status;

typedef enum
{
    SyncActivityTypeDownload,
    SyncActivityTypeUpload,
    SyncActivityTypeIdle
} ActivityType;

@interface SyncNodeStatus : NSObject

- (id)initWithNodeId:(NSString *)nodeId;

@property (nonatomic, strong) NSString *nodeId;
@property (nonatomic, assign) Status status;
@property (nonatomic, assign) ActivityType activityType;
@property (nonatomic, assign) unsigned long long bytesTransfered;

@end
