/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

#import "AFPFolderEnumerator.h"
#import "AFPServerEnumerator+Internals.h"
#import "CustomFolderService.h"

@interface AFPFolderEnumerator()

@property (nonatomic, strong) CustomFolderService *customFolderService;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;

@end

@implementation AFPFolderEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    self.observer = observer;
    
    [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
        self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier];
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
                NSString *folderRef = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
                [self enumerateItemsInFolderWithFolderRef:folderRef];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeFavorites:
            {
                [self enumerateItemsInFavoriteFolder];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeSite:
            {
                self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                NSString *siteShortName = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
                [self enumerateItemsInSiteWithSiteShortName:siteShortName];
                break;
            }
            default:
                break;
        }
    }];
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

#pragma mark - Private methods

- (void)enumerateItemsInMyFiles
{
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        [self handleEnumeratedCustomFolder:folder error:error];
    }];
}

- (void)enumerateItemsInSharedFiles
{
    [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        [self handleEnumeratedCustomFolder:folder error:error];
    }];
}

- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInFolderWithFolderRef:(NSString *)folderRef
{
    [self.documentService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        [self handleEnumeratedCustomFolder:nodeRefNode error:nodeRefError];
    }];
}

- (void)enumerateItemsInFavoriteFolder
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInSiteWithSiteShortName:(NSString *)siteShortName
{
    [self.siteService retrieveDocumentLibraryFolderForSite:siteShortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
        if (folder)
        {
            [self enumerateItemsInFolder:folder];
        }
        else
        {
            [self.observer finishEnumeratingWithError:error];
        }
    }];
}

- (void)handleEnumeratedCustomFolder:(AlfrescoNode *)node error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
    }
    else if ([node isKindOfClass:[AlfrescoFolder class]])
    {
        [self enumerateItemsInFolder:(AlfrescoFolder *)node];
    }
}

- (void)handleEnumeratedFolderWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
    }
    else
    {
        NSMutableArray *fileProviderItems = [NSMutableArray new];
        for (AlfrescoNode *node in pagingResult.objects)
        {
            AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveNode:node parentIdentifier:self.itemIdentifier];
            AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
            [fileProviderItems addObject:item];
        }
        [self.observer didEnumerateItems:fileProviderItems];
        [self.observer finishEnumeratingUpToPage:nil];
    }
}

@end
