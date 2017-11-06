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
#import "AlfrescoNode+Utilities.h"

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
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    if(error)
    {
        AlfrescoLogError(@"Error Creating Realm: %@", error.localizedDescription);
    }
    
    return realm;
}

- (RLMRealm *)realmForSyncWithAccountIdentifier:(NSString *)accountIdentifier
{
    RLMRealmConfiguration *config = [RLMRealmConfiguration defaultConfiguration];
    
    NSURL *sharedAppGroupFolderURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    NSString *configFilePath = [[sharedAppGroupFolderURL.path stringByAppendingPathComponent:accountIdentifier] stringByAppendingPathExtension:@"realm"];
    config.fileURL = [NSURL URLWithString:configFilePath];
    NSError *error = nil;
    RLMRealm *realm = [RLMRealm realmWithConfiguration:config error:&error];
    if(error)
    {
        AlfrescoLogError(@"Error Creating Realm: %@", error.localizedDescription);
    }
    
    return realm;
}

- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account
{
    if(account)
    {
        [self saveAccount:account];
        RLMRealm *realm = [self realm];
        FileProviderAccountInfo *fpAccountInfo = [FileProviderAccountInfo new];
        fpAccountInfo.name = displayName;
        fpAccountInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:menuItemIdentifierSuffix andAccount:account];
        
        NSString *accountDBIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
        FileProviderAccountInfo *accountMetadata = [FileProviderAccountInfo objectInRealm:realm forPrimaryKey:accountDBIdentifier];
        fpAccountInfo.parentFolder = accountMetadata;
        
        FileProviderAccountInfo *fpMySitesInfo, *fpFavoriteSitesInfo;
        if([menuItemIdentifierSuffix isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            fpMySitesInfo = [FileProviderAccountInfo new];
            fpMySitesInfo.name = NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites");
            fpMySitesInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:kFileProviderMySitesFolderIdentifierSuffix andAccount:account];
            fpMySitesInfo.parentFolder = fpAccountInfo;
            
            fpFavoriteSitesInfo = [FileProviderAccountInfo new];
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

- (void)saveAccount:(UserAccount *)account
{
    if(account)
    {
        RLMRealm *realm = [self realm];
        FileProviderAccountInfo *fpAccountInfo = [FileProviderAccountInfo new];
        fpAccountInfo.name = account.accountDescription;
        fpAccountInfo.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
        [realm transactionWithBlock:^{
            [realm addOrUpdateObject:fpAccountInfo];
        }];
    }
}

- (void)cleanMenuItemsForAccount:(UserAccount *)account
{
    if(account)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier CONTAINS %@", account.accountIdentifier];
        RLMResults<FileProviderAccountInfo *> *accountMenuItems = [FileProviderAccountInfo objectsInRealm:realm withPredicate:pred];
        if(accountMenuItems.count > 0)
        {
            [realm transactionWithBlock:^{
                [realm deleteObjects:accountMenuItems];
            }];
        }
    }
}

- (void)saveNode:(AlfrescoNode *)node parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier
{
    if(node && parentIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", parentIdentifier];
        RLMResults<FileProviderAccountInfo *> *parentList = [FileProviderAccountInfo objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            FileProviderAccountInfo *parent = parentList.firstObject;
            FileProviderAccountInfo *item = [FileProviderAccountInfo new];
            NSString *typePath = node.isFolder ? kFileProviderFolderPathString : kFileProviderDocumentPathString;
            NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
            item.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForIdentifier:[node nodeRefWithoutVersionID] typePath:typePath andAccountIdentifier:accountIdentifier];
            item.parentFolder = parent;
            item.creationDate = node.createdAt;
            item.name = node.name;
            
            [realm transactionWithBlock:^{
                [realm addOrUpdateObject:item];
            }];
        }
    }
}

