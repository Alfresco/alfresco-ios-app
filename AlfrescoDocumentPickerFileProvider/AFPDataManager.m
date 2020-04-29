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

#import "AFPDataManager.h"
#import "AlfrescoFileManager+Extensions.h"
#import "UserAccount.h"
#import "AFPItemIdentifier.h"
#import "AlfrescoNode+Utilities.h"

#import "AlfrescoViewConfig.h"

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
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier == %@", parentIdentifier];
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
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier == %@", parentIdentifier];
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

- (AFPItemMetadata *)saveItem:(AFPItem *)item needsUpload:(BOOL)needUpload fileURL:(NSURL *)fileURL
{
    if(item)
    {
        RLMRealm *realm = [self realm];
        NSString *parentIdentifier = item.parentItemIdentifier;
        
        AFPItemMetadata *itemMetadata = [AFPItemMetadata new];
        itemMetadata.identifier = item.itemIdentifier;
        itemMetadata.name = item.filename;
        itemMetadata.parentIdentifier = parentIdentifier;
        itemMetadata.needsUpload = needUpload;
        itemMetadata.filePath = fileURL.path;
        
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier == %@", parentIdentifier];
        RLMResults<AFPItemMetadata *> *parentList = [AFPItemMetadata objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            itemMetadata.parentFolder = parentList[0];
        }
        
        [realm transactionWithBlock:^{
            [realm addOrUpdateObject:itemMetadata];
        }];
        
        return itemMetadata;
    }
    return nil;
}

- (void)removeItemMetadataForIdentifier:(NSString *)identifier
{
    RLMRealm *realm = [self realm];
    AFPItemMetadata *itemMetadataToDelete = [self metadataItemForIdentifier:identifier];
    if(itemMetadataToDelete)
    {
        [realm beginWriteTransaction];
        [realm deleteObject:itemMetadataToDelete];
        [realm commitWriteTransaction];
    }
}

- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)itemIdentifier downloaded:(BOOL)isDownloaded
{
    if(itemIdentifier)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", itemIdentifier];
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

- (void)updateMenuItemsWithHiddenCollectionOfViewConfigs:(NSArray *)viewConfigs forAccount:(UserAccount *)account
{
    for(AlfrescoViewConfig *config in viewConfigs)
    {
        if([config.type isEqualToString:kAlfrescoConfigViewTypeFavourites])
        {
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderFavoritesFolderIdentifierSuffix andAccount:account]];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeSiteBrowser])
        {
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderSitesFolderIdentifierSuffix andAccount:account]];
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderFavoriteSitesFolderIdentifierSuffix andAccount:account]];
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderMySitesFolderIdentifierSuffix andAccount:account]];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeSync])
        {
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderSyncedFolderIdentifierSuffix andAccount:account]];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeRepository])
        {
            NSString *folderTypeId = config.parameters[kAlfrescoConfigViewParameterFolderTypeKey];
            
            if ([folderTypeId isEqualToString:kAlfrescoConfigViewParameterFolderTypeMyFiles])
            {
                [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderMyFilesFolderIdentifierSuffix andAccount:account]];
            }
            else if([folderTypeId isEqualToString:kAlfrescoConfigViewParameterFolderTypeShared])
            {
                [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:kFileProviderSharedFilesFolderIdentifierSuffix andAccount:account]];
            }
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeLocal])
        {
            [self removeItemMetadataForIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:nil]];
            [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:NSFileProviderRootContainerItemIdentifier completionHandler:^(NSError * _Nullable error) {
                if (error != NULL)
                {
                    AlfrescoLogError(@"ERROR: Couldn't signal enumerator %@ for changes %@", NSFileProviderRootContainerItemIdentifier, error);
                }
            }];
        }
    }
    [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account] completionHandler:^(NSError * _Nullable error) {
        if (error != NULL)
        {
            AlfrescoLogError(@"ERROR: Couldn't signal enumerator %@ for changes %@", [AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account], error);
        }
    }];
}

