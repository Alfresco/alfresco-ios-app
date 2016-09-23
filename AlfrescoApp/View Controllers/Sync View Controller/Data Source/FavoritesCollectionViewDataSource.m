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

#import "FavoritesCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"
#import "FavouriteManager.h"

@implementation FavoritesCollectionViewDataSource

- (instancetype)initWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate
{
    self = [super initWithParentNode:node session:session delegate:delegate];
    if(!self)
    {
        return nil;
    }
    self.shouldAllowMultiselect = NO;
    
    if(!node)
    {
        self.screenTitle = NSLocalizedString(@"favourites.title", @"Favorites Title");
    }
    self.emptyMessage = NSLocalizedString(@"favourites.empty", @"No Favorites");
    
    [self reloadDataSource];
    
    return self;
}

- (void)reloadDataSource
{
    [self reloadDataSourceIgnoringCache:NO];
}

- (void)reloadDataSourceIgnoringCache:(BOOL)ignoreCache
{
    __weak typeof(self) weakSelf = self;
    [[FavouriteManager sharedManager] topLevelFavoriteNodesWithSession:self.session ignoreCache:ignoreCache completionBlock:^(NSArray *array, NSError *error) {
        if(array)
        {
            self.dataSourceCollection = [array mutableCopy];
            [weakSelf.delegate dataSourceUpdated];
        }
        else
        {
            [weakSelf.delegate requestFailedWithError:error stringFormat:NSLocalizedString(@"error.filefolder.favorites.failed", @"Favorites failed")];
        }
    }];
}

@end
