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
  
#import "ErrorDescriptions.h"
#import "ALFTableView.h"
#import "MBProgressHUD.h"

@class AlfrescoFolder;
@class AlfrescoPagingResult;
@protocol AlfrescoSession;

/**
 * ParentListViewController
 */
@interface ParentListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet ALFTableView *tableView;
@property (nonatomic, strong) NSMutableArray *tableViewData;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;
@property (nonatomic, assign) BOOL moreItemsAvailable;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) UIRefreshControl *refreshControl;
@property (nonatomic, strong, readonly) MBProgressHUD *progressHUD;
@property (nonatomic, assign) BOOL allowsPullToRefresh;
@property (nonatomic, assign) BOOL isDisplayingSearch;

- (id)initWithSession:(id<AlfrescoSession>)session;
- (id)initWithNibName:(NSString *)nibName andSession:(id<AlfrescoSession>)session;
- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addAlfrescoNodes:(NSArray *)alfrescoNodes withRowAnimation:(UITableViewRowAnimation)rowAnimation;
- (void)showHUD;
- (void)showHUDWithMode:(MBProgressHUDMode)mode;
- (void)hideHUD;
- (void)hidePullToRefreshView;
- (BOOL)shouldRefresh;
- (void)enablePullToRefresh;
- (void)disablePullToRefresh;
- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)tableViewNodeIdentifiers;
- (void)refreshTableView:(UIRefreshControl *)refreshControl;
- (void)showLoadingTextInRefreshControl:(UIRefreshControl *)refreshControl;

@end