- (void)updateMenuItemsWithVisibleCollectionOfViewConfigs:(NSArray *)viewConfigs forAccount:(UserAccount *)account
{
    NSString *displayName;
    for(AlfrescoViewConfig *config in viewConfigs)
    {
        if([config.type isEqualToString:kAlfrescoConfigViewTypeFavourites])
        {
            displayName = config.label ?: NSLocalizedString(@"favourites.title", @"Favorites Title");
            [self saveMenuItem:kFileProviderFavoritesFolderIdentifierSuffix displayName:displayName forAccount:account];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeSiteBrowser])
        {
            displayName = config.label ?: NSLocalizedString(@"sites.title", @"Sites Title");
            [self saveMenuItem:kFileProviderSitesFolderIdentifierSuffix displayName:displayName forAccount:account];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeSync])
        {
            displayName = config.label ?: NSLocalizedString(@"sync.title", @"Sync Title");
            [self saveMenuItem:kFileProviderSyncedFolderIdentifierSuffix displayName:displayName forAccount:account];
        }
        else if([config.type isEqualToString:kAlfrescoConfigViewTypeRepository])
        {
            NSString *folderTypeId = config.parameters[kAlfrescoConfigViewParameterFolderTypeKey];
            if ([folderTypeId isEqualToString:kAlfrescoConfigViewParameterFolderTypeMyFiles])
            {
                displayName = config.label ?: NSLocalizedString(@"myFiles.title", @"My Files");
                [self saveMenuItem:kFileProviderMyFilesFolderIdentifierSuffix displayName:displayName forAccount:account];
            }
            else if([folderTypeId isEqualToString:kAlfrescoConfigViewParameterFolderTypeShared])
            {
                displayName = config.label ?: NSLocalizedString(@"sharedFiles.title", @"Shared Files");
                [self saveMenuItem:kFileProviderSharedFilesFolderIdentifierSuffix displayName:displayName forAccount:account];
            }
        }
        else if ([config.type isEqualToString:kAlfrescoConfigViewTypeLocal])
        {
            [self saveLocalFilesItem];
            [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:NSFileProviderRootContainerItemIdentifier completionHandler:^(NSError * _Nullable error) {
                if (error != NULL)
                {
                    AlfrescoLogError(@"ERROR: Couldn't signal enumerator %@ for changes %@", NSFileProviderRootContainerItemIdentifier, error);
                }
            }];
        }
    }
    [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:[AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account] completionHandler:^(NSError * _Nullable error) {
        if (error != NULL)
        {
            AlfrescoLogError(@"ERROR: Couldn't signal enumerator %@ for changes %@", [AFPItemIdentifier itemIdentifierForSuffix:nil andAccount:account], error);
        }
    }];
}

- (AFPItemMetadata *)localFilesItem
{
    AFPItemMetadata *localFiles = nil;
    RLMRealm *realm = [self realm];
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"identifier == %@", [AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:nil]];
    RLMResults<AFPItemMetadata *> *results = [AFPItemMetadata objectsInRealm:realm withPredicate:predicate];
    if(results.count > 0)
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
        NSPredicate *parentPred = [NSPredicate predicateWithFormat:@"identifier == %@", itemIdentifier];
        RLMResults<AFPItemMetadata *> *parentList = [AFPItemMetadata objectsInRealm:realm withPredicate:parentPred];
        if(parentList.count > 0)
        {
            AFPItemMetadata *parent = parentList.firstObject;
            NSPredicate *resultsPred = [NSPredicate predicateWithFormat:@"parentFolder == %@", parent];
            result = [AFPItemMetadata objectsInRealm:realm withPredicate:resultsPred];
        }
    }
    
    return result;
}

- (AFPItemMetadata *)metadataItemForIdentifier:(NSFileProviderItemIdentifier)identifier
{
    RLMRealm *realm = [self realm];
    NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", identifier];
    RLMResults<AFPItemMetadata *> *list = [AFPItemMetadata objectsInRealm:realm withPredicate:pred];
    if(list.count > 0)
    {
        return list.firstObject;
    }
    return nil;
}

- (RealmSyncNodeInfo *)syncItemForId:(NSFileProviderItemIdentifier)identifier
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
    NSString *itemSyncIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:identifier];
    return [self syncItemForId:itemSyncIdentifier forAccountIdentifier:accountIdentifier];
}

