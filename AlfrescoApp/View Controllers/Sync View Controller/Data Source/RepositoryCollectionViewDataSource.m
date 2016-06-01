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

#import "RepositoryCollectionViewDataSource+Internal.h"
#import "FileFolderCollectionViewCell.h"
#import "BaseCollectionViewFlowLayout.h"
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "RealmSyncManager.h"

@implementation RepositoryCollectionViewDataSource

- (instancetype)initWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super init];
    if(!self)
    {
        return nil;
    }
    
    if(node)
    {
        self.parentNode = node;
        self.screenTitle = node.name;
    }
    
    self.session = session;
    self.delegate = delegate;
    
    return self;
}

- (void)setSession:(id<AlfrescoSession>)session
{
    if(session)
    {
        _session = session;
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:_session];
    }
}

#pragma mark - Reload methods
- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    [self reloadCollectionViewWithPagingResult:pagingResult data:nil error:error];
}

- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error
{
    if (pagingResult)
    {
        self.dataSourceCollection = data ?: [pagingResult.objects mutableCopy];
        self.moreItemsAvailable = pagingResult.hasMoreItems;
        [self.delegate dataSourceUpdated];
    }
}

#pragma mark - Permissions methods
- (void)retrievePermissionsForNode:(AlfrescoNode *)node
{
    [self.documentService retrievePermissionsOfNode:node completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (!error)
        {
            [self.nodesPermissions setValue:permissions forKey:node.identifier];
        }
    }];
}

- (void)retrieveAndSetPermissionsOfCurrentFolder
{
    [self.documentService retrievePermissionsOfNode:self.parentNode completionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (permissions)
        {
            self.parentFolderPermissions = permissions;
            [self.delegate didRetrievePermissionsForParentNode];
        }
        else
        {
            [self.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.permission.notfound", @"Permission retrieval failed")];
        }
    }];
}

#pragma mark - UICollectionViewDataSource methods
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.dataSourceCollection.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    FileFolderCollectionViewCell *nodeCell = [collectionView dequeueReusableCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier] forIndexPath:indexPath];
    
    AlfrescoNode *node = self.dataSourceCollection[indexPath.row];
    SyncNodeStatus *nodeStatus = [[RealmSyncManager sharedManager] syncStatusForNodeWithId:node.identifier];
    [nodeCell updateCellInfoWithNode:node nodeStatus:nodeStatus];
    [nodeCell registerForNotifications];
    
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    BOOL isSyncOn = [[RealmSyncManager sharedManager] isNodeInSyncList:node];
    BOOL isTopLevelNode = [[RealmSyncManager sharedManager] isTopLevelSyncNode:node];
    
    [nodeCell updateStatusIconsIsFavoriteNode:NO isSyncNode:isSyncOn isTopLevelSyncNode:isTopLevelNode animate:NO];
    [favoriteManager isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        [nodeCell updateStatusIconsIsFavoriteNode:isFavorite isSyncNode:isSyncOn isTopLevelSyncNode:isTopLevelNode animate:NO];
    }];
    
    BaseCollectionViewFlowLayout *currentLayout = [self.delegate currentSelectedLayout];
    
    if (node.isFolder)
    {
        if(currentLayout.shouldShowSmallThumbnail)
        {
            [nodeCell.image setImage:smallImageForType(@"folder") withFade:NO];
        }
        else
        {
            [nodeCell.image setImage:largeImageForType(@"folder") withFade:NO];
        }
    }
    else if (node.isDocument)
    {
        AlfrescoDocument *document = (AlfrescoDocument *)node;
        ThumbnailManager *thumbnailManager = [ThumbnailManager sharedManager];
        UIImage *thumbnail = [thumbnailManager thumbnailForDocument:document renditionType:kRenditionImageDocLib];
        
        if (thumbnail)
        {
            [nodeCell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            if(currentLayout.shouldShowSmallThumbnail)
            {
                [nodeCell.image setImage:smallImageForType([document.name pathExtension]) withFade:NO];
            }
            else
            {
                [nodeCell.image setImage:largeImageForType([document.name pathExtension]) withFade:NO];
            }
            [thumbnailManager retrieveImageForDocument:document renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    FileFolderCollectionViewCell *updateCell = (FileFolderCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                    if (updateCell)
                    {
                        [updateCell.image setImage:image withFade:YES];
                    }
                }
            }];
        }
    }
    
    nodeCell.accessoryViewDelegate = [self.delegate cellAccessoryViewDelegate];
    return nodeCell;
}

#pragma mark - DataSourceInformationProtocol methods
- (NSInteger)indexOfNode:(AlfrescoNode *)node
{
    NSInteger index = NSNotFound;
    index = [self.dataSourceCollection indexOfObject:node];
    
    return index;
}

- (BOOL)isNodeAFolderAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if(indexPath.item < self.dataSourceCollection.count)
    {
        selectedNode = [self.dataSourceCollection objectAtIndex:indexPath.row];
    }
    
    return [selectedNode isKindOfClass:[AlfrescoFolder class]];
}

