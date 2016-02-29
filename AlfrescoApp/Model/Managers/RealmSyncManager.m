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

@implementation RealmSyncManager

+ (RealmSyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (RLMRealm *)createRealmForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:account.accountIdentifier] stringByAppendingPathExtension:@"realm"];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        NSException *exception = [NSException exceptionWithName:kFailedToCreateRealmDatabase reason:error.description userInfo:@{kRealmSyncErrorKey : error}];
        [exception raise];
    }
    
    return realm;
}

- (void)changeDefaultConfigurationForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:account.accountIdentifier] stringByAppendingPathExtension:@"realm"];
    
    // Set this as the configuration used for the default Realm
    [RLMRealmConfiguration setDefaultConfiguration:config];
}

@end