- (NSFileProviderItemIdentifier)parentItemIdentifierOfSyncedNode:(RealmSyncNodeInfo *)syncedNode fromAccountIdentifier:(NSString *)accountIdentifier
{
    NSFileProviderItemIdentifier identifier;
    if(syncedNode && accountIdentifier.length)
    {
        RealmSyncNodeInfo *parentNode = syncedNode.parentNode;
        if(parentNode)
        {
            NSString *syncNodePathString = [NSString stringWithFormat:@"%@/%@", kFileProviderIdentifierComponentSync, kFileProviderIdentifierComponentFolder];
            identifier = [AFPItemIdentifier itemIdentifierForIdentifier:parentNode.syncNodeInfoId typePath:syncNodePathString andAccountIdentifier:accountIdentifier];
        }
        else
        {
            identifier = [AFPItemIdentifier itemIdentifierForSuffix:kFileProviderSyncedFolderIdentifierSuffix andAccountIdentifier:accountIdentifier];
        }
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
            
            RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
            RLMResults *syncNodes = [RealmSyncNodeInfo objectsInRealm:realm where:@"syncContentPath == %@", syncContentPath];
            if(syncNodes.count > 0)
            {
                RealmSyncNodeInfo *syncNode = syncNodes.firstObject;
                identifier = [AFPItemIdentifier itemIdentifierForSyncNode:syncNode forAccountIdentifier:accountIdentifier];
            }
        }
    }
    
    return identifier;
}

- (RLMResults<RealmSyncNodeInfo *> *)syncItemsInParentNodeWithSyncId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier
{
    RLMResults<RealmSyncNodeInfo *> *results;
    if(accountIdentifier.length)
    {
        RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
        if(identifier)
        {
            RealmSyncNodeInfo *parent = [[RealmSyncCore sharedSyncCore] syncNodeInfoForId:identifier inRealm:realm];
            results = parent.nodes;
        }
        else
        {
            results = [[RealmSyncCore sharedSyncCore] topLevelSyncNodesInRealm:realm];
        }
    }
    return results;
}

- (RealmSyncNodeInfo *)syncItemForId:(NSString *)identifier forAccountIdentifier:(NSString *)accountIdentifier
{
    RealmSyncNodeInfo *syncNode = nil;
    if(identifier.length && accountIdentifier.length)
    {
        RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
        syncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForId:identifier inRealm:realm];
    }
    return syncNode;
}

- (void)cleanRemovedChildrenFromSyncFolder:(AlfrescoNode *)syncFolder usingUpdatedChildrenIdList:(NSArray *)childrenIdList fromAccountIdentifier:(NSString *)accountIdentifier
{
    RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
    RealmSyncNodeInfo *syncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:syncFolder ifNotExistsCreateNew:NO inRealm:realm];
    RLMLinkingObjects *childrenArray = syncNode.nodes;
    NSMutableArray *nodesToDelete = [NSMutableArray new];
    for (RealmSyncNodeInfo *child in childrenArray)
    {
        if(![childrenIdList containsObject:child.syncNodeInfoId])
        {
            [nodesToDelete addObject:child];
        }
    }
    
    [realm transactionWithBlock:^{
        for (RealmSyncNodeInfo *child in nodesToDelete)
        {
            [realm deleteObject:child];
        }
    }];
}

- (void)updateSyncDocument:(AlfrescoDocument *)oldDocument withAlfrescoNode:(AlfrescoDocument *)document fromPath:(NSString *)path fromAccountIdentifier:(NSString *)accountIdentifier
{
    if(accountIdentifier.length)
    {
        [[RealmSyncCore sharedSyncCore] didUploadNewVersionForDocument:oldDocument updatedDocument:document fromPath:path forAccountIdentifier:accountIdentifier];
    }
}

- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)metadataIdentifier
      withSyncDocument:(AlfrescoDocument *)alfrescoDocument
{
    if(alfrescoDocument && metadataIdentifier.length)
    {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", metadataIdentifier];
        RLMResults<AFPItemMetadata *> *list = [AFPItemMetadata objectsInRealm:realm
                                                                withPredicate:pred];
        if(list.count > 0)
        {
            AFPItemMetadata *item = list.firstObject;
            
            [realm transactionWithBlock:^{
                item.node = [NSKeyedArchiver archivedDataWithRootObject:alfrescoDocument];
                [realm addOrUpdateObject:item];
            }];
        }
    }
}

- (void)updateMetadataForIdentifier:(NSFileProviderItemIdentifier)metadataIdentifier
          withFileName:(NSString *)updatedFileName
{
    if (metadataIdentifier.length && updatedFileName.length) {
        RLMRealm *realm = [self realm];
        NSPredicate *pred = [NSPredicate predicateWithFormat:@"identifier == %@", metadataIdentifier];
        RLMResults<AFPItemMetadata *> *list = [AFPItemMetadata objectsInRealm:realm
                                                                withPredicate:pred];
        if(list.count > 0)
        {
            AFPItemMetadata *item = list.firstObject;
            [realm transactionWithBlock:^{
                item.name = updatedFileName;
                [realm addOrUpdateObject:item];
            }];
        }
    }
}

@end
