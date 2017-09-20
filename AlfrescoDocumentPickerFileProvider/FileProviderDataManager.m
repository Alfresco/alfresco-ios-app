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

#import "FileProviderDataManager.h"
#import "AlfrescoFileManager+Extensions.h"
#import "UserAccount.h"
#import "AlfrescoFileProviderItemIdentifier.h"

static NSString * const kFileProviderAccountInfo = @"FileProviderAccountInfo";

@implementation FileProviderDataManager

+ (instancetype)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (RLMRealm *)realm
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    NSString *fileProviderFolder = [[AlfrescoFileManager sharedManager] fileProviderFolderPath];
    config.fileURL = [NSURL URLWithString:[[fileProviderFolder stringByAppendingPathComponent:kFileProviderAccountInfo] stringByAppendingPathExtension:@"realm"]];
    NSLog(@"==== config file url is %@", config.fileURL);
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    if(error)
    {
        NSLog(@"==== error is %@", error);
    }
    
    return realm;
}

- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account
{
    if(account)
    {
        RLMRealm *realm = [self realm];
        FileProviderAccountInfo *fpAccountInfo = [FileProviderAccountInfo new];
        fpAccountInfo.accountIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
        fpAccountInfo.name = displayName;
        fpAccountInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:menuItemIdentifierSuffix andAccount:account];
        
        
        FileProviderAccountInfo *fpMySitesInfo, *fpFavoriteSitesInfo;
        if([menuItemIdentifierSuffix isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            fpMySitesInfo = [FileProviderAccountInfo new];
            fpMySitesInfo.accountIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
            fpMySitesInfo.name = NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites");
            fpMySitesInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:kFileProviderMySitesFolderIdentifierSuffix andAccount:account];
            fpMySitesInfo.parentFolder = fpAccountInfo;
            
            fpFavoriteSitesInfo = [FileProviderAccountInfo new];
            fpFavoriteSitesInfo.accountIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
            fpFavoriteSitesInfo.name = NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites");
            fpFavoriteSitesInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:kFileProviderFavoriteSitesFolderIdentifierSuffix andAccount:account];
            fpFavoriteSitesInfo.parentFolder = fpAccountInfo;
        }
        
        [realm transactionWithBlock:^{
            [realm addOrUpdateObject:fpAccountInfo];
            if(fpMySitesInfo && fpFavoriteSitesInfo)
            {
                [realm addOrUpdateObject:fpMySitesInfo];
                [realm addOrUpdateObject:fpFavoriteSitesInfo];
            }
        }];
    }
}

- (void)cleanMenuItemsForAccount:(UserAccount *)account
{
    if(account)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"accountIdentifier = %@", account.accountIdentifier];
        RLMResults<FileProviderAccountInfo *> *accountMenuItems = [FileProviderAccountInfo objectsInRealm:realm withPredicate:pred];
        if(accountMenuItems.count > 0)
        {
            [realm transactionWithBlock:^{
                [realm deleteObjects:accountMenuItems];
            }];
        }
    }
}

- (RLMResults<FileProviderAccountInfo *> *)menuItemsForAccount:(NSString *)accountIdentifier
{
    RLMResults<FileProviderAccountInfo *> *results = nil;
    NSLog(@"==== file provider ==== account identifier %@", accountIdentifier);
    if(accountIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSString *identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:accountIdentifier];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"accountIdentifier = %@", identifier];
        results = [FileProviderAccountInfo objectsInRealm:realm withPredicate:pred];
    }
    
    return results;
}

@end
