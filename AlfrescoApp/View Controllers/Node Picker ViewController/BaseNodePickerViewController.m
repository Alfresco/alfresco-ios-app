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

#import "BaseNodePickerViewController.h"
#import "NodePickerFileFolderListViewController.h"

static CGFloat const kCellHeight = 64.0f;

@interface BaseNodePickerViewController ()

@end


@implementation BaseNodePickerViewController

#pragma mark - View Life Cycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupCancelButton];
    [self setupTableView];
}

#pragma mark - Setup

- (void)setupCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self.nodePicker
                                                                                  action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)setupTableView
{
    if (self.nodePicker.mode == NodePickerModeMultiSelect)
    {
        [self.tableView setEditing:YES];
        [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    }
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kPickerMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
    
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UINib *nib = [UINib nibWithNibName:NSStringFromClass([AlfrescoNodeCell class]) bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:[AlfrescoNodeCell cellIdentifier]];
}

#pragma mark - UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return (self.isDisplayingSearch) ? self.searchResults.count : self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.isDisplayingSearch ? self.searchResults[indexPath.row] : self.tableViewData[indexPath.row];
    return [self.nodePicker isSelectionEnabledForNode:selectedNode];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.isDisplayingSearch ? self.searchResults[indexPath.row] : self.tableViewData[indexPath.row];

    if (selectedNode.isFolder)
    {
        NodePickerFileFolderListViewController *viewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode
                                                                                                              folderDisplayName:selectedNode.title
                                                                                                                        session:self.session
                                                                                                           nodePickerController:self.nodePicker];

        [self.navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        if (self.nodePicker.type == NodePickerTypeDocuments && self.nodePicker.mode == NodePickerModeSingleSelect)
        {
            [self.nodePicker deselectAllNodes];
            [self.nodePicker selectNode:selectedNode];
            [self.nodePicker pickingNodesComplete];
        }
        else
        {
            [self.nodePicker selectNode:selectedNode];
        }
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.isDisplayingSearch ? self.searchResults[indexPath.row] : self.tableViewData[indexPath.row];
    
    [self.nodePicker deselectNode:selectedNode];
    [self.tableView reloadData];
}

- (void)tableView:(UITableView *)tableView didEndDisplayingCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *nodeCell = (AlfrescoNodeCell *)cell;
    [nodeCell removeNotifications];
}

@end
