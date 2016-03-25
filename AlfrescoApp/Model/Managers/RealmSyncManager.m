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

#import "RealmSyncManager.h"

#import "UserAccount.h"
#import "AccountManager.h"
#import "AccountSyncProgress.h"
#import "SyncNodeStatus.h"
#import "SyncOperation.h"

@interface RealmSyncManager()

@property (nonatomic, strong) NSMutableDictionary *syncQueues;
@property (nonatomic, strong) NSMutableDictionary *syncOperations;

@end

@implementation RealmSyncManager

#pragma mark - Singleton
+ (RealmSyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

#pragma mark - Public methods
- (RLMRealm *)createRealmForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [self configPathForAccount:account];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        NSException *exception = [NSException exceptionWithName:kFailedToCreateRealmDatabase reason:error.description userInfo:@{kRealmSyncErrorKey : error}];
        [exception raise];
    }
    
    return realm;
}

- (void)deleteRealmForAccount:(UserAccount *)account
{
    if(account == [AccountManager sharedManager].selectedAccount)
    {
        [self resetDefaultRealmConfiguration];
    }
    
    NSFileManager *manager = [NSFileManager defaultManager];
    NSString *realmFilepath = [self configPathForAccount:account];
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

- (void)disableSyncForAccount:(UserAccount*)account fromViewController:(UIViewController *)presentingViewController cancelBlock:(void (^)(void))cancelBlock completionBlock:(void (^)(void))completionBlock
{
    if([self isCurrentlySyncing])
    {
        UIAlertController *confirmAlert = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"action.pendingoperations.title", @"Pending sync operations") message:NSLocalizedString(@"action.pendingoperations.message", @"Stop pending operations") preferredStyle:UIAlertControllerStyleAlert];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.cancel", @"Cancel") style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
            cancelBlock();
        }]];
        [confirmAlert addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"action.pendingoperations.confirm", @"Confirm") style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            [self cancelAllSyncOperations];
            [self deleteRealmForAccount:account];
            completionBlock();
        }]];
        
        [presentingViewController presentViewController:confirmAlert animated:YES completion:nil];
    }
    else
    {
        [self deleteRealmForAccount:account];
        completionBlock();
    }
}

#pragma mark - Sync Utilities
- (void)cancelAllSyncOperations
{
    NSArray *syncOperationKeys = [self.syncOperations allKeys];
    
    for (NSString *accountId in syncOperationKeys)
    {
        [self cancelAllSyncOperationsForAccountWithId:accountId];
    }
}

- (void)cancelAllSyncOperationsForAccountWithId:(NSString *)accountId
{
//    NSArray *syncDocumentIdentifiers = [self.syncOperations[accountId] allKeys];
//    
//    for (NSString *documentIdentifier in syncDocumentIdentifiers)
//    {
//        [self cancelSyncForDocumentWithIdentifier:documentIdentifier inAccountWithId:accountId];
//    }
//    
//    AccountSyncProgress *syncProgress = self.accountsSyncProgress[accountId];
//    syncProgress.totalSyncSize = 0;
//    syncProgress.syncProgressSize = 0;
}

- (BOOL)isCurrentlySyncing
{
    __block BOOL isSyncing = NO;
    
    [self.syncQueues enumerateKeysAndObjectsUsingBlock:^(id key, NSOperationQueue *queue, BOOL *stop) {
        
        isSyncing = queue.operationCount > 0;
        
        if (isSyncing)
        {
            *stop = YES;
        }
    }];
    
    return YES;
}

#pragma mark - Realm Utilities
- (void)changeDefaultConfigurationForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [self configPathForAccount:account];
    
    // Set this as the configuration used for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

- (NSString *)configPathForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:account.accountIdentifier] stringByAppendingPathExtension:@"realm"];
    return config.path;
}

- (void)resetDefaultRealmConfiguration
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:@"default"] stringByAppendingPathExtension:@"realm"];
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

@end
