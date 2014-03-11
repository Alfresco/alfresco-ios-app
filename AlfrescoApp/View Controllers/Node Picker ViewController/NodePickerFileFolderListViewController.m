//
//  NodePickerFileFolderListViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 26/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

static NSInteger const kFolderSelectionButtonWidth = 32;
static NSInteger const kFolderSelectionButtongHeight = 32;

#import "NodePickerFileFolderListViewController.h"

@interface NodePickerFileFolderListViewController ()

@property (nonatomic, strong) NodePicker *nodePicker;
@property (nonatomic, strong) AlfrescoFolder *displayFolder;

@end

@implementation NodePickerFileFolderListViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder
             folderPermissions:(AlfrescoPermissions *)permissions
             folderDisplayName:(NSString *)displayName
                       session:(id<AlfrescoSession>)session
          nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithFolder:folder folderPermissions:permissions folderDisplayName:displayName session:session];
    if (self)
    {
        _nodePicker = nodePicker;
        _displayFolder = folder;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self updateUIUsingFolderPermissionsWithAnimation:YES];
    
    if (self.nodePicker.nodePickerMode == NodePickerModeMultiSelect)
    {
        [self.tableView setEditing:YES];
        [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    }
    
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
    self.searchController.searchResultsTableView.contentInset = edgeInset;
    
    [self.searchController.searchResultsTableView setEditing:YES];
    [self.searchController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    
    if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
    {
        if (self.displayFolder)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.displayFolder]];
        }
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
}

// this is added to overwrite parent implementation
- (void)viewDidAppear:(BOOL)animated
{
    
}

- (void)cancelButtonPressed:(id)sender
{
    [self.nodePicker cancelNodePicker];
}

- (void)updateUIUsingFolderPermissionsWithAnimation:(BOOL)animated
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.nodePicker isSelectionEnabledForNode:self.tableViewData[indexPath.row]];
}

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.tableView reloadData];
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark - TableView Delegates and Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    AlfrescoNode *selectedNode = nil;
    if (tableView == self.searchController.searchResultsTableView)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    if ([self.nodePicker isNodeSelected:selectedNode])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = nil;
    if (tableView == self.searchController.searchResultsTableView)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    if (selectedNode.isFolder)
    {
        NodePickerFileFolderListViewController *browserViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode
                                                                                                                     folderPermissions:nil
                                                                                                                     folderDisplayName:selectedNode.title
                                                                                                                               session:self.session
                                                                                                                  nodePickerController:self.nodePicker];
        [self.navigationController pushViewController:browserViewController animated:YES];
    }
    else
    {
        if (self.nodePicker.nodePickerType == NodePickerTypeDocuments && self.nodePicker.nodePickerMode == NodePickerModeSingleSelect)
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
    AlfrescoNode *selectedNode = nil;
    if (tableView == self.searchController.searchResultsTableView)
    {
        selectedNode = self.searchResults[indexPath.row];
    }
    else
    {
        selectedNode = self.tableViewData[indexPath.row];
    }
    
    [self.nodePicker deselectNode:selectedNode];
    [self.tableView reloadData];
}

#pragma mark - Searchbar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tableView reloadData];
}

@end
