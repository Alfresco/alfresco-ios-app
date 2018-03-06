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

#import "AFPSiteEnumerator.h"
#import "AFPServerEnumerator+Internals.h"

@implementation AFPSiteEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    self.observer = observer;
    AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier];
    __weak typeof(self) weakSelf = self;
    switch (identifierType) {
        case AlfrescoFileProviderItemIdentifierTypeSites:
        {
            [self enumerateItemsInSites];
            break;
        }
        case AlfrescoFileProviderItemIdentifierTypeMySites:
        {
            [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                [strongSelf enumerateItemsInMySites];
            }];
            break;
        }
        case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
        {
            [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                __strong typeof(self) strongSelf = weakSelf;
                strongSelf.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
                [strongSelf enumerateItemsInFavoriteSites];
            }];
            break;
        }
            
        default:
            break;
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

- (void)enumerateItemsInMySites
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedSitesWithPagingResult:pagingResult error:error];
    }];
}

- (void)enumerateItemsInFavoriteSites
{
    AlfrescoListingContext *listingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kFileProviderMaxItemsPerListingRetrieve skipCount:0];
    __weak typeof(self) weakSelf = self;
    [self.siteService retrieveFavoriteSitesWithListingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf handleEnumeratedSitesWithPagingResult:pagingResult error:error];
    }];
}

- (void)handleEnumeratedSitesWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:error];
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
        [self.observer finishEnumeratingUpToPage:nil];
    }
}

@end
