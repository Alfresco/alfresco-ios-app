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

#import "AFPDataManager.h"
#import "AlfrescoFileManager+Extensions.h"
#import "UserAccount.h"
#import "AFPItemIdentifier.h"
#import "AlfrescoNode+Utilities.h"

static NSString * const kFileProviderAccountInfo = @"FileProviderAccountInfo";

@implementation AFPDataManager

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

- (void)saveLocalFilesItem
{
    RLMRealm *realm = [self realm];
    AFPItemMetadata *itemMetadata = [AFPItemMetadata new];
    itemMetadata.name = NSLocalizedString(@"downloads.title", @"Local Files");
    itemMetadata.identifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:nil];
    [realm transactionWithBlock:^{
        [realm addOrUpdateObject:itemMetadata];
    }];
}

- (void)saveMenuItem:(NSString *)menuItemIdentifierSuffix displayName:(NSString *)displayName forAccount:(UserAccount *)account
{
    if(account)
    {
        [self saveAccount:account];
        RLMRealm *realm = [self realm];
        AFPItemMetadata *fpAccountInfo = [AFPItemMetadata new];
        fpAccountInfo.name = displayName;
        fpAccountInfo.identifier = [AFPItemIdentifier itemIdentifierForSuffix:menuItemIdentifierSuffix andAccount:account];
        
        NSString *accountDBIdentifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
        AFPItemMetadata *accountMetadata = [AFPItemMetadata objectInRealm:realm forPrimaryKey:accountDBIdentifier];
        fpAccountInfo.parentFolder = accountMetadata;
        
        AFPItemMetadata *fpMySitesInfo, *fpFavoriteSitesInfo;
        if([menuItemIdentifierSuffix isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            fpMySitesInfo = [AFPItemMetadata new];
            fpMySitesInfo.name = NSLocalizedString(@"sites.segmentControl.mysites", @"My Sites");
            fpMySitesInfo.identifier = [AFPItemIdentifier itemIdentifierForSuffix:kFileProviderMySitesFolderIdentifierSuffix andAccount:account];
            fpMySitesInfo.parentFolder = fpAccountInfo;
            
            fpFavoriteSitesInfo = [AFPItemMetadata new];
            fpFavoriteSitesInfo.name = NSLocalizedString(@"sites.segmentControl.favoritesites", @"Favorite Sites");
            fpFavoriteSitesInfo.identifier = [AFPItemIdentifier itemIdentifierForSuffix:kFileProviderFavoriteSitesFolderIdentifierSuffix andAccount:account];
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
        AFPItemMetadata *fpAccountInfo = [AFPItemMetadata new];
        fpAccountInfo.name = account.accountDescription;
        fpAccountInfo.identifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account];
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
        RLMResults<AFPItemMetadata *> *accountMenuItems = [AFPItemMetadata objectsInRealm:realm withPredicate:pred];
        if(accountMenuItems.count > 0)
        {
            [realm transactionWithBlock:^{
                [realm deleteObjects:accountMenuItems];
            }];
        }
    }
}

- (AFPItemMetadata *)saveNode:(AlfrescoNode *)node parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier
{
    if(node && parentIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", parentIdentifier];
        RLMResults<AFPItemMetadata *> *parentList = [AFPItemMetadata objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            AFPItemMetadata *parent = parentList.firstObject;
            AFPItemMetadata *item = [AFPItemMetadata new];
            
            NSString *typePath = node.isFolder ? kFileProviderIdentifierComponentFolder : kFileProviderIdentifierComponentDocument;
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
            item.identifier = [AFPItemIdentifier itemIdentifierForIdentifier:[node nodeRefWithoutVersionID] typePath:typePath andAccountIdentifier:accountIdentifier];
            item.parentFolder = parent;
            item.creationDate = node.createdAt;
            item.name = node.name;
            item.node = [NSKeyedArchiver archivedDataWithRootObject:node];
            
            [realm transactionWithBlock:^{
                [realm addOrUpdateObject:item];
            }];
            return item;
        }
    }
    return nil;
}

- (AFPItemMetadata *)saveSite:(AlfrescoSite *)site parentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier
{
    if(site && parentIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", parentIdentifier];
        RLMResults<AFPItemMetadata *> *parentList = [AFPItemMetadata objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            AFPItemMetadata *parent = parentList.firstObject;
            AFPItemMetadata *item = [AFPItemMetadata new];
            NSString *typePath = kFileProviderIdentifierComponentSite;
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
            item.identifier = [AFPItemIdentifier itemIdentifierForIdentifier:site.shortName typePath:typePath andAccountIdentifier:accountIdentifier];
            item.parentFolder = parent;
            item.name = site.title;
            
            [realm transactionWithBlock:^{
                [realm addOrUpdateObject:item];
            }];
            return item;
        }
    }
    return nil;
}

- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)itemIdentifier downloaded:(BOOL)isDownloaded
{
    if(itemIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier = %@", itemIdentifier];
        RLMResults<AFPItemMetadata *> *list = [AFPItemMetadata objectsInRealm:realm withPredicate:pred];
        if(list.count > 0)
        {
            AFPItemMetadata *item = list.firstObject;
            [realm transactionWithBlock:^{
                item.downloaded = isDownloaded;
            }];
        }
    }
}

