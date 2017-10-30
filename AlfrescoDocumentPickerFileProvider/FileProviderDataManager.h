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
#import "FileProviderAccountInfo.h"
#import "RealmSyncNodeInfo.h"
#import "RealmSyncError.h"
@class UserAccount;

@interface FileProviderDataManager : NSObject

+ (instancetype)sharedManager;
- (RLMRealm *)realm;

- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account;
- (void)cleanMenuItemsForAccount:(UserAccount *)account;
- (void)saveNode:(AlfrescoNode *)node parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;
- (void)saveSite:(AlfrescoSite *)site parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier;

- (RLMResults<FileProviderAccountInfo *> *)menuItemsForAccount:(NSString *)accountIdentifier;
- (RLMResults<FileProviderAccountInfo *> *)menuItemsForParentIdentifier:(NSString *)itemIdentifier;
- (FileProviderAccountInfo *)itemForIdentifier:(NSFileProviderItemIdentifier)identifier;

- (RLMResults<RealmSyncNodeInfo *> *)syncItemsInNodeWithId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier;
- (NSFileProviderItemIdentifier)parentItemIdentifierOfSyncedNode:(RealmSyncNodeInfo *)syncedNode fromAccountIdentifier:(NSString *)accountIdentifier;

@end
