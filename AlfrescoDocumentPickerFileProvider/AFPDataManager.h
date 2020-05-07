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

#import <Foundation/Foundation.h>
#import "AFPItemMetadata.h"
#import "RealmSyncCore.h"
#import "AFPItem.h"
@class UserAccount;

@interface AFPDataManager : NSObject

+ (instancetype)sharedManager;
- (RLMRealm *)realm;

- (void)saveLocalFilesItem;
- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account;
- (AFPItemMetadata *)saveNode:(AlfrescoNode *)node parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
- (AFPItemMetadata *)saveSite:(AlfrescoSite *)site parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
- (AFPItemMetadata *)saveItem:(AFPItem *)item needsUpload:(BOOL)needUpload fileURL:(NSURL *)fileURL;
- (void)removeItemMetadataForIdentifier:(NSString *)identifier;
- (void)cleanMenuItemsForAccount:(UserAccount *)account;
- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)itemIdentifier downloaded:(BOOL)isDownloaded;
- (void)updateMenuItemsWithHiddenCollectionOfViewConfigs:(NSArray *)viewConfigs forAccount:(UserAccount *)account;
- (void)updateMenuItemsWithVisibleCollectionOfViewConfigs:(NSArray *)viewConfigs forAccount:(UserAccount *)account;

- (AFPItemMetadata *)localFilesItem;
- (RLMResults<AFPItemMetadata *> *)menuItemsForAccount:(NSString *)accountIdentifier;
- (RLMResults<AFPItemMetadata *> *)menuItemsForParentIdentifier:(NSString *)itemIdentifier;
- (AFPItemMetadata *)metadataItemForIdentifier:(NSFileProviderItemIdentifier)identifier;
- (RealmSyncNodeInfo *)syncItemForId:(NSFileProviderItemIdentifier)identifier;

- (NSFileProviderItemIdentifier)parentItemIdentifierOfSyncedNode:(RealmSyncNodeInfo *)syncedNode fromAccountIdentifier:(NSString *)accountIdentifier;
- (NSFileProviderItemIdentifier)itemIdentifierOfSyncedNodeWithURL:(NSURL *)syncedNodeURL;
- (RLMResults<RealmSyncNodeInfo *> *)syncItemsInParentNodeWithSyncId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier;
- (RealmSyncNodeInfo *)syncItemForId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier;
- (void)cleanRemovedChildrenFromSyncFolder:(AlfrescoNode *)syncFolder usingUpdatedChildrenIdList:(NSArray *)childrenIdList fromAccountIdentifier:(NSString *)accountIdentifier;
- (void)updateSyncDocument:(AlfrescoDocument *)oldDocument withAlfrescoNode:(AlfrescoDocument *)document fromPath:(NSString *)path fromAccountIdentifier:(NSString *)accountIdentifier;
- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)metadataIdentifier
      withSyncDocument:(AlfrescoDocument *)alfrescoDocument;
- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)metadataIdentifier
          withFileName:(NSString *)updatedFileName;

@end
