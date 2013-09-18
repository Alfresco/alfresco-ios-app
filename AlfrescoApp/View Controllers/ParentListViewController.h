//
//  ParentListViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MBProgressHUD.h"
#import "ErrorDescriptions.h"

@class AlfrescoFolder;
@class AlfrescoPagingResult;
@protocol AlfrescoSession;

@interface ParentListViewController : UIViewController <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) IBOutlet UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *tableViewData;
@property (nonatomic, strong) AlfrescoListingContext *defaultListingContext;
@property (nonatomic, assign) BOOL moreItemsAvailable;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) UIRefreshControl *refreshControl;

- (id)initWithSession:(id<AlfrescoSession>)session;
- (id)initWithNibName:(NSString *)nibName andSession:(id<AlfrescoSession>)session;
- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)reloadTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult error:(NSError *)error;
- (void)addMoreToTableViewWithPagingResult:(AlfrescoPagingResult *)pagingResult data:(NSMutableArray *)data error:(NSError *)error;
- (void)addAlfrescoNodes:(NSArray *)alfrescoNodes withRowAnimation:(UITableViewRowAnimation)rowAnimation;
- (void)showHUD;
- (void)hideHUD;
- (void)hidePullToRefreshView;
- (BOOL)shouldRefresh;
- (void)enablePullToRefresh;
- (void)disablePullToRefresh;
- (NSIndexPath *)indexPathForNodeWithIdentifier:(NSString *)identifier inNodeIdentifiers:(NSArray *)tableViewNodeIdentifiers;
- (void)refreshTableView:(UIRefreshControl *)refreshControl;
- (void)showLoadingTextInRefreshControl:(UIRefreshControl *)refreshControl;

@end
