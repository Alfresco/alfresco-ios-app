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
#import <Realm/Realm.h>
#import "RealmSyncError.h"
#import "RealmSyncNodeInfo.h"
#import "AlfrescoFileManager+Extensions.h"

typedef NS_ENUM(NSUInteger, NodesType) {
    NodesTypeDocuments,
    NodesTypeFolders,
    NodesTypeDocumentsAndFolders,
};

@interface RealmSyncCore : NSObject

+ (RealmSyncCore *)sharedSyncCore;

- (RLMRealm *)realmWithIdentifier:(NSString *)identifier;
- (RLMRealmConfiguration *)configForName:(NSString *)name;

- (RLMResults *)allSyncNodesInRealm:(RLMRealm *)realm;
- (RLMResults *)topLevelSyncNodesInRealm:(RLMRealm *)realm;
- (RLMResults *)topLevelFoldersInRealm:(RLMRealm *)realm;
- (RLMResults *)allDocumentsInRealm:(RLMRealm *)realm;
- (NSArray *)allNodesWithType:(NodesType)nodesType inFolder:(AlfrescoFolder *)folder recursive:(BOOL)recursive includeTopLevelNodes:(BOOL)shouldIncludeTopLevelNodes inRealm:(RLMRealm *)realm;

- (RealmSyncNodeInfo *)syncNodeInfoForObject:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm;
- (RealmSyncNodeInfo *)syncNodeInfoForId:(NSString *)nodeSyncId inRealm:(RLMRealm *)realm;
- (RealmSyncNodeInfo *)createSyncNodeInfoForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm;
- (RealmSyncError *)errorObjectForNode:(AlfrescoNode *)node ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm;
- (NSString *)syncIdentifierForNode:(AlfrescoNode *)node;
- (void)updateSyncNodeInfoForNodeWithSyncId:(NSString *)nodeSyncId alfrescoNode:(AlfrescoNode *)node lastDownloadedDate:(NSDate *)downloadedDate syncContentPath:(NSString *)syncContentPath inRealm:(RLMRealm *)realm;
- (void)didUploadNode:(AlfrescoNode *)node fromPath:(NSString *)tempPath toFolder:(AlfrescoFolder *)folder forAccountIdentifier:(NSString *)accountIdentifier;
- (void)didUploadNewVersionForDocument:(AlfrescoDocument *)document updatedDocument:(AlfrescoDocument *)updatedDocument fromPath:(NSString *)path forAccountIdentifier:(NSString *)accountIdentifier;
- (BOOL)isNode:(AlfrescoNode *)node inSyncListInRealm:(RLMRealm *)realm;
- (NSString *)contentPathForNode:(AlfrescoNode *)node forAccountIdentifier:(NSString *)accountIdentifier;
- (NSString *)syncNameForNode:(AlfrescoNode *)node inRealm:(RLMRealm *)realm;
- (NSString *)syncContentDirectoryPathForAccountWithId:(NSString *)accountIdentifier;

- (void)initiateContentMigrationProcessForAccounts:(NSArray *)accounts;
- (BOOL)isContentMigrationNeeded;

@end
