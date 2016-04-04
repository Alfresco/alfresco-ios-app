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

#import "RealmManager.h"

@implementation RealmManager

+ (RealmManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (RLMRealm *)createRealmWithName:(NSString *)realmName
{
    RLMRealmConfiguration *config = [self configForName:realmName];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        NSException *exception = [NSException exceptionWithName:kFailedToCreateRealmDatabase reason:error.description userInfo:@{kRealmSyncErrorKey : error}];
        [exception raise];
    }
    
    return realm;
}

- (void)deleteRealmWithName:(NSString *)realmName
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *realmFilepath = [self configForName:realmName].path;
    NSArray<NSString *> *realmFilePaths = @[
                                            realmFilepath,
                                            [realmFilepath stringByAppendingPathExtension:@"lock"],
                                            [realmFilepath stringByAppendingPathExtension:@"log_a"],
                                            [realmFilepath stringByAppendingPathExtension:@"log_b"],
                                            [realmFilepath stringByAppendingPathExtension:@"note"]
                                            ];
    for (NSString *path in realmFilePaths) {
        NSError *error = nil;
        [manager removeItemAtPath:path error:&error];
        if (error) {
            // handle error
        }
    }
}

- (RealmSyncNodeInfo *)syncNodeInfoForObjectWithId:(NSString *)objectId inRealm:(RLMRealm *)realm
{
    RealmSyncNodeInfo *nodeInfo = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId == %@", objectId].firstObject;
    return nodeInfo;
}

- (RLMRealmConfiguration *)configForName:(NSString *)name
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:name] stringByAppendingPathExtension:@"realm"];
    return config;
}

- (RealmSyncError *)errorObjectForNodeWithId:(NSString *)nodeId ifNotExistsCreateNew:(BOOL)createNew inRealm:(RLMRealm *)realm
{
    RealmSyncError *syncError = nil;
    
    if (nodeId)
    {
        RealmSyncNodeInfo *nodeInfo = [self syncNodeInfoForObjectWithId:nodeId inRealm:realm];
        syncError = nodeInfo.syncError;
        
        if (createNew && !syncError)
        {
            syncError = [self createSyncErrorInRealm:realm];
            syncError.errorId = nodeId;
        }
    }
    return syncError;
}

- (RealmSyncError *)createSyncErrorInRealm:(RLMRealm *)realm
{
    RealmSyncError *error = [RealmSyncError new];
    [realm beginWriteTransaction];
    [realm addObject:error];
    [realm commitWriteTransaction];
    return error;
    
}

- (void)deleteRealmObject:(RLMObject *)objectToDelete inRealm:(RLMRealm *)realm
{
    [realm beginWriteTransaction];
    [realm deleteObject:objectToDelete];
    [realm commitWriteTransaction];
}

@end
