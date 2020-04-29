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

#import "RepositoryCollectionViewDataSource+Internal.h"
#import "LoadingCollectionViewCell.h"
#import "BaseCollectionViewFlowLayout.h"
#import "SearchCollectionSectionHeader.h"
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "RealmSyncManager.h"
#import "AccountManager.h"

@implementation RepositoryCollectionViewDataSource

- (instancetype)init
{
    self = [super init];
    
    if (!self)
    {
        return nil;
    }
    
    self.defaultListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:kMaxItemsPerListingRetrieve skipCount:0];
    self.shouldAllowLayoutChange = YES;
    
    return self;
}

- (instancetype)initWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [self init];
    if(!self)
    {
        return nil;
    }
    
    [self setupWithParentNode:node session:session delegate:delegate];
    
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self.session = session;
    self.delegate = delegate;
    self.dataSourceCollection = [NSMutableArray new];
    if(node)
    {
        self.parentNode = node;
        self.screenTitle = node.name;
        self.nodesPermissions = [NSMutableDictionary new];
        
        [self retrieveContentsOfParentNode];
    }
    [self registerNotifications];
}

- (void)setSession:(id<AlfrescoSession>)session
{
    if(session)
    {
        _session = session;
        self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:_session];
    }
}

- (void)registerNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdated:) name:kAlfrescoDocumentUpdatedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentDeleted:) name:kAlfrescoDocumentDeletedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(nodeAdded:) name:kAlfrescoNodeAddedOnServerNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(documentUpdatedOnServer:) name:kAlfrescoSaveBackRemoteComplete object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(editingDocumentCompleted:) name:kAlfrescoDocumentEditedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionRefreshed:) name:kAlfrescoSessionRefreshedNotification object:nil];
}

#pragma mark - Reload methods

- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        self.dataSourceCollection = [pagingResult.objects mutableCopy];
        self.moreItemsAvailable = pagingResult.hasMoreItems;
        [self.delegate dataSourceUpdated];
    }
    else
    {
        [self.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.content.failedtoretrieve", @"Retrieve failed")];
    }
}

- (void)addMoreToCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error
{
    if (pagingResult)
    {
        NSMutableArray *arrayOfIndexPaths = [NSMutableArray new];
        for(NSInteger initialIndex = self.dataSourceCollection.count; initialIndex < self.dataSourceCollection.count + pagingResult.objects.count; initialIndex ++)
        {
            [arrayOfIndexPaths addObject:[NSIndexPath indexPathForItem:initialIndex inSection:0]];
        }
        [self.dataSourceCollection addObjectsFromArray:pagingResult.objects];
        
        self.moreItemsAvailable = pagingResult.hasMoreItems;
        [self.delegate dataSourceUpdated];
    }
    else
    {
        [self.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.content.failedtoretrieve", @"Retrieve failed")];
    }
}

#pragma mark - Permissions methods
- (void)retrievePermissionsForNode:(AlfrescoNode *)node
{
    [node retrieveNodePermissionsWithSession:self.session withCompletionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (permissions)
        {
            [self.nodesPermissions setValue:permissions forKey:[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
            [[RealmManager sharedManager] savePermissions:permissions forNode:node];
        }
    }];
}

- (void)retrieveAndSetPermissionsOfCurrentFolder
{
    [self.parentNode retrieveNodePermissionsWithSession:self.session withCompletionBlock:^(AlfrescoPermissions *permissions, NSError *error) {
        if (permissions)
        {
            self.parentFolderPermissions = permissions;
            [self.delegate didRetrievePermissionsForParentNode];
            [[RealmManager sharedManager] savePermissions:permissions forNode:self.parentNode];
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
    if((self.moreItemsAvailable) && (indexPath.item == self.dataSourceCollection.count))
    {
        LoadingCollectionViewCell *cell = (LoadingCollectionViewCell *)[collectionView dequeueReusableCellWithReuseIdentifier:[LoadingCollectionViewCell cellIdentifier] forIndexPath:indexPath];
        return cell;
    }
    else
    {
        FileFolderCollectionViewCell *nodeCell = [collectionView dequeueReusableCellWithReuseIdentifier:[FileFolderCollectionViewCell cellIdentifier] forIndexPath:indexPath];
        if(indexPath.item < self.dataSourceCollection.count)
        {
            AlfrescoNode *node = self.dataSourceCollection[indexPath.item];
            RealmSyncManager *syncManager = [RealmSyncManager sharedManager];
            
            SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
            [nodeCell updateCellInfoWithNode:node nodeStatus:nodeStatus];
            [nodeCell registerForNotifications];
            
            [self updateFavoriteStatusIconForNodeCell:nodeCell node:node];
            
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
                            // MOBILE-2991, check the tableView and indexPath objects are still valid as there is a chance
                            // by the time completion block is called the table view could have been unloaded.
                            if (collectionView && indexPath)
                            {
                                FileFolderCollectionViewCell *updateCell = (FileFolderCollectionViewCell *)[collectionView cellForItemAtIndexPath:indexPath];
                                [updateCell.image setImage:image withFade:YES];
                            }
                        }
                    }];
                }
            }
            
            nodeCell.accessoryViewDelegate = [self.delegate cellAccessoryViewDelegate];
        }
        return nodeCell;
    }
}

- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath
{
    UICollectionReusableView *reusableview = nil;
    if (kind == UICollectionElementKindSectionHeader)
    {
        SearchCollectionSectionHeader *headerView = (SearchCollectionSectionHeader *)[collectionView dequeueReusableSupplementaryViewOfKind:UICollectionElementKindSectionHeader withReuseIdentifier:@"SectionHeader" forIndexPath:indexPath];

        if(!headerView.hasAddedSearchBar)
        {
            UISearchBar *searchBar = [self.delegate searchBarForSupplimentaryHeaderView];
            headerView.searchBar = searchBar;
            [headerView addSubview:searchBar];
            [searchBar sizeToFit];
            headerView.hasAddedSearchBar = YES;
        }

        reusableview = headerView;
    }

    return reusableview;
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
    AlfrescoNode *nodeToReturn = nil;
    if(index < self.dataSourceCollection.count)
    {
        nodeToReturn = self.dataSourceCollection[index];
    }
    
    return nodeToReturn;
}

- (NSInteger)numberOfNodesInCollection
{
    return self.dataSourceCollection.count;
}

- (void)deleteNode:(AlfrescoNode *)nodeToDelete completionBlock:(void (^)(BOOL success))completionBlock
{
    __weak typeof(self) weakSelf = self;
    [self.documentService deleteNode:nodeToDelete completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            NSString *analyticsLabel = nil;
            
            if([nodeToDelete isNodeInSyncList])
            {
                [[RealmSyncManager sharedManager] deleteNodeFromSync:nodeToDelete deleteRule:DeleteRuleAllNodes withCompletionBlock:^(BOOL savedLocally) {
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

- (void)createFolderWithName:(NSString *)folderName
{
    if(self.parentNode)
    {
        [self.documentService createFolderWithName:folderName inParentFolder:(AlfrescoFolder *)self.parentNode properties:nil completionBlock:^(AlfrescoFolder *folder, NSError *error) {
            if (folder)
            {
                [self retrievePermissionsForNode:folder];
                [self addAlfrescoNodes:@[folder]];
                [[RealmSyncManager sharedManager] didUploadNode:folder fromPath:nil toFolder:(AlfrescoFolder *)self.parentNode];
                
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryDM
                                                                  action:kAnalyticsEventActionCreate
                                                                   label:kAnalyticsEventLabelFolder
                                                                   value:@1];
            }
            else
            {
                [self.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.createfolder.createfolder", @"Creation failed")];
            }
        }];
    }
}

- (void)retrieveNextItems:(AlfrescoListingContext *)moreListingContext
{
    [self retrieveContentOfFolder:(AlfrescoFolder *)self.parentNode usingListingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        [self addMoreToCollectionViewWithPagingResult:pagingResult error:error];
    }];
}

- (AlfrescoPermissions *)permissionsForNode:(AlfrescoNode *)node
{
    AlfrescoPermissions *permissions = nil;
    if(node)
    {
        NSString *nodeIdentifier = [[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node];
        permissions = self.nodesPermissions[nodeIdentifier];
    }
    
    return permissions;
}

- (NSArray *)nodeIdentifiersOfCurrentCollection
{
    NSArray *collectionViewNodeIdentifiers = [self.dataSourceCollection valueForKeyPath:@"identifier"];
    return collectionViewNodeIdentifiers;
}

- (void)addAlfrescoNodes:(NSArray *)alfrescoNodes
{
    NSComparator comparator = ^(AlfrescoNode *obj1, AlfrescoNode *obj2) {
        return (NSComparisonResult)[obj1.name caseInsensitiveCompare:obj2.name];
    };
    
    NSMutableArray *newNodeIndexPaths = [NSMutableArray arrayWithCapacity:alfrescoNodes.count];
    for (AlfrescoNode *node in alfrescoNodes)
    {
        AlfrescoPermissions *nodePermissions = self.nodesPermissions[[[RealmSyncCore sharedSyncCore] syncIdentifierForNode:node]];
        if(!nodePermissions)
        {
            [self retrievePermissionsForNode:node];
        }
        // add to the collectionView data source at the correct index
        NSUInteger newIndex = [self.dataSourceCollection indexOfObject:node inSortedRange:NSMakeRange(0, self.dataSourceCollection.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
        [self.dataSourceCollection insertObject:node atIndex:newIndex];
        // create index paths to animate into the table view
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:newIndex inSection:0];
        [newNodeIndexPaths addObject:indexPath];
    }
    
    [self.delegate didAddNodes:alfrescoNodes atIndexPath:newNodeIndexPaths];
}

- (void)reloadDataSource
{
    [self retrieveContentsOfParentNode];
}

- (AlfrescoFolder *)parentFolder
{
    AlfrescoFolder *parent = nil;
    
    if (_parentNode.isFolder)
    {
        parent = (AlfrescoFolder *)_parentNode;
    }

    return parent;
}

#pragma mark - SwipeToDeleteDelegate methods
- (void)collectionView:(UICollectionView *)collectionView didSwipeToDeleteItemAtIndex:(NSIndexPath *)indexPath completionBlock:(void (^)(void))completionBlock
{
    AlfrescoNode *nodeToDelete = self.dataSourceCollection[indexPath.item];
    
    [self deleteNode:nodeToDelete completionBlock:^(BOOL success) {
        if(success)
        {
            if([collectionView.collectionViewLayout isKindOfClass:[BaseCollectionViewFlowLayout class]])
            {
                BaseCollectionViewFlowLayout *properLayout = (BaseCollectionViewFlowLayout *)collectionView.collectionViewLayout;
                [properLayout setSelectedIndexPathForSwipeToDelete:nil];
            }
        }
        
        if (completionBlock)
        {
            completionBlock();
        }
    }];
}

#pragma mark - Private methods

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

- (void)retrieveContentsOfParentNode
{
    __weak typeof(self) weakSelf = self;
    if(self.parentNode)
    {
        [self.documentService retrieveChildrenInFolder:(AlfrescoFolder *)self.parentNode listingContext:self.defaultListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
            if (!error)
            {
                for (AlfrescoNode *node in pagingResult.objects)
                {
                    [weakSelf retrievePermissionsForNode:node];
                }
                
                if (!self.parentFolderPermissions)
                {
                    [self retrieveAndSetPermissionsOfCurrentFolder];
                }
                else
                {
                    [self.delegate didRetrievePermissionsForParentNode];
                }
            }
            
            [self reloadCollectionViewWithPagingResult:pagingResult error:error];
        }];
    }
    else
    {
        [self.delegate dataSourceUpdated];
    }
}

- (void)retrieveContentOfFolder:(AlfrescoFolder *)folder usingListingContext:(AlfrescoListingContext *)listingContext completionBlock:(void (^)(AlfrescoPagingResult *pagingResult, NSError *error))completionBlock;
{
    if (!listingContext)
    {
        listingContext = self.defaultListingContext;
    }
    
    [self.documentService retrieveChildrenInFolder:folder listingContext:listingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if (!error)
        {
            for (AlfrescoNode *node in pagingResult.objects)
            {
                [self retrievePermissionsForNode:node];
            }
        }
        if (completionBlock != NULL)
        {
            completionBlock(pagingResult, error);
        }
    }];
}

- (void)updateFavoriteStatusIconForNodeCell:(FileFolderCollectionViewCell *)nodeCell node:(AlfrescoNode *)node
{
    BOOL isSyncOn = [node isNodeInSyncList];
    BOOL isTopLevelNode = [node isTopLevelSyncNode];

    [nodeCell updateStatusIconsIsFavoriteNode:NO isSyncNode:isSyncOn isTopLevelSyncNode:isTopLevelNode animate:NO];
    [[FavouriteManager sharedManager] isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        [nodeCell updateStatusIconsIsFavoriteNode:isFavorite isSyncNode:isSyncOn isTopLevelSyncNode:isTopLevelNode animate:NO];
    }];
}

#pragma mark - Notification methods
- (void)documentUpdated:(NSNotification *)notification
{
    id updatedDocumentObject = notification.object;
    id existingDocumentObject = notification.userInfo[kAlfrescoDocumentUpdatedFromDocumentParameterKey];
    
    // this should always be an AlfrescoDocument. If it isn't something has gone terribly wrong...
    if ([updatedDocumentObject isKindOfClass:[AlfrescoDocument class]])
    {
        AlfrescoDocument *existingDocument = (AlfrescoDocument *)existingDocumentObject;
        AlfrescoDocument *updatedDocument = (AlfrescoDocument *)updatedDocumentObject;
        
        NSArray *allIdentifiers = [self.dataSourceCollection valueForKey:@"identifier"];
        if ([allIdentifiers containsObject:existingDocument.identifier])
        {
            NSUInteger index = [allIdentifiers indexOfObject:existingDocument.identifier];
            [self.dataSourceCollection replaceObjectAtIndex:index withObject:updatedDocument];
            NSIndexPath *indexPathOfDocument = [NSIndexPath indexPathForRow:index inSection:0];
            
            [self.delegate reloadItemsAtIndexPaths:@[indexPathOfDocument] reselectItems:YES];
        }
    }
    else
    {
        @throw ([NSException exceptionWithName:@"AlfrescoNode update exception in FileFolderListViewController - (void)documentUpdated:"
                                        reason:@"No document node returned from the edit file service"
                                      userInfo:nil]);
    }
}

- (void)documentDeleted:(NSNotification *)notification
{
    AlfrescoDocument *deletedDocument = notification.object;
    
    if ([self.dataSourceCollection containsObject:deletedDocument])
    {
        NSUInteger index = [self.dataSourceCollection indexOfObject:deletedDocument];
        NSIndexPath *indexPathOfDeletedNode = [NSIndexPath indexPathForRow:index inSection:0];
        [self.dataSourceCollection removeObject:deletedDocument];
        [self.delegate didDeleteItems:@[deletedDocument] atIndexPaths:@[indexPathOfDeletedNode]];
    }
}

- (void)nodeAdded:(NSNotification *)notification
{
    NSDictionary *foldersDictionary = notification.object;
    
    AlfrescoFolder *parentFolder = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerParentFolderKey];
    
    if ([parentFolder isEqual:self.parentNode])
    {
        AlfrescoNode *subnode = [foldersDictionary objectForKey:kAlfrescoNodeAddedOnServerSubNodeKey];
        [self retrievePermissionsForNode:subnode];
        [self addAlfrescoNodes:@[subnode]];
        [[RealmSyncManager sharedManager] didUploadNode:subnode fromPath:nil toFolder:(AlfrescoFolder *)self.parentNode];
    }
}

- (void)documentUpdatedOnServer:(NSNotification *)notification
{
    NSString *nodeIdentifierUpdated = notification.object;
    AlfrescoDocument *updatedDocument = notification.userInfo[kAlfrescoDocumentUpdatedFromDocumentParameterKey];
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:nodeIdentifierUpdated inNodeIdentifiers:[self.dataSourceCollection valueForKey:@"identifier"]];
    
    if (indexPath)
    {
        [self.dataSourceCollection replaceObjectAtIndex:indexPath.row withObject:updatedDocument];
        [self.delegate reloadItemsAtIndexPaths:@[indexPath] reselectItems:NO];
    }
}

- (void)editingDocumentCompleted:(NSNotification *)notification
{
    AlfrescoDocument *editedDocument = notification.object;
    
    NSIndexPath *indexPath = [self indexPathForNodeWithIdentifier:editedDocument.name inNodeIdentifiers:[self.dataSourceCollection valueForKey:@"name"]];
    
    if (indexPath)
    {
        [self.dataSourceCollection replaceObjectAtIndex:indexPath.row withObject:editedDocument];
        [self.delegate reloadItemsAtIndexPaths:@[indexPath] reselectItems:NO];
    }
}

- (void)sessionRefreshed:(NSNotification *)notification
{
    self.session = notification.object;
}

- (NSString*)getSearchType
{
    return kAlfrescoModelTypeContent;
}

@end
