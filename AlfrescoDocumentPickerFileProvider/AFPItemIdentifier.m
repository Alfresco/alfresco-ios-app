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

#import "AFPItemIdentifier.h"
#import "UserAccount.h"
#import "RealmSyncNodeInfo.h"

@implementation AFPItemIdentifier

+ (NSFileProviderItemIdentifier)getAccountIdentifierFromEnumeratedIdentifier:(__autoreleasing NSFileProviderItemIdentifier)enumeratedIdentifier
{
    NSArray *splitContent = [enumeratedIdentifier componentsSeparatedByString:@"."];
    if(splitContent.count > 1)
        return splitContent[1];
    return nil;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccount:(UserAccount *)account
{
    return [AFPItemIdentifier itemIdentifierForSuffix:suffix andAccountIdentifier:account.accountIdentifier];
}

+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *identifier;
    if(accountIdentifier.length)
    {
        if(suffix)
        {
            identifier = [NSString stringWithFormat:@"%@.%@.%@", kFileProviderAccountsIdentifierPrefix, accountIdentifier, suffix];
        }
        else
        {
            identifier = [NSString stringWithFormat:@"%@.%@", kFileProviderAccountsIdentifierPrefix, accountIdentifier];
        }
    }
    else
    {
        identifier = kFileProviderLocalFilesPrefix;
    }
    return identifier;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForIdentifier:(NSString *)identifier typePath:(NSString *)typePath andAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *accountItemIdentifier = [AFPItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:accountIdentifier];
    NSString *itemIdentifier = [NSString stringWithFormat:@"%@.%@.%@", accountItemIdentifier, typePath, identifier];
    return itemIdentifier;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForLocalFilename:(NSString *)filename
{
    NSString *itemIdentifier = [NSString stringWithFormat:@"%@.%@", kFileProviderLocalFilesPrefix, filename];
    return itemIdentifier;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForFilename:(NSString *)filename andFileParentIdentifier:(NSFileProviderItemIdentifier)parentIdentifier
{
    AlfrescoFileProviderItemIdentifierType parentIdentifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:parentIdentifier];
    if (parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeLocalFiles)
    {
        return [AFPItemIdentifier itemIdentifierForLocalFilename:filename];
    }
    else if(parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeSyncFolder)
    {
        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
        NSString *syncNodePathString = [NSString stringWithFormat:@"%@.%@", kFileProviderIdentifierComponentSync, kFileProviderIdentifierComponentNewDocument];
        return [AFPItemIdentifier itemIdentifierForIdentifier:filename typePath:syncNodePathString andAccountIdentifier:accountIdentifier];
    }
    else if (parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeFolder || parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeSite || parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeMyFiles || parentIdentifierType == AlfrescoFileProviderItemIdentifierTypeSharedFiles)
    {
        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:parentIdentifier];
        return [AFPItemIdentifier itemIdentifierForIdentifier:filename typePath:kFileProviderIdentifierComponentNewDocument andAccountIdentifier:accountIdentifier];
    }
    return nil;
}

+ (AlfrescoFileProviderItemIdentifierType)itemIdentifierTypeForIdentifier:(NSString *)identifier
{
    NSArray *components = [identifier componentsSeparatedByString:@"."];
    if(components.count == 2 && [components[0] isEqualToString:kFileProviderAccountsIdentifierPrefix])
    {
        return AlfrescoFileProviderItemIdentifierTypeAccount;
    }
    else if(components.count >= 1 && [components[0] isEqualToString:kFileProviderLocalFilesPrefix])
    {
        if(components.count == 1)
        {
            return AlfrescoFileProviderItemIdentifierTypeLocalFiles;
        }
        else
        {
            return AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument;
        }
    }
    else if(components.count == 3)
    {
        if([components[2] isEqualToString:kFileProviderMyFilesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeMyFiles;
        }
        else if([components[2] isEqualToString:kFileProviderSharedFilesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSharedFiles;
        }
        else if([components[2] isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSites;
        }
        else if([components[2] isEqualToString:kFileProviderFavoritesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeFavorites;
        }
        else if([components[2] isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSites;
        }
        else if([components[2] isEqualToString:kFileProviderMySitesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeMySites;
        }
        else if([components[2] isEqualToString:kFileProviderFavoriteSitesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeFavoriteSites;
        }
        else if([components[2] isEqualToString:kFileProviderSyncedFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSynced;
        }
    }
    else if(components.count > 3)
    {
        if([components[2] isEqualToString:kFileProviderIdentifierComponentFolder])
        {
            return AlfrescoFileProviderItemIdentifierTypeFolder;
        }
        else if([components[2] isEqualToString:kFileProviderIdentifierComponentSite])
        {
            return AlfrescoFileProviderItemIdentifierTypeSite;
        }
        else if([components[2] isEqualToString:kFileProviderIdentifierComponentDocument])
        {
            return AlfrescoFileProviderItemIdentifierTypeDocument;
        }
        else if([components[2] isEqualToString:kFileProviderIdentifierComponentNewDocument])
        {
            return AlfrescoFileProviderItemIdentifierTypeNewDocument;
        }
        else if([components[2] isEqualToString:kFileProviderIdentifierComponentSync])
        {
            if([components[3] isEqualToString:kFileProviderIdentifierComponentFolder])
            {
                return AlfrescoFileProviderItemIdentifierTypeSyncFolder;
            }
            else if([components[3] isEqualToString:kFileProviderIdentifierComponentNewDocument])
            {
                return AlfrescoFileProviderItemIdentifierTypeSyncNewDocument;
            }
            else
            {
                return AlfrescoFileProviderItemIdentifierTypeSyncDocument;
            }
        }
    }
    
    return AlfrescoFileProviderItemIdentifierTypeAccount;
}

+ (NSString *)alfrescoIdentifierFromItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    NSArray *components = [itemIdentifier componentsSeparatedByString:@"."];
    if(components.count == 4 && ([components[2] isEqualToString:kFileProviderIdentifierComponentFolder] || [components[2] isEqualToString:kFileProviderIdentifierComponentSite] || [components[2] isEqualToString:kFileProviderIdentifierComponentDocument]))
    {
        return components[3];
    }
    else if (components.count == 5 && [components[2] isEqualToString:kFileProviderIdentifierComponentSync])
    {
        return components[4];
    }
    return nil;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForSyncNode:(RealmSyncNodeInfo *)syncNode forAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *nodeTypePath = syncNode.isFolder? kFileProviderIdentifierComponentFolder : kFileProviderIdentifierComponentDocument;
    NSString *syncNodePathString = [NSString stringWithFormat:@"%@.%@", kFileProviderIdentifierComponentSync, nodeTypePath];
    return [AFPItemIdentifier itemIdentifierForIdentifier:syncNode.syncNodeInfoId typePath:syncNodePathString andAccountIdentifier:accountIdentifier];
}

+ (NSString *)filenameFromItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    NSString *prefix = [NSString stringWithFormat:@"%@.", kFileProviderLocalFilesPrefix];
    NSString *filename = [itemIdentifier substringFromIndex:[prefix length]];
    return filename;
}

@end
