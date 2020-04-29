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

#import <UIKit/UIKit.h>
#import "ErrorDescriptions.h"
#import "MultiSelectContainerView.h"
#import "BaseLayoutAttributes.h"
#import "BaseCollectionViewFlowLayout.h"
#import "CollectionViewProtocols.h"
#import "RepositoryCollectionViewDataSource.h"

@class AlfrescoFolder;
@class AlfrescoPagingResult;
@protocol AlfrescoSession;

typedef NS_ENUM(NSUInteger, CollectionViewStyle)
{
    CollectionViewStyleList,
    CollectionViewStyleGrid
};

@interface ParentCollectionViewController : UIViewController < UICollectionViewDelegateFlowLayout, UIGestureRecognizerDelegate, CollectionViewCellAccessoryViewDelegate, DataSourceInformationProtocol, UIPopoverPresentationControllerDelegate, CollectionViewMultiSelectDelegate >

// IBOutlets
@property (nonatomic, weak) IBOutlet MultiSelectContainerView *multiSelectContainerView;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *multiSelectContainerViewHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *multiSelectContainerViewBottomConstraint;
@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;

@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) MBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL allowsPullToRefresh;
@property (nonatomic, assign) BOOL allowsSwipeToDelete;
@property (nonatomic, strong) NSString *emptyMessage;
@property (nonatomic, assign) BOOL isOnSearchResults;
@property (nonatomic, assign) CollectionViewStyle style;
@property (nonatomic, strong) BaseCollectionViewFlowLayout *listLayout;
@property (nonatomic, strong) BaseCollectionViewFlowLayout *gridLayout;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewTopConstraint;
@property (nonatomic) BOOL shouldIncludeSearchBar;

@property (nonatomic, strong) RepositoryCollectionViewDataSource *dataSource;
@property (nonatomic, strong) RepositoryCollectionViewDataSource *searchDataSource;
@property (nonatomic, strong) UIAlertController *actionsAlertController;

- (instancetype)initWithSession:(id<AlfrescoSession>)session;
- (instancetype)initWithSession:(id<AlfrescoSession>)session style:(CollectionViewStyle)style;

- (void)setupWithSession:(id<AlfrescoSession>)session;

- (void)reloadCollectionView;
- (void)showHUD;
- (void)showHUDWithMode:(MBProgressHUDMode)mode;
- (void)hideHUD;
- (void)hidePullToRefreshView;
- (BOOL)shouldRefresh;
- (void)enablePullToRefresh;
- (void)disablePullToRefresh;
- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)collectionViewNodeIdentifiers;
- (void)refreshCollectionView:(UIRefreshControl *)refreshControl;
- (void)showLoadingTextInRefreshControl:(UIRefreshControl *)refreshControl;
- (void)connectivityChanged:(NSNotification *)notification;

- (void)changeCollectionViewStyle:(CollectionViewStyle)style animated:(BOOL)animated;
- (BaseCollectionViewFlowLayout *)layoutForStyle:(CollectionViewStyle)style;

- (void)updateEmptyView;
- (RepositoryCollectionViewDataSource *)inUseDataSource;
@end
