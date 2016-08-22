/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

@interface RealmManager : NSObject

+ (RealmManager *)sharedManager;

- (RLMRealm *)createRealmWithName:(NSString *)realmName;
- (void)deleteRealmWithName:(NSString *)realmName;

- (RealmSyncNodeInfo *)syncNodeInfoForObjectWithId:(NSString *)objectId ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm;
- (RealmSyncError *)errorObjectForNodeWithId:(NSString *)nodeId ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm;
- (void)updateSyncNodeInfoWithId:(NSString *)objectId withNode:(AlfrescoNode *)node lastDownloadedDate:(NSDate *)downloadedDate syncContentPath:(NSString *)syncContentPath inRealm:(RLMRealm *)realm;
- (void)savePermissions:(AlfrescoPermissions *)permissions forNode:(AlfrescoNode *)node;

- (RLMRealmConfiguration *)configForName:(NSString *)name;
- (void)deleteRealmObject:(RLMObject *)objectToDelete inRealm:(RLMRealm *)realm;
- (void)deleteRealmObjects:(NSArray *)objectsToDelete inRealm:(RLMRealm *)realm;

- (RLMResults *)allSyncNodesInRealm:(RLMRealm *)realm;
- (RLMResults *)topLevelSyncNodesInRealm:(RLMRealm *)realm;
- (RLMResults *)topLevelFoldersInRealm:(RLMRealm *)realm;
- (RLMResults *)allDocumentsInRealm:(RLMRealm *)realm;

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account;
- (void)resetDefaultRealmConfiguration;

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inRealm:(RLMRealm *)realm;

@end
