//
//  SyncNodeStatus.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

extern NSString * const kSyncStatusNodeIdKey;
extern NSString * const kSyncStatusPropertyChangedKey;
extern NSString * const kSyncStatusChangeKey;
extern NSString * const kSyncLocalModificationDate;

extern NSString * const kSyncStatus;
extern NSString * const kSyncActivityType;
extern NSString * const kSyncBytesTransfered;
extern NSString * const kSyncTotalSize;
extern NSString * const kSyncIsFavorite;

typedef NS_ENUM(NSInteger, SyncStatus)
{
    SyncStatusFailed,
    SyncStatusSuccessful,
    SyncStatusLoading,
    SyncStatusWaiting,
    SyncStatusOffline,
    SyncStatusCancelled,
    SyncStatusDisabled,
    SyncStatusRemoved
};

typedef NS_ENUM(NSInteger, SyncActivityType)
{
    SyncActivityTypeDownload,
    SyncActivityTypeUpload,
    SyncActivityTypeIdle
};

@interface SyncNodeStatus : NSObject

- (id)initWithNodeId:(NSString *)nodeId;

@property (nonatomic, strong) NSString *nodeId;
@property (nonatomic, assign) SyncStatus status;
@property (nonatomic, assign) SyncActivityType activityType;
@property (nonatomic, assign) unsigned long long bytesTransfered;
@property (nonatomic, assign) unsigned long long totalBytesToTransfer;

@property (nonatomic, strong) NSDate *localModificationDate;
@property (nonatomic, assign) unsigned long long totalSize;

@end
