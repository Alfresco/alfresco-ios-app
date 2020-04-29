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

#import "NodePickerSyncedContentViewController.h"
#import "NodePickerFileFolderListViewController.h"
#import "SyncCollectionViewDataSource.h"
#import "RepositoryCollectionViewDataSource+Internal.h"

@interface NodePickerSyncedContentViewController () <RepositoryCollectionViewDataSourceDelegate>

@property (nonatomic, strong) RepositoryCollectionViewDataSource *dataSource;

@end

@implementation NodePickerSyncedContentViewController

- (instancetype)initWithParentNode:(AlfrescoFolder *)node
                           session:(id<AlfrescoSession>)session
              nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    
    if (self)
    {
        self.parentNode = node;
        self.nodePicker = nodePicker;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allowsPullToRefresh = NO;
    [self loadSyncNodesForFolder:self.parentNode];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.nodePicker updateMultiSelectToolBarActions];
    [self updateSelectFolderButton];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

#pragma mark -

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    self.dataSource = [[SyncCollectionViewDataSource alloc] initWithParentNode:self.parentNode session:self.session delegate:self];
    self.tableViewData = self.dataSource.dataSourceCollection;
    self.title = self.dataSource.screenTitle;
}

- (void)reloadTableView
{
    self.tableViewData = self.dataSource.dataSourceCollection;
    [self.tableView reloadData];
}

- (void)updateSelectFolderButton
{
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        if (self.displayFolder)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.displayFolder]];
        }
    }
}

#pragma mark - RepositoryCollectionViewDataSourceDelegate

- (void)dataSourceUpdated
{
    [self reloadTableView];
}

#pragma mark - UITableViewDataSource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *nodeCell = (AlfrescoNodeCell *)[super tableView:tableView cellForRowAtIndexPath:indexPath];
    
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    [nodeCell setupCellWithNode:node session:self.session hideAccessoryView:YES];

    if ([self.nodePicker isNodeSelected:node])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return nodeCell;
}

@end
