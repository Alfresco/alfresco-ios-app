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

#import "FavoritesCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"
#import "FavouriteManager.h"

@interface FavoritesCollectionViewDataSource ()

@property (nonatomic, strong) NSString *filter;

@end

@implementation FavoritesCollectionViewDataSource

- (instancetype)initWithFilter:(NSString *)filter session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate listingContext:(AlfrescoListingContext *)listingContext
{
    self = [super initWithParentNode:nil session:session delegate:delegate];
    if(!self)
    {
        return nil;
    }
    
    self.filter = filter ? filter : kAlfrescoConfigViewParameterFavoritesFiltersAll;
    self.shouldAllowMultiselect = NO;
    self.screenTitle = NSLocalizedString(@"favourites.title", @"Favorites Title");
    self.emptyMessage = NSLocalizedString(@"favourites.empty", @"No Favorites");
    
    if (listingContext)
    {
        self.defaultListingContext = listingContext;
    }
    
    [self registerForNotifications];
    [self reloadDataSource];
    
    return self;
}

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didAddNodeToFavorites:)
                                                 name:kFavouritesDidAddNodeNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(didRemoveNodeFromFavorites:)
                                                 name:kFavouritesDidRemoveNodeNotification
                                               object:nil];
}

- (void)reloadDataSource
{
    [self.dataSourceCollection removeAllObjects];
    [self retrieveNextItems:self.defaultListingContext];
}

#pragma mark - Public Methods

- (void)retrieveNextItems:(AlfrescoListingContext *)moreListingContext
{
    __weak typeof(self) weakSelf = self;
    
    [[FavouriteManager sharedManager] topLevelFavoriteNodesWithSession:self.session filter:self.filter listingContext:moreListingContext completionBlock:^(AlfrescoPagingResult *pagingResult, NSError *error) {
        if(pagingResult)
        {
            if (self.dataSourceCollection == nil)
            {
                self.dataSourceCollection = [NSMutableArray array];
            }
            [self.dataSourceCollection addObjectsFromArray:pagingResult.objects];
            
            self.moreItemsAvailable = pagingResult.hasMoreItems;
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            [weakSelf.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.favorites.failed", @"Favorites failed")];
        }
    }];
}

#pragma mark - Private Methods

- (void)updateFavoriteStatusIconForNodeCell:(FileFolderCollectionViewCell *)nodeCell node:(AlfrescoNode *)node
{
    BOOL isSyncOn = [node isNodeInSyncList];
    BOOL isTopLevelNode = [node isTopLevelSyncNode];

    [nodeCell updateStatusIconsIsFavoriteNode:YES isSyncNode:isSyncOn isTopLevelSyncNode:isTopLevelNode animate:NO];
}

#pragma mark - Notifications Handlers

- (void)didAddNodeToFavorites:(NSNotification *)notification
{
    [self reloadDataSource];
}

- (void)didRemoveNodeFromFavorites:(NSNotification *)notification
{
    AlfrescoNode *node = (AlfrescoNode *)notification.object;
    
    if (node)
    {
        [self.dataSourceCollection removeObject:node];
        [self reloadDataSource];
    }
}

@end
