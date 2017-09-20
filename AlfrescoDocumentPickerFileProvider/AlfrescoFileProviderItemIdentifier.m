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

#import "AlfrescoFileProviderItemIdentifier.h"
#import "UserAccount.h"

@implementation AlfrescoFileProviderItemIdentifier

+ (NSFileProviderItemIdentifier)getAccountIdentifierFromEnumeratedFolderIdenfitier:(__autoreleasing NSFileProviderItemIdentifier)enumeratedIdentifier
{
    NSArray *splitContent = [enumeratedIdentifier componentsSeparatedByString:@"."];
    if(splitContent.count > 1)
        return splitContent[1];
    return nil;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccount:(UserAccount *)account
{
    return [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:suffix andAccountIdentifier:account.accountIdentifier];
}

+ (NSFileProviderItemIdentifier)itemIdentifierForSuffix:(NSString *)suffix andAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *identifier;
    if(suffix)
    {
        identifier = [NSString stringWithFormat:@"%@.%@.%@", kFileProviderAccountsIdentifierPrefix, accountIdentifier, suffix];
    }
    else
    {
        identifier = [NSString stringWithFormat:@"%@.%@", kFileProviderAccountsIdentifierPrefix, accountIdentifier];
    }
    return identifier;
}

+ (NSFileProviderItemIdentifier)itemIdentifierForFolderRef:(NSString *)folderRef andAccountIdentifier:(NSString *)accountIdentifier
{
    NSString *accountItemIdentifier = [AlfrescoFileProviderItemIdentifier itemIdentifierForSuffix:nil andAccountIdentifier:accountIdentifier];
    NSString *folderItemIdentifier = [NSString stringWithFormat:@"%@.%@.%@", accountItemIdentifier, kFileProviderFolderPathString, folderRef];
    return folderItemIdentifier;
}

+ (AlfrescoFileProviderItemIdentifierType)itemIdentifierTypeForIdentifier:(NSString *)identifier
{
    NSArray *components = [identifier componentsSeparatedByString:@"."];
    if(components.count == 2)
    {
        return AlfrescoFileProviderItemIdentifierTypeAccount;
    }
    else if(components.count == 3)
    {
        if([components[2] isEqualToString:kFileProviderMyFilesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeMyFiles;
        }
        else if ([components[2] isEqualToString:kFileProviderSharedFilesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSharedFiles;
        }
        else if ([components[2] isEqualToString:kFileProviderSitesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeSites;
        }
        else if ([components[2] isEqualToString:kFileProviderFavoritesFolderIdentifierSuffix])
        {
            return AlfrescoFileProviderItemIdentifierTypeFavorites;
        }
    }
    else if(components.count > 3)
    {
        if([components[2] isEqualToString:kFileProviderFolderPathString])
        {
            return AlfrescoFileProviderItemIdentifierTypeFolder;
        }
        else if([components[2] isEqualToString:kFileProviderSitePathString])
        {
            return AlfrescoFileProviderItemIdentifierTypeSite;
        }
        else if ([components[2] isEqualToString:kFileProviderDocumentPathString])
        {
            return AlfrescoFileProviderItemIdentifierTypeDocument;
        }
    }
    
    return AlfrescoFileProviderItemIdentifierTypeAccount;
}

+ (NSString *)folderRefFromItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    NSArray *components = [itemIdentifier componentsSeparatedByString:@"."];
    if(components.count == 4 && [components[2] isEqualToString:kFileProviderFolderPathString])
    {
        return components[3];
    }
    return nil;
}

@end
