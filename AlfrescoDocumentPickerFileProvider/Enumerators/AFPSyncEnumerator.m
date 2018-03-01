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

#import "AFPSyncEnumerator.h"
#import "AFPDataManager.h"
#import "AFPItem.h"
#import "AFPItemIdentifier.h"

@interface AFPSyncEnumerator()

@property (nonatomic, strong) NSFileProviderItemIdentifier itemIdentifier;

@end

@implementation AFPSyncEnumerator

- (instancetype)initWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.itemIdentifier = itemIdentifier;
    
    return self;
}

- (void)enumerateItemsForObserver:(id<NSFileProviderEnumerationObserver>)observer startingAtPage:(NSFileProviderPage)page
{
    NSMutableArray *enumeratedSyncedItems = [NSMutableArray new];
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:self.itemIdentifier];
    
    NSString *nodeId = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:self.itemIdentifier];
    
    RLMResults<RealmSyncNodeInfo *> *syncedItems = [[AFPDataManager sharedManager] syncItemsInNodeWithId:nodeId forAccountIdentifier:accountIdentifier];
    for(RealmSyncNodeInfo *node in syncedItems)
    {
        AFPItem *fpItem = [[AFPItem alloc] initWithSyncedNode:node parentItemIdentifier:self.itemIdentifier];
        [enumeratedSyncedItems addObject:fpItem];
    }
    
    [observer didEnumerateItems:enumeratedSyncedItems];
    [observer finishEnumeratingUpToPage:nil];
}

- (void)invalidate
{
    // TODO: perform invalidation of server connection if necessary
}

@end