- (AFPItemMetadata *)localFilesItem
{
    AFPItemMetadata *localFiles = nil;
    RLMRealm *realm = [self realm];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier = %@", [AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:nil]];
    RLMResults<AFPItemMetadata *> *results = [AFPItemMetadata objectsInRealm:realm withPredicate:predicate];
    if(results && results.count > 0)
    {
        localFiles = results.firstObject;
    }
    
    return localFiles;
}

- (RLMResults<AFPItemMetadata *> *)menuItemsForAccount:(NSString *)accountIdentifier
{
    RLMResults<AFPItemMetadata *> *results = nil;
    if(accountIdentifier)
    {
        NSString *identifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:accountIdentifier];
        results = [self menuItemsForParentIdentifier:identifier];
    }
    
    return results;
}

- (RLMResults<AFPItemMetadata *> *)menuItemsForParentIdentifier:(NSString *)itemIdentifier
{
    RLMResults<AFPItemMetadata *> *result = nil;
    if(itemIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier = %@", itemIdentifier];
        RLMResults<AFPItemMetadata *> *parentList = [AFPItemMetadata objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            AFPItemMetadata *parent = parentList.firstObject;
            NSPredicate *resultsPred = [NSPredicate predicateWithFormat:@"parentFolder = %@", parent];
            result = [AFPItemMetadata objectsInRealm:realm withPredicate:resultsPred];
        }
    }
    
    return result;
}

- (id)dbItemForIdentifier:(NSFileProviderItemIdentifier)identifier
{
    id item;
    if(identifier)
    {
        AlfrescoFileProviderItemIdentifierType typeIdentifier = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSyncNode)
        {
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
            RLMRealm *realm = [self realmForSyncWithAccountIdentifier:accountIdentifier];
            NSString *itemSyncIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:identifier];
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
            RLMResults<AFPItemMetadata *> *list = [AFPItemMetadata objectsInRealm:realm withPredicate:pred];
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
        NSString *syncNodePathString = [NSString stringWithFormat:@"%@/%@", kFileProviderIdentifierComponentSync, kFileProviderIdentifierComponentFolder];
        identifier = [AFPItemIdentifier itemIdentifierForIdentifier:parentNode.syncNodeInfoId typePath:syncNodePathString andAccountIdentifier:accountIdentifier];
    }
    
    return identifier;
}

- (NSFileProviderItemIdentifier)itemIdentifierOfSyncedNodeWithURL:(NSURL *)syncedNodeURL
{
    NSFileProviderItemIdentifier identifier;
    NSArray <NSString *> *pathComponents = [syncedNodeURL pathComponents];
    if(pathComponents.count > 3)
    {
        if([pathComponents[pathComponents.count - 3] isEqualToString:kSyncFolder])
        {
            // Sync/<account identifier>/<sync content path>
            NSString *accountIdentifier = pathComponents[pathComponents.count - 2];
            NSString *syncContentPath = pathComponents[pathComponents.count - 1];
            
            RLMRealm *realm = [self realmForSyncWithAccountIdentifier:accountIdentifier];
            RLMResults *syncNodes = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncContentPath == %@", syncContentPath];
            if(syncNodes && syncNodes.count > 0)
            {
                RealmSyncNodeInfo *syncNode = syncNodes.firstObject;
                identifier = [AFPItemIdentifier itemIdentifierForSyncNode:syncNode forAccountIdentifier:accountIdentifier];
            }
        }
    }
    
    return identifier;
}

@end
