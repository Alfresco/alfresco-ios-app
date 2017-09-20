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

#import "AlfrescoFolderEnumerator.h"
#import "AlfrescoFileProviderItemIdentifier.h"
#import "AlfrescoFileProviderItem.h"
#import "CustomFolderService.h"
#import "FileProviderAccountManager.h"
#import "FavouriteManager.h"

@interface AlfrescoFolderEnumerator()

@property (nonatomic, strong) CustomFolderService *customFolderService;
@property (nonatomic, strong) NSURLRequest *currentRequest;
@property (nonatomic, strong) AlfrescoFolder *requestedFolder;
@property (nonatomic, strong) id<NSFileProviderEnumerationObserver> observer;
@property (nonatomic, strong) FileProviderAccountManager *accountManager;

@end

@implementation AlfrescoFolderEnumerator

- (instancetype)initWithEnumeratedItemIdentifier:(NSFileProviderItemIdentifier)enumeratedItemIdentifier
{
    if (self = [super init])
    {
        _enumeratedItemIdentifier = enumeratedItemIdentifier;
        self.accountManager = [FileProviderAccountManager new];
    }
    return self;
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    /* TODO:
     - inspect the page to determine whether this is an initial or a follow-up request
     
     If this is an enumerator for a directory, the root container or all directories:
     - perform a server request to fetch directory contents
     If this is an enumerator for the active set:
     - perform a server request to update your local database
     - fetch the active set from your local database
     
     - inform the observer about the items returned by the server (possibly multiple times)
     - inform the observer that you are finished with this page
     */
    self.observer = observer;
    AlfrescoFileProviderItemIdentifierType identifierType = [AlfrescoFileProviderItemIdentifier itemIdentifierTypeForIdentifier:self.enumeratedItemIdentifier];
    switch (identifierType) {
        case AlfrescoFileProviderItemIdentifierTypeMyFiles:
        {
            [self enumerateItemsInMyFiles];
            break;
        }
        case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
        {
            [self enumerateItemsInSharedFiles];
            break;
        }
        case AlfrescoFileProviderItemIdentifierTypeFolder:
        {
            NSString *folderRef = [AlfrescoFileProviderItemIdentifier folderRefFromItemIdentifier:self.enumeratedItemIdentifier];
            [self enumerateItemsInFolderWithFolderRef:folderRef];
            break;
        }
        case AlfrescoFileProviderItemIdentifierTypeFavorites:
        {
            [self enumerateItemsInFavoriteFolder];
        }
        default:
            break;
    }
}

- (void)enumerateChangesForObserver:(id<NSFileProviderChangeObserver>)observer fromSyncAnchor:(NSFileProviderSyncAnchor)anchor
{
    /* TODO:
     - query the server for updates since the passed-in sync anchor
     
     If this is an enumerator for the active set:
     - note the changes in your local database
     
     - inform the observer about item deletions and updates (modifications + insertions)
     - inform the observer when you have finished enumerating up to a subsequent sync anchor
     */
}

#pragma mark - Private methods
- (void)enumerateItemsInMyFiles
{
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:self.enumeratedItemIdentifier];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            [self.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
            [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                if(error)
                {
                    [self.observer finishEnumeratingWithError:error];
                }
                else
                {
                    self.requestedFolder = folder;
                    [self enumerateItemsInFolder:self.requestedFolder withSession:session];
                }
            }];
        }
    }];
}

- (void)enumerateItemsInSharedFiles
{
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:self.enumeratedItemIdentifier];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            [self.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
            [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                if(error)
                {
                    [self.observer finishEnumeratingWithError:error];
                }
                else
                {
                    self.requestedFolder = folder;
                    [self enumerateItemsInFolder:self.requestedFolder withSession:session];
                }
            }];
        }
    }];
}

- (void)enumerateItemsInFavoriteFolder
{
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:self.enumeratedItemIdentifier];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            [self.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
            [documentService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
                if(!error)
                {
                    NSMutableArray *fileProviderItems = [NSMutableArray new];
                    for (AlfrescoNode *node in pagingResult.objects)
                    {
                        AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAlfrescoNode:node parentItemIdentifier:self.enumeratedItemIdentifier];
                        [fileProviderItems addObject:item];
                    }
                    [self.observer didEnumerateItems:fileProviderItems];
                    [self.observer finishEnumeratingUpToPage:nil];
                }
                else
                {
                    [self.observer finishEnumeratingWithError:error];
                }
            }];
        }
    }];
}

- (void)enumerateItemsInFolderWithFolderRef:(NSString *)folderRef
{
    NSString *accountIdentifier = [AlfrescoFileProviderItemIdentifier getAccountIdentifierFromEnumeratedFolderIdenfitier:self.enumeratedItemIdentifier];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            [self.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            [documentFolderService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
                if (nodeRefError)
                {
                    [self.observer finishEnumeratingWithError:nodeRefError];
                }
                else if ([nodeRefNode isKindOfClass:[AlfrescoFolder class]])
                {
                    [self enumerateItemsInFolder:(AlfrescoFolder *)nodeRefNode withSession:session];
                }
            }];

        }
    }];
}

- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder withSession:(id<AlfrescoSession>)session
{
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (!error)
        {
            NSMutableArray *fileProviderItems = [NSMutableArray new];
            for (AlfrescoNode *node in pagingResult.objects)
            {
                AlfrescoFileProviderItem *item = [[AlfrescoFileProviderItem alloc] initWithAlfrescoNode:node parentItemIdentifier:self.enumeratedItemIdentifier];
                [fileProviderItems addObject:item];
            }
            [self.observer didEnumerateItems:fileProviderItems];
            [self.observer finishEnumeratingUpToPage:nil];
        }
        else
        {
            [self.observer finishEnumeratingWithError:error];
        }
    }];
}

@end
