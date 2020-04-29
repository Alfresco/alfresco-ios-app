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

#import "AFPEnumeratorBuilder.h"

#import "AFPItemIdentifier.h"

#import "AFPRootEnumerator.h"
#import "AFPLocalEnumerator.h"
#import "AFPAccountEnumerator.h"
#import "AFPSyncEnumerator.h"
#import "AFPSiteEnumerator.h"
#import "AFPFolderEnumerator.h"
#import "KeychainUtils.h"

@implementation AFPEnumeratorBuilder

- (id<NSFileProviderEnumerator>)enumeratorForItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    NSError *error = nil;
    [KeychainUtils saveItem:itemIdentifier
                     forKey:kFileProviderCurrentItemIdentifier
                    inGroup:kSharedAppGroupIdentifier
                      error:&error];
    if (error) {
        AlfrescoLogError(@"An error occured while saving the item identifier. Reason:%@", error.localizedDescription);
    }
    
    id<NSFileProviderEnumerator> enumerator = nil;
    
    if([itemIdentifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
    {
        enumerator = [AFPRootEnumerator new];
    }
    else if([itemIdentifier isEqualToString:kFileProviderLocalFilesPrefix])
    {
        enumerator = [AFPLocalEnumerator new];
    }
    else
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
        switch (identifierType) {
            case AlfrescoFileProviderItemIdentifierTypeAccount:
            {
                enumerator = [[AFPAccountEnumerator alloc] initWithItemIdentifier:itemIdentifier];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeMyFiles:
            case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
            case AlfrescoFileProviderItemIdentifierTypeFolder:
            case AlfrescoFileProviderItemIdentifierTypeFavorites:
            case AlfrescoFileProviderItemIdentifierTypeSite:
            {
                enumerator = [[AFPFolderEnumerator alloc] initWithItemIdentifier:itemIdentifier];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeSites:
            case AlfrescoFileProviderItemIdentifierTypeMySites:
            case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
            {
                enumerator = [[AFPSiteEnumerator alloc] initWithItemIdentifier:itemIdentifier];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeSynced:
            case AlfrescoFileProviderItemIdentifierTypeSyncFolder:
            {
                enumerator = [[AFPSyncEnumerator alloc] initWithItemIdentifier:itemIdentifier];
                break;
            }
            default:
                break;
        }
    }
    
    return enumerator;
}

@end
