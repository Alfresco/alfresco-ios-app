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

#import "SyncCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"
#import "RealmManager.h"
#import "RealmSyncNodeInfo.h"

@interface SyncCollectionViewDataSource()

@property (nonatomic, strong) RLMResults *syncDataSourceCollection;
@property (nonatomic, strong) RLMNotificationToken *token;

@end

@implementation SyncCollectionViewDataSource

- (instancetype)initWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super initWithParentNode:node session:session delegate:delegate];
    if(!self)
    {
        return nil;
    }
    
    if(!node)
    {
        self.screenTitle = NSLocalizedString(@"sync.title", @"Sync Title");
    }
    self.emptyMessage = NSLocalizedString(@"sync.empty", @"No Synced Content");
    self.shouldAllowMultiselect = NO;
    
    [RealmSyncManager sharedManager].syncDisabledDelegate = self;
    [self reloadDataSource];
    
    return self;
}

- (void)reloadDataSource
{
    __weak typeof(self) weakSelf = self;
    self.token = [[RealmSyncManager sharedManager] notificationTokenForAlfrescoNode:self.parentNode notificationBlock:^(RLMResults<RealmSyncNodeInfo *> *results, RLMCollectionChange *change, NSError *error) {
        if(results.count > 0)
        {
            weakSelf.syncDataSourceCollection = results;
            if(weakSelf.parentNode)
            {
                RealmSyncNodeInfo *syncParentNode = weakSelf.syncDataSourceCollection.firstObject;
                [weakSelf setupDataSourceCollection:syncParentNode.nodes];
            }
            else
            {
                [weakSelf setupDataSourceCollection:weakSelf.syncDataSourceCollection];
            }
        }
        else if(error)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                [weakSelf.delegate requestFailedWithError:error stringFormat:@"%@"];
            });
        }
        else
        {
            [weakSelf setupDataSourceCollection:[NSMutableArray new]];
        }
    }];
}

#pragma mark - Helper methods

- (void)setupDataSourceCollection:(id<NSFastEnumeration>)collection
{
    self.dataSourceCollection = [NSMutableArray new];
    self.nodesPermissions = [NSMutableDictionary new];
    for(RealmSyncNodeInfo *nodeInfo in collection)
    {
        if (nodeInfo.alfrescoNode)
        {
            [self.dataSourceCollection addObject:nodeInfo.alfrescoNode];
            if(nodeInfo.alfrescoPermissions)
            {
                [self.nodesPermissions setObject:nodeInfo.alfrescoPermissions forKey:nodeInfo.alfrescoNode.identifier];
            }
        }
    }
    
    NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"name" ascending:YES selector:@selector(caseInsensitiveCompare:)];
    [self.dataSourceCollection sortUsingDescriptors:@[sortDescriptor]];
    
    __weak typeof(self) weakSelf = self;
    dispatch_async(dispatch_get_main_queue(), ^{
        [weakSelf.delegate dataSourceUpdated];
    });
}

- (void)retrieveContentsOfParentNode
{
    //Nothing to do as the sync data is available offline - this overrides the method in the parent class
}

#pragma mark - RealmSyncManagerSyncDisabledDelegate methods
- (void)syncFeatureStatusChanged:(BOOL)isSyncOn
{
    [self.token invalidate];
    if(!isSyncOn)
    {
        [self setupDataSourceCollection:nil];
    }
    else
    {
        [self reloadDataSource];
    }
}

@end