- (void)saveSite:(AlfrescoSite *)site parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier
{
    if(site && parentIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", parentIdentifier];
        RLMResults<FileProviderAccountInfo *> *parentList = [FileProviderAccountInfo objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            FileProviderAccountInfo *parent = parentList.firstObject;
            FileProviderAccountInfo *item = [FileProviderAccountInfo new];
            NSString *typePath = kFileProviderSitePathString;
            NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
            item.identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForIdentifier:site.shortName typePath:typePath andAccountIdentifier:accountIdentifier];
            item.parentFolder = parent;
            item.name = site.title;
            
            [realm transactionWithBlock:^{
                [realm addOrUpdateObject:item];
            }];
        }
    }
}

- (RLMResults<FileProviderAccountInfo *> *)menuItemsForAccount:(NSString *)accountIdentifier
{
    RLMResults<FileProviderAccountInfo *> *results = nil;
    if(accountIdentifier)
    {
        NSString *identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:accountIdentifier];
        results = [self menuItemsForParentIdentifier:identifier];
    }
    
    return results;
}

- (RLMResults<FileProviderAccountInfo *> *)menuItemsForParentIdentifier:(NSString *)itemIdentifier
{
    RLMResults<FileProviderAccountInfo *> *result = nil;
    if(itemIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", itemIdentifier];
        RLMResults<FileProviderAccountInfo *> *parentList = [FileProviderAccountInfo objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            FileProviderAccountInfo *parent = parentList.firstObject;
            NSPredicate *resultsPred = [NSPredicate predicateWithFormat:@"parentFolder = %@", parent];
            result = [FileProviderAccountInfo objectsInRealm:realm withPredicate:resultsPred];
        }
    }
    
    return result;
}

- (id)itemForIdentifier:(NSFileProviderItemIdentifier)identifier
{
    id item;
    if(identifier)
    {
        AlfrescoFileProviderItemIdentifierType typeIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSyncNode)
        {
            NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
            RLMRealm *realm = [self realmForSyncWithAccountIdentifier:accountIdentifier];
            NSString *itemSyncIdentifier = [AlfrescoFileProviderItemIdentifier identifierFromItemIdentifier:identifier];
            RLMResults<RealmSyncNodeInfo*> *items = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId == %@", itemSyncIdentifier];
            if(items.count > 0)
            {
                item = items.firstObject;
            }
        }
        else
        {
            RLMRealm *realm = [self realm];
            NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", identifier];
            RLMResults<FileProviderAccountInfo *> *list = [FileProviderAccountInfo objectsInRealm:realm withPredicate:pred];
            if(list.count > 0)
            {
                item = list.firstObject;
            }
        }
    }
    
    return item;
}

- (RLMResults<RealmSyncNodeInfo *> *)syncItemsInNodeWithId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier
{
    RLMRealm *realm = [self realmForSyncWithAccountIdentifier:accountIdentifier];
    RLMResults<RealmSyncNodeInfo *> *results;
    if(identifier)
    {
        RLMResults *parentSyncNodes = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncNodeInfoId == %@", identifier];
        if(parentSyncNodes.count > 0)
        {
            RealmSyncNodeInfo *node = parentSyncNodes.firstObject;
            results = node.nodes;
        }
    }
    else
    {
        results = [RealmSyncNodeInfo objectsInRealm:realm where:@"isTopLevelSyncNode = %@", @YES];
    }
    return results;
}

- (NSFileProviderItemIdentifier)parentItemIdentifierOfSyncedNode:(RealmSyncNodeInfo *)syncedNode fromAccountIdentifier:(NSString *)accountIdentifier
{
    NSFileProviderItemIdentifier identifier;
    if(syncedNode && accountIdentifier)
    {
        RealmSyncNodeInfo *parentNode = syncedNode.parentNode;
        NSString *syncNodePathString = [NSString stringWithFormat:@"%@/%@", kFileProviderSyncPathString, kFileProviderFolderPathString];
        identifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForIdentifier:parentNode.syncNodeInfoId typePath:syncNodePathString andAccountIdentifier:accountIdentifier];
    }
    
    return identifier;
}

@end
