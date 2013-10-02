//
//  SyncViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 30/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncViewController.h"
#import "SyncManager.h"
#import "SyncCell.h"
#import "Utility.h"

static NSInteger const kCellHeight = 84;
static CGFloat const kFooterHeight = 32.0f;
static CGFloat const kCellImageViewWidth = 32.0f;
static CGFloat const kCellImageViewHeight = 32.0f;
static NSString * const kSyncInterface = @"SyncViewController";

@interface SyncViewController ()
@property (nonatomic) AlfrescoNode *parentNode;
@end

@implementation SyncViewController

- (id)initWithParentNode:(AlfrescoNode *)node andSession:(id<AlfrescoSession>)session
{
    self = [super initWithNibName:kSyncInterface andSession:session];
    if (self)
    {
        self.session = session;
        self.parentNode = node;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self loadSyncNodesForFolder:self.parentNode];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - private methods

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    if (folder)
    {
        self.tableViewData = [[SyncManager sharedManager] topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)self.parentNode];
        [self hidePullToRefreshView];
    }
    else
    {
        self.tableViewData = [[[SyncManager sharedManager] syncDocumentsAndFoldersForSession:self.session withCompletionBlock:^(NSArray *syncedNodes) {
            if (syncedNodes)
            {
                self.tableViewData = [syncedNodes mutableCopy];
                [self.tableView reloadData];
                [self hidePullToRefreshView];
            }
        }] mutableCopy];
    }
    [self.tableView reloadData];
}

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
    
    [self loadSyncNodesForFolder:self.parentNode];
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return kFooterHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    //static NSString *cellIdentifier = kSyncTableCellIdentifier;
    SyncCell *syncCell = [tableView dequeueReusableCellWithIdentifier:kSyncTableCellIdentifier];
    if (nil == syncCell)
    {
        syncCell = (SyncCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SyncCell class]) owner:self options:nil] lastObject];
    }
    
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    
    syncCell.nodeId = node.identifier;
    syncCell.filename.text = node.name;
    
    if (node.isFolder)
    {
        syncCell.image.image = imageForType(@"folder");
    }
    else if (node.isDocument)
    {
        syncCell.image.image = imageForType([node.name pathExtension]);
    }
    
    SyncNodeStatus *nodeStatus = [[SyncManager sharedManager] syncStatusForNode:node];
    [syncCell updateCellWithNodeStatus:nodeStatus propertyChanged:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:syncCell
                                             selector:@selector(statusChanged:)
                                                 name:kSyncStatusChangeNotification
                                               object:nil];
    
    return syncCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.tableViewData[indexPath.row];
    
    if (selectedNode.isFolder)
    {
        SyncViewController *controller = [[SyncViewController alloc] initWithParentNode:selectedNode andSession:self.session];
        
        [self.navigationController pushViewController:controller animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    SyncManager *syncManager = [SyncManager sharedManager];
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNode:node];
    
    switch (nodeStatus.status)
    {
        case SyncStatusLoading:
            [syncManager cancelSyncForDocument:(AlfrescoDocument *)node];
            break;
            
        case SyncStatusFailed:
            [syncManager retrySyncForDocument:(AlfrescoDocument *)node];
            break;
            
        default:
            break;
    }
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self loadSyncNodesForFolder:self.parentNode];
}

@end
