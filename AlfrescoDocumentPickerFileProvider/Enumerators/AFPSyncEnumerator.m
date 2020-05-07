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

#import "AFPSyncEnumerator.h"
#import "AFPDataManager.h"
#import "AFPItem.h"
#import "AFPItemIdentifier.h"
#import "AFPServerEnumerator+Internals.h"
#import "AFPErrorBuilder.h"

@implementation AFPSyncEnumerator

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSError *authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if (authenticationError)
    {
        [observer finishEnumeratingWithError:authenticationError];
    }
    else
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:self.itemIdentifier];
        if(identifierType == AlfrescoFileProviderItemIdentifierTypeSynced)
        {
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
            NSMutableArray *enumeratedSyncedItems = [NSMutableArray new];
            RLMResults<RealmSyncNodeInfo *> *syncedItems = [[AFPDataManager sharedManager] syncItemsInParentNodeWithSyncId:nil forAccountIdentifier:accountIdentifier];
            for(RealmSyncNodeInfo *node in syncedItems)
            {
                AFPItem *fpItem = [[AFPItem alloc] initWithSyncedNode:node parentItemIdentifier:self.itemIdentifier];
                [enumeratedSyncedItems addObject:fpItem];
            }
            
            [observer didEnumerateItems:enumeratedSyncedItems];
            [observer finishEnumeratingUpToPage:nil];

        }
        else
        {
            AFPPage *alfrescoPage = [NSKeyedUnarchiver unarchiveObjectWithData:page];
            if(alfrescoPage.hasMoreItems || alfrescoPage == nil)
            {
                __weak typeof(self) weakSelf = self;
                self.networkOperationsComplete = NO;
                self.observer = observer;
                [self setupSessionWithCompletionBlock:^(id<AlfrescoSession> session) {
                    __strong typeof(self) strongSelf = weakSelf;
                    strongSelf.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                    RealmSyncNodeInfo *syncNode = [[AFPDataManager sharedManager] syncItemForId:strongSelf.itemIdentifier];
                    AlfrescoNode *parentNode = syncNode.alfrescoNode;
                    [strongSelf enumerateItemsInFolder:(AlfrescoFolder *)parentNode skipCount:alfrescoPage.skipCount];
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
            }
        }
    }
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

@end
