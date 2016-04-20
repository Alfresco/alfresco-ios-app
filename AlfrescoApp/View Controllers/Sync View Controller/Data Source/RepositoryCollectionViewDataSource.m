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
#import "ThumbnailManager.h"
#import "FavouriteManager.h"
#import "RealmSyncManager.h"

@implementation RepositoryCollectionViewDataSource

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
    
//    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
//        BOOL isSyncOn = [syncManager isNodeInSyncList:node];
    
    //    [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:NO animate:NO];
//        [favoriteManager isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
//    
//            [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:isFavorite animate:NO];
//        }];
    
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

@end
