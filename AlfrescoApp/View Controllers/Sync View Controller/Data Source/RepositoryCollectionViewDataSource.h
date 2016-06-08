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

#import <Foundation/Foundation.h>
#import "BaseCollectionViewFlowLayout.h"
#import "CollectionViewProtocols.h"

@class RepositoryCollectionViewDataSource;

@protocol RepositoryCollectionViewDataSourceDelegate <NSObject>

- (BaseCollectionViewFlowLayout *)currentSelectedLayout;
- (id<CollectionViewCellAccessoryViewDelegate>)cellAccessoryViewDelegate;

- (void)dataSourceUpdated;
- (void)requestFailedWithError:(NSError *)error stringFormat:(NSString *)stringFormat;

- (void)didDeleteItems:(NSArray *)items atIndexPaths:(NSArray *)indexPathsOfDeletedItems;
- (void)failedToDeleteItems:(NSError *)error;

- (void)didRetrievePermissionsForParentNode;

- (void)selectItemAtIndexPath:(NSIndexPath *)indexPath;

- (void)setNodeDataSource:(RepositoryCollectionViewDataSource *)dataSource;

@end

@interface RepositoryCollectionViewDataSource : NSObject <UICollectionViewDataSource, DataSourceInformationProtocol, SwipeToDeleteDelegate>

@property (nonatomic, weak) id<RepositoryCollectionViewDataSourceDelegate> delegate;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSString *emptyMessage;
@property (nonatomic, strong) NSString *screenTitle;
@property (nonatomic, strong) NSString *errorTitle;
@property (nonatomic, assign) BOOL moreItemsAvailable;

- (instancetype)initWithParentNode:(AlfrescoNode *)node session:(id<AlfrescoSession>)session delegate:(id<RepositoryCollectionViewDataSourceDelegate>)delegate;
- (AlfrescoNode *)alfrescoNodeAtIndex:(NSInteger)index;
- (NSInteger)numberOfNodesInCollection;

@end
