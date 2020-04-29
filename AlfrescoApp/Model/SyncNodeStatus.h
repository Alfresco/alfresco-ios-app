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
