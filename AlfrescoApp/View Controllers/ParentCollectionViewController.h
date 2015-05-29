/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
#import "MBProgressHUD.h"
#import "ErrorDescriptions.h"

@class AlfrescoFolder;
@class AlfrescoPagingResult;
@protocol AlfrescoSession;
@class ALFCollectionView;

@interface ParentCollectionViewController : UIViewController <UICollectionViewDataSource, UICollectionViewDelegate>

@property (weak, nonatomic) IBOutlet ALFCollectionView *collectionView;

@property (nonatomic, strong) NSMutableArray *collectionViewData;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;
@property (nonatomic, assign) BOOL moreItemsAvailable;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) MBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL allowsPullToRefresh;

- (id)initWithSession:(id<AlfrescoSession>)session;
- (id)initWithNibName:(NSString *)nibName andSession:(id<AlfrescoSession>)session;
- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)reloadCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addMoreToCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)addMoreToCollectionViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addAlfrescoNodes:(NSArray *)alfrescoNodes completion:(void (^)(BOOL finished))completion;
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

@end
