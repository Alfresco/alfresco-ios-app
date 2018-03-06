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
    
    __weak typeof(self) weakSelf = self;
    [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
        __strong typeof(self) strongSelf = weakSelf;
        strongSelf.customFolderService = [[CustomFolderService alloc] initWithSession:session];
        strongSelf.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier];
        switch (identifierType) {
            case AlfrescoFileProviderItemIdentifierTypeMyFiles:
            {
                [strongSelf enumerateItemsInMyFiles];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
            {
                [strongSelf enumerateItemsInSharedFiles];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeFolder:
            {
                NSString *folderRef = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
                [strongSelf enumerateItemsInFolderWithFolderRef:folderRef];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeFavorites:
            {
                [strongSelf enumerateItemsInFavoriteFolder];
                break;
            }
            case AlfrescoFileProviderItemIdentifierTypeSite:
            {
                strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                NSString *siteShortName = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
                [strongSelf enumerateItemsInSiteWithSiteShortName:siteShortName];
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
    __weak typeof(self) weakSelf = self;
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:folder error:error];
    }];
}

- (void)enumerateItemsInSharedFiles
{
    __weak typeof(self) weakSelf = self;
    [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:folder error:error];
    }];
}

- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder
{
    __weak typeof(self) weakSelf = self;
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInFolderWithFolderRef:(NSString *)folderRef
{
    __weak typeof(self) weakSelf = self;
    [self.documentService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:nodeRefNode error:nodeRefError];
    }];
}

- (void)enumerateItemsInFavoriteFolder
{
    __weak typeof(self) weakSelf = self;
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    [self.documentService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedFolderWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInSiteWithSiteShortName:(NSString *)siteShortName
{
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveDocumentLibraryFolderForSite:siteShortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (folder)
        {
            [strongSelf enumerateItemsInFolder:folder];
        }
        else
        {
            [strongSelf.observer finishEnumeratingWithError:error];
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