#pragma mark - Public methods
- (AlfrescoNode *)alfrescoNodeAtIndex:(NSInteger)index
{
    return self.dataSourceCollection[index];
}

- (NSInteger)numberOfNodesInCollection
{
    return self.dataSourceCollection.count;
}

#pragma mark - SwipeToDeleteDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSwipeToDeleteItemAtIndex:(NSIndexPath *)indexPath
{
    AlfrescoNode *nodeToDelete = self.dataSourceCollection[indexPath.item];
    AlfrescoPermissions *permissionsForNodeToDelete = [[RealmSyncManager sharedManager] permissionsForSyncNode:nodeToDelete];
    
    if (permissionsForNodeToDelete.canDelete)
    {
        [self deleteNode:nodeToDelete completionBlock:^(BOOL success) {
            if(success)
            {
                if([collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
                {
                    BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)collectionView.collectionViewLayout;
                    [properLayout setSelectedIndexPathForSwipeToDelete:nil];
                }
            }
        }];
    }
}

#pragma mark - Private methods
- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.documentService deleteNode:nodeToDelete completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            if([[RealmSyncManager sharedManager] isNodeInSyncList:nodeToDelete])
            {
                [[RealmSyncManager sharedManager] deleteNodeFromSync:nodeToDelete withCompletionBlock:^(BOOL savedLocally) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        NSString *successMessage = @"";
                        if (savedLocally)
                        {
                            successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message.sync", @"Delete Success Message"), nodeToDelete.name];
                        }
                        else
                        {
                            successMessage = [NSString stringWithFormat:NSLocalizedString(@"action.delete.success.message", @"Delete Success Message"), nodeToDelete.name];
                        }
                        displayInformationMessageWithTitle(successMessage, NSLocalizedString(@"action.delete.success.title", @"Delete Success Title"));
                    });
                }];
            }
            
            NSString *analyticsLabel = nil;
            if ([nodeToDelete isKindOfClass:[AlfrescoDocument class]])
            {
                analyticsLabel = ((AlfrescoDocument *)nodeToDelete).contentMimeType;
            }
            else if ([nodeToDelete isKindOfClass:[AlfrescoFolder class]])
            {
                analyticsLabel = kAnalyticsEventLabelFolder;
            }
            
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                              action:kAnalyticsEventActionDelete
                                                               label:analyticsLabel
                                                               value:@1];
            
            NSArray *collectionViewNodeIdentifiers = nil;
            NSIndexPath *indexPathForNode = nil;
            // remove nodeToDelete from collection view
            collectionViewNodeIdentifiers = [weakSelf.dataSourceCollection valueForKeyPath:@"identifier"];
            [weakSelf.dataSourceCollection removeObject:nodeToDelete];
            
            indexPathForNode = [self indexPathForNodeWithIdentifier:nodeToDelete.identifier inNodeIdentifiers:collectionViewNodeIdentifiers];
            if (indexPathForNode != nil)
            {
                [weakSelf.delegate didDeleteItems:[NSArray arrayWithObject:nodeToDelete] atIndexPaths:[NSArray arrayWithObject:indexPathForNode]];
            }
        }
        else
        {
            [weakSelf.delegate failedToDeleteItems:error];
        }
        
        if (completionBlock != NULL)
        {
            completionBlock(succeeded);
        }
    }];
}

- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)collectionViewNodeIdentifiers
{
    NSIndexPath *indexPath = nil;
    
    if (identifier != nil)
    {
        BOOL (^matchesAlfrescoNodeIdentifier)(NSString *, NSUInteger, BOOL *) = ^(NSString *nodeIdentifier, NSUInteger idx, BOOL *stop)
        {
            BOOL matched = NO;
            
            if ([nodeIdentifier isKindOfClass:[NSString class]] && [identifier hasPrefix:nodeIdentifier])
            {
                matched = YES;
                *stop = YES;
            }
            return matched;
        };
        
        // See if there's a matching node identifier in tableview node identifiers, using the block defined above
        
        NSUInteger matchingIndex = NSNotFound;
        NSUInteger inSection = 0;
        
        for (int i = 0; i < collectionViewNodeIdentifiers.count; i++)
        {
            id item = collectionViewNodeIdentifiers[i];
            
            if ([item isKindOfClass:[NSArray class]] || [item isKindOfClass:[NSMutableArray class]])
            {
                matchingIndex = [item indexOfObjectPassingTest:matchesAlfrescoNodeIdentifier];
                
                if (matchingIndex != NSNotFound)
                {
                    inSection = i;
                    break;
                }
            }
            else
            {
                matchingIndex = [collectionViewNodeIdentifiers indexOfObjectPassingTest:matchesAlfrescoNodeIdentifier];
                break;
            }
        }
        
        if (matchingIndex != NSNotFound)
        {
            indexPath = [NSIndexPath indexPathForRow:matchingIndex inSection:inSection];
        }
    }
    
    return indexPath;
}

@end
