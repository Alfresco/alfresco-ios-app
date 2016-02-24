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

- (RLMRealm *)createRealmForAccount:(UserAccount *)account
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:account.accountIdentifier] stringByAppendingPathExtension:@"realm"];
    
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    
    if(error)
    {
        //TODO:
    }
    
    return realm;
}

- (void)deleteRealmForAccount:(UserAccount *)account
{
    @autoreleasepool {
        // all Realm usage here
    }
    NSFileManager *manager = [NSFileManager defaultManager];
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    // Use the default directory, but replace the filename with the accountId
    config.path = [[[config.path stringByDeletingLastPathComponent] stringByAppendingPathComponent:account.accountIdentifier] stringByAppendingPathExtension:@"realm"];
    NSArray<NSString *> *realmFilePaths = @[config.path,
                                            [config.path stringByAppendingPathExtension:@"lock"],
                                            [config.path stringByAppendingPathExtension:@"log_a"],
                                            [config.path stringByAppendingPathExtension:@"log_b"],
                                            [config.path stringByAppendingPathExtension:@"note"]
                                            ];
    for (NSString *path in realmFilePaths)
    {
        NSError *error = nil;
        [manager removeItemAtPath:path error:&error];
        if (error)
        {
            // handle error
        }
    }
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
