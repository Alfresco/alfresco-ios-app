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
  
@class SyncError, SyncNodeInfo, SyncAccount;

@interface SyncNodeInfo : NSManagedObject

@property (nonatomic, retain) NSNumber *isFolder;
@property (nonatomic, retain) NSNumber *isTopLevelSyncNode;
@property (nonatomic, retain) NSNumber *isRemovedFromSyncHasLocalChanges;
@property (nonatomic, retain) NSDate *lastDownloadedDate;
@property (nonatomic, retain) NSData *node;
@property (nonatomic, retain) NSData *permissions;
@property (nonatomic, retain) NSNumber *reloadContent;
@property (nonatomic, retain) NSString *syncContentPath;
@property (nonatomic, retain) NSString *syncNodeInfoId;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) SyncAccount *account;
@property (nonatomic, retain) NSSet *nodes;
@property (nonatomic, retain) SyncNodeInfo *parentNode;
@property (nonatomic, retain) SyncError *syncError;
@end

@interface SyncNodeInfo (CoreDataGeneratedAccessors)

- (void)addNodesObject:(SyncNodeInfo *)value;
- (void)removeNodesObject:(SyncNodeInfo *)value;
- (void)addNodes:(NSSet *)values;
- (void)removeNodes:(NSSet *)values;

@end
