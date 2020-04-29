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

#import "AFPServerEnumerator+Internals.h"
#import "AFPErrorBuilder.h"

@implementation AFPServerEnumerator

- (instancetype)initWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    self = [super init];
    if(self)
    {
        self.itemIdentifier = itemIdentifier;
        self.childrenIdentifiers = [NSMutableArray new];
    }
    
    return self;
}

- (AlfrescoSiteService *)siteService
{
    if(_siteService)
    {
        [_siteService clear];
    }
    
    return _siteService;
}

#pragma mark - Internal methods

- (void)setupSessionWithCompletionBlock:(void (^)(id<AlfrescoSession> session))completionBlock
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
    __weak typeof(self) weakSelf = self;
    self.accountManager = [AFPAccountManager sharedManager];
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
        if(loginError)
        {
            __strong typeof(self) strongSelf = weakSelf;
            [strongSelf.observer finishEnumeratingWithError:loginError];
        }
        else
        {
            completionBlock(session);
        }
    }];
}

- (void)handleEnumeratedCustomFolder:(AlfrescoNode *)node skipCount:(int)skipCount error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:[AFPErrorBuilder fileProviderErrorForGenericError:error]];
        self.networkOperationsComplete = YES;
    }
    else if ([node isKindOfClass:[AlfrescoFolder class]])
    {
        [self enumerateItemsInFolder:(AlfrescoFolder *)node skipCount:skipCount];
    }
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

- (void)handleEnumeratedFolderWithPagingResult:(AlfrescoPagingResult *)pagingResult skipCount:(int)skipCount error:(NSError *)error
{
    if (error)
    {
        [self.observer finishEnumeratingWithError:[AFPErrorBuilder fileProviderErrorForGenericError:error]];
    }
    else
    {
        NSMutableArray *fileProviderItems = [NSMutableArray new];
        NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
        RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
        
        if([AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier] == AlfrescoFileProviderItemIdentifierTypeSyncFolder)
        {
            for (AlfrescoNode *node in pagingResult.objects)
            {
                RealmSyncNodeInfo *syncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:YES inRealm:realm];
                AFPItem *item = [[AFPItem alloc] initWithSyncedNode:syncNode parentItemIdentifier:self.itemIdentifier];
                [fileProviderItems addObject:item];
                [self.childrenIdentifiers addObject:syncNode.syncNodeInfoId];
            }
            
            if(!pagingResult.hasMoreItems)
            {
                RealmSyncNodeInfo *syncFolder = [[AFPDataManager sharedManager] syncItemForId:self.itemIdentifier];
                [[AFPDataManager sharedManager] cleanRemovedChildrenFromSyncFolder:syncFolder.alfrescoNode usingUpdatedChildrenIdList:self.childrenIdentifiers fromAccountIdentifier:accountIdentifier];
            }
        }
        else
        {
            for (AlfrescoNode *node in pagingResult.objects)
            {
                AFPItem *item;
                if([[RealmSyncCore sharedSyncCore] isNode:node inSyncListInRealm:realm])
                {
                    RealmSyncNodeInfo *syncNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:node ifNotExistsCreateNew:NO inRealm:realm];
                    item = [[AFPItem alloc] initWithSyncedNode:syncNode parentItemIdentifier:self.itemIdentifier];
                }
                else
                {
                    AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveNode:node parentIdentifier:self.itemIdentifier];
                    item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
                }
                [fileProviderItems addObject:item];
            }
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
