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
 
#import "SyncNodeInfo.h"
#import "SyncError.h"
#import "SyncNodeInfo.h"
#import "SyncAccount.h"


@implementation SyncNodeInfo

@dynamic isFolder;
@dynamic isTopLevelSyncNode;
@dynamic isRemovedFromSyncHasLocalChanges;
@dynamic lastDownloadedDate;
@dynamic node;
@dynamic permissions;
@dynamic reloadContent;
@dynamic syncContentPath;
@dynamic syncNodeInfoId;
@dynamic title;
@dynamic account;
@dynamic nodes;
@dynamic parentNode;
@dynamic syncError;

@end
