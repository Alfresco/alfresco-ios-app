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

#import "RealmManager.h"

#import "UserAccount.h"
#import "AlfrescoNode+Sync.h"
#import "AccountManager.h"
#import "RealmSyncManager+CoreDataMigration.h"

@interface RealmManager()
@property (nonatomic, strong) RLMRealm *mainThreadRealm;
@end

@implementation RealmManager

+ (RealmManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
        
        if([AccountManager sharedManager].selectedAccount)
        {
            [sharedObject createMainThreadRealmWithCompletionBlock:nil];
        }
    });
    return sharedObject;
}

#pragma mark - Private methods

- (void)createMainThreadRealmWithCompletionBlock:(void (^)(void))completionBlock
{
    if ([NSThread isMainThread])
    {
        __weak typeof(self) weakSelf = self;
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.mainThreadRealm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if (completionBlock)
            {
                completionBlock();
            }
        });
    }
    else
    {
        __weak typeof(self) weakSelf = self;
        dispatch_sync(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            strongSelf.mainThreadRealm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:[AccountManager sharedManager].selectedAccount.accountIdentifier];
            if (completionBlock)
            {
                completionBlock();
            }
        });
    }
}

#pragma mark - RealmManagerProtocol
#pragma mark Realm management methods

- (void)deleteRealmWithName:(NSString *)realmName
{
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *realmFilepath = [[RealmSyncCore sharedSyncCore] configForName:realmName].fileURL.path;
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
    
    _mainThreadRealm = nil;
}

- (RLMRealm *)realmForCurrentThread
{
    RLMRealm *realm = nil;
    if(([NSThread isMainThread]) && (self.mainThreadRealm))
    {
        realm = self.mainThreadRealm;
    }
    else
    {
        realm = [RLMRealm defaultRealm];
    }
    
    return realm;
}

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account completionBlock:(void (^)(void))completionBlock
{
    [RLMRealmConfiguration setDefaultConfiguration:[[RealmSyncCore sharedSyncCore] configForName:account.accountIdentifier]];
    [self createMainThreadRealmWithCompletionBlock:completionBlock];
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSString *configFilePath = [[[config.fileURL.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

#pragma mark Realm object management

- (void)savePermissions:(AlfrescoPermissions *)permissions forNode:(AlfrescoNode *)node
{
    RLMRealm *realm = [RLMRealm defaultRealm];
    RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
    if(nodeInfo && !nodeInfo.invalidated)
    {
        [realm beginWriteTransaction];
        nodeInfo.permissions = [NSKeyedArchiver archivedDataWithRootObject:permissions];
        [realm commitWriteTransaction];
    }
}

- (void)deleteRealmObject:(RLMObject *)objectToDelete inRealm:(RLMRealm *)realm
{
    if(objectToDelete)
    {
        [realm beginWriteTransaction];
        [realm deleteObject:objectToDelete];
        [realm commitWriteTransaction];
    }
}

- (void)deleteRealmObjects:(NSArray *)objectsToDelete inRealm:(RLMRealm *)realm
{
    [realm beginWriteTransaction];
    for(RLMObject *object in objectsToDelete)
    {
        if ([object isKindOfClass:[RealmSyncNodeInfo class]] && !object.isInvalidated)
        {
            // Delete the associated RealmSyncError, if exists.
            RealmSyncError *realmSyncError = ((RealmSyncNodeInfo *)object).syncError;
            
            if (realmSyncError)
            {
                [realm deleteObject:realmSyncError];
            }
        }
        
        [realm deleteObject:object];
    }
    [realm commitWriteTransaction];
}

- (void)resolvedObstacleForDocument:(AlfrescoDocument *)document inRealm:(RLMRealm *)realm
{
    // once sync problem is resolved (document synced or saved) set its isUnfavoritedHasLocalChanges flag to NO so node is deleted later
    RealmSyncNodeInfo *nodeInfo = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:document ifNotExistsCreateNew:NO inRealm:realm];
    [realm beginWriteTransaction];
    nodeInfo.isRemovedFromSyncHasLocalChanges = NO;
    [realm commitWriteTransaction];
}

@end
