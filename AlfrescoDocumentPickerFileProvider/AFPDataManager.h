/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>
#import <Realm/Realm.h>
#import "AFPItemMetadata.h"
#import "RealmSyncNodeInfo.h"
#import "RealmSyncError.h"
#import "AFPItem.h"
@class UserAccount;

@interface AFPDataManager : NSObject

+ (instancetype)sharedManager;
- (RLMRealm *)realm;
- (RLMRealm *)realmForSyncWithAccountIdentifier:(NSString *)accountIdentifier;

- (void)saveLocalFilesItem;
- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account;
- (AFPItemMetadata *)saveNode:(AlfrescoNode *)node parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
- (AFPItemMetadata *)saveSite:(AlfrescoSite *)site parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
- (AFPItemMetadata *)saveItem:(AFPItem *)item;
- (void)cleanMenuItemsForAccount:(UserAccount *)account;
- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)itemIdentifier downloaded:(BOOL)isDownloaded;

- (AFPItemMetadata *)localFilesItem;
- (RLMResults<AFPItemMetadata *> *)menuItemsForAccount:(NSString *)accountIdentifier;
- (RLMResults<AFPItemMetadata *> *)menuItemsForParentIdentifier:(NSString *)itemIdentifier;
- (id)dbItemForIdentifier:(NSFileProviderItemIdentifier)identifier;

- (RLMResults<RealmSyncNodeInfo *> *)syncItemsInNodeWithId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier;
- (NSFileProviderItemIdentifier)parentItemIdentifierOfSyncedNode:(RealmSyncNodeInfo *)syncedNode fromAccountIdentifier:(NSString *)accountIdentifier;
- (NSFileProviderItemIdentifier)itemIdentifierOfSyncedNodeWithURL:(NSURL *)syncedNodeURL;
- (RealmSyncNodeInfo *)syncItemForId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier;
- (RealmSyncNodeInfo *)syncItemForId:(NSString *)identifier inRealm:(RLMRealm *)realm;
- (void)updateSyncDocumentWithId:(NSString *)identifier fromAccountIdentifier:(NSString *)accountIdentifier withAlfrescoNode:(AlfrescoDocument *)document;
- (void)didUploadDocument:(AlfrescoDocument *)alfDocument fromFilePath:(NSString *)tempFilePath toSyncedFolder:(AlfrescoFolder *)folder withFolderItemIdentifier:(NSFileProviderItemIdentifier)folderItemIdentifier;

@end
