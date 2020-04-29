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

#import <Realm/Realm.h>
#import <AlfrescoSDK-iOS/AlfrescoSDK.h>

@class RealmSyncError;

@interface RealmSyncNodeInfo : RLMObject

@property (nonatomic) BOOL isFolder;
@property (nonatomic) BOOL isTopLevelSyncNode;
@property (nonatomic) BOOL isRemovedFromSyncHasLocalChanges;
@property (nonatomic, strong) NSDate *lastDownloadedDate;
@property (nonatomic, strong) NSData *node;
@property (nonatomic, strong) NSData *permissions;
@property (nonatomic) BOOL reloadContent;
@property (nonatomic, strong) NSString *syncContentPath;
@property (nonatomic, strong) NSString *syncNodeInfoId;
@property (nonatomic, strong) NSString *title;

@property (nonatomic) RealmSyncError *syncError;
@property (nonatomic) RealmSyncNodeInfo *parentNode;
//Inverse of parentNode relation
@property (readonly) RLMLinkingObjects *nodes;
@property (readonly) AlfrescoNode *alfrescoNode;
@property (readonly) AlfrescoPermissions *alfrescoPermissions;

@end

// This protocol enables typed collections. i.e.:
// RLMArray<RealmSyncNodeInfo>
RLM_ARRAY_TYPE(RealmSyncNodeInfo)
