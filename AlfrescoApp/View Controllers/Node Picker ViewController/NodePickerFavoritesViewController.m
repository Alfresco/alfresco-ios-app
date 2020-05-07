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
 
#import "NodePickerFavoritesViewController.h"
#import "RealmSyncManager.h"
#import "NodePickerFileFolderListViewController.h"
#import "AlfrescoNodeCell.h"

@interface NodePickerFavoritesViewController ()

@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;

@end

@implementation NodePickerFavoritesViewController

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
    
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    [self loadFavoritesNodesForFolder:self.parentNode];
    self.allowsPullToRefresh = NO;
    
    self.title = [self listTitle];
    
    [self updateSelectFolderButton];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.nodePicker updateMultiSelectToolBarActions];
    
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        [self.nodePicker deselectAllNodes];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)updateSelectFolderButton
{
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        if (self.parentNode)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.parentNode]];
        }
    }
}

#pragma mark - Private Methods

- (void)loadFavoritesNodesForFolder:(AlfrescoNode *)folder
{
    [self showHUD];
    [self.documentFolderService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
        [self hideHUD];
        if (self.nodePicker.type == NodePickerTypeFolders)
        {
            self.tableViewData = [self foldersInNodes:array];
        }
        else
        {
            self.tableViewData = [array mutableCopy];
        }
        
        BOOL isMultiSelectMode = (self.nodePicker.mode == NodePickerModeMultiSelect) && (self.tableViewData.count > 0);
        self.tableView.editing = isMultiSelectMode;
        self.tableView.allowsMultipleSelectionDuringEditing = isMultiSelectMode;
        [self.tableView reloadData];
    }];
}

- (NSMutableArray *)foldersInNodes:(NSArray *)nodes
{
    NSPredicate *folderPredicate = [NSPredicate predicateWithFormat:@"SELF.isFolder == YES"];
    NSMutableArray *folders = [[nodes filteredArrayUsingPredicate:folderPredicate] mutableCopy];
    return folders;
}

- (NSString *)listTitle
{
    self.tableView.emptyMessage = NSLocalizedString(@"favourites.empty", @"No Favorites");
    NSString *title = self.parentNode ? self.parentNode.name : NSLocalizedString(@"favourites.title", @"Favorites Title");
    return title;
}

#pragma mark - Table view data source

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
