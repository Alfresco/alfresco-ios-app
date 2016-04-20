/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "SyncCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"
#import "RealmSyncManager.h"
#import "RealmManager.h"
#import "RealmSyncHelper.h"
#import "RealmSyncNodeInfo.h"

@interface SyncCollectionViewDataSource()

@property (nonatomic, strong) RLMResults *syncDataSourceCollection;
@property (nonatomic, strong) RLMNotificationToken *token;

@end

@implementation SyncCollectionViewDataSource

- (instancetype)initWithParentNode:(AlfrescoNode *)node
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    self.parentNode = node;
    self.token = [[RealmSyncManager sharedManager] notificationTokenForAlfrescoNode:node notificationBlock:^(RLMResults *results, NSError *error) {
        if(results.count > 0)
        {
            self.syncDataSourceCollection = results;
            if(node)
            {
                RealmSyncNodeInfo *syncParentNode = self.syncDataSourceCollection.firstObject;
                [self setupDataSourceCollection:syncParentNode.nodes];
            }
            else
            {
                [self setupDataSourceCollection:self.syncDataSourceCollection];
            }
            
        }
    }];
    
    return self;
}

#pragma mark - Helper methods

- (void)setupDataSourceCollection:(id<NSFastEnumeration>)collection
{
    self.dataSourceCollection = [NSMutableArray new];
    for(RealmSyncNodeInfo *nodeInfo in collection)
    {
        [self.dataSourceCollection addObject:nodeInfo.alfrescoNode];
    }
    
    [self.delegate dataSourceHasChanged];
}

@end