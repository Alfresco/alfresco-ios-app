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

#import "AFPSiteEnumerator.h"
#import "AFPServerEnumerator+Internals.h"
#import "AFPErrorBuilder.h"

@implementation AFPSiteEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        AFPPage *alfrescoPage = [NSKeyedUnarchiver unarchiveObjectWithData:page];
        if(alfrescoPage.hasMoreItems || alfrescoPage == nil)
        {
            self.observer = observer;
            self.networkOperationsComplete = NO;
            AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier];
            switch (identifierType) {
                case AlfrescoFileProviderItemIdentifierTypeSites:
                {
                    [self enumerateItemsInSites];
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeMySites:
                {
                    
                    __weak typeof(self) weakSelf = self;
                    [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                        __strong typeof(self) strongSelf = weakSelf;
                        strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                        [strongSelf enumerateItemsInMySitesWithSkipCount:alfrescoPage.skipCount];
                    }];
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
                    break;
                }
                case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
                {
                    __weak typeof(self) weakSelf = self;
                    [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                        __strong typeof(self) strongSelf = weakSelf;
                        strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                        [strongSelf enumerateItemsInFavoriteSitesWithSkipCount:alfrescoPage.skipCount];
                    }];
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
                    break;
                }
                    
                default:
                    break;
            }
        }
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

#pragma mark - Private methods

- (void)enumerateItemsInSites
{
    NSMutableArray *enumeratedResults = [NSMutableArray new];
    RLMResults<AFPItemMetadata *> *results = [[AFPDataManager sharedManager] menuItemsForParentIdentifier:self.itemIdentifier];
    for(AFPItemMetadata *result in results)
    {
        AFPItem *item = [[AFPItem alloc] initWithItemMetadata:result];
        [enumeratedResults addObject:item];
    }
    
    [self.observer didEnumerateItems:enumeratedResults];
    [self.observer finishEnumeratingUpToPage:nil];
}

- (void)enumerateItemsInMySitesWithSkipCount:(int)skipCount
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:skipCount];
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedSitesWithPagingResult:pagingResult skipCount:skipCount error:error];
    }];
}

- (void)enumerateItemsInFavoriteSitesWithSkipCount:(int)skipCount
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:skipCount];
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveFavoriteSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedSitesWithPagingResult:pagingResult skipCount:skipCount error:error];
    }];
}

- (void)handleEnumeratedSitesWithPagingResult:(AlfrescoPagingResult *)pagingResult skipCount:(int)skipCount error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:[AFPErrorBuilder fileProviderErrorForGenericError:error]];
    }
    else
    {
        NSMutableArray *enumeratedResults = [NSMutableArray new];
        for(AlfrescoSite *site in pagingResult.objects)
        {
            AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveSite:site parentIdentifier:self.itemIdentifier];
            AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
            [enumeratedResults addObject:item];
        }
        
        [self.observer didEnumerateItems:enumeratedResults];
        
        int newSkipCount = skipCount + (int)pagingResult.objects.count;
        AFPPage *newPage = [[AFPPage alloc] initWithSkipCount:newSkipCount hasMoreItems:pagingResult.hasMoreItems];
        NSFileProviderPage page = [NSKeyedArchiver archivedDataWithRootObject:newPage];
        [self.observer finishEnumeratingUpToPage:page];
    }
    self.networkOperationsComplete = YES;
}

@end
