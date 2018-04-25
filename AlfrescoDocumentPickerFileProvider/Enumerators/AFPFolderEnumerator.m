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

@interface AFPFolderEnumerator()

@property (atomic) BOOL networkOperationsComplete;

@end

@implementation AFPFolderEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    AFPPage *alfrescoPage = [NSKeyedUnarchiver unarchiveObjectWithData:page];
    if(alfrescoPage.hasMoreItems || alfrescoPage == nil)
    {
        self.observer = observer;
        __weak typeof(self) weakSelf = self;
        self.networkOperationsComplete = NO;
        [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
            __strong typeof(self) strongSelf = weakSelf;
            if(!strongSelf.customFolderService)
            {
                strongSelf.customFolderService = [[CustomFolderService alloc] initWithSession:session];
                strongSelf.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            }
            
            AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:strongSelf.itemIdentifier];
            switch (identifierType) {
                case AlfrescoFileProviderItemIdentifierTypeMyFiles:
                {
                    [strongSelf enumerateItemsInMyFilesWithSkipCount:alfrescoPage.skipCount];
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
                {
                    [strongSelf enumerateItemsInSharedFilesWithSkipCount:alfrescoPage.skipCount];
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeFolder:
                {
                    NSString *folderRef = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:strongSelf.itemIdentifier];
                    [strongSelf enumerateItemsInFolderWithFolderRef:folderRef skipCount:alfrescoPage.skipCount];
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeFavorites:
                {
                    [strongSelf enumerateItemsInFavoriteFolderWithSkipCount:alfrescoPage.skipCount];
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeSite:
                {
                    strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                    NSString *siteShortName = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:strongSelf.itemIdentifier];
                    [strongSelf enumerateItemsInSiteWithSiteShortName:siteShortName skipCount:alfrescoPage.skipCount];
                    break;
                }
                default:
                    break;
            }
            
            /*
             * Keep this object around long enough for the network operations to complete.
             * Running as a background thread, seperate from the UI, so should not cause
             * Any issues when blocking the thread.
             */
            do
            {
                [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            }
            while (self.networkOperationsComplete == NO);
        }];
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

#pragma mark - Private methods

- (void)enumerateItemsInMyFilesWithSkipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:folder skipCount:skipCount error:error];
    }];
}

- (void)enumerateItemsInSharedFilesWithSkipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:folder skipCount:skipCount error:error];
    }];
}

- (void)enumerateItemsInFolder:(AlfrescoFolder *)folder skipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:skipCount];
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedFolderWithPagingResult:pagingResult skipCount:skipCount error:error];
    }];
}

- (void)enumerateItemsInFolderWithFolderRef:(NSString *)folderRef skipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    [self.documentService retrieveNodeWithIdentifier:folderRef completionBlock:^(AlfrescoNode *nodeRefNode, NSError *nodeRefError) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedCustomFolder:nodeRefNode skipCount:skipCount error:nodeRefError];
    }];
}

- (void)enumerateItemsInFavoriteFolderWithSkipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:skipCount];
    [self.documentService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedFolderWithPagingResult:pagingResult skipCount:skipCount error:error];
    }];
}

- (void)enumerateItemsInSiteWithSiteShortName:(NSString *)siteShortName skipCount:(int)skipCount
{
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveDocumentLibraryFolderForSite:siteShortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        if (folder)
        {
            [strongSelf enumerateItemsInFolder:folder skipCount:skipCount];
        }
        else
        {
            [strongSelf.observer finishEnumeratingWithError:error];
            self.networkOperationsComplete = YES;
        }
    }];
}

- (void)handleEnumeratedCustomFolder:(AlfrescoNode *)node skipCount:(int)skipCount error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
        self.networkOperationsComplete = YES;
    }
    else if ([node isKindOfClass:[AlfrescoFolder class]])
    {
        [self enumerateItemsInFolder:(AlfrescoFolder *)node skipCount:skipCount];
    }
}

- (void)handleEnumeratedFolderWithPagingResult:(AlfrescoPagingResult *)pagingResult skipCount:(int)skipCount error:(NSError *)error
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
        
        int newSkipCount = skipCount + (int)pagingResult.objects.count;
        AFPPage *newPage = [[AFPPage alloc] initWithSkipCount:newSkipCount hasMoreItems:pagingResult.hasMoreItems];
        NSFileProviderPage page = [NSKeyedArchiver archivedDataWithRootObject:newPage];
        [self.observer finishEnumeratingUpToPage:page];
    }
    self.networkOperationsComplete = YES;
}

@end
