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

@property (nonatomic, strong) AlfrescoAppPicker *nodePicker;

@end

@implementation NodePickerFileFolderListViewController

- (instancetype)initWithFolder:(AlfrescoFolder *)folder
             folderPermissions:(AlfrescoPermissions *)permissions
             folderDisplayName:(NSString *)displayName
                       session:(id<AlfrescoSession>)session
          nodePickerController:(AlfrescoAppPicker *)nodePicker
{
    self = [super initWithFolder:folder folderPermissions:permissions folderDisplayName:displayName session:session];
    if (self)
    {
        _nodePicker = nodePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    [self updateUIUsingFolderPermissionsWithAnimation:YES];
    
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
    self.searchController.searchResultsTableView.contentInset = edgeInset;
    
    [self.searchController.searchResultsTableView setEditing:YES];
    [self.searchController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    
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
    [self.nodePicker cancelPicker];
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
    return [self.nodePicker isSelectionEnabledForItem:self.tableViewData[indexPath.row]];
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
    
    if ([self.nodePicker isItemSelected:selectedNode])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    cell.accessoryType = UITableViewCellAccessoryNone;
    if (self.nodePicker.pickerType == PickerTypeNodesSingleSelection && selectedNode.isFolder && ![self.nodePicker isItemSelected:selectedNode])
    {
        cell.editingAccessoryView = [self createFolderSelectionButton];
    }
    else
    {
        cell.editingAccessoryView = nil;
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
        [tableView deselectRowAtIndexPath:indexPath animated:NO];
        if (self.nodePicker.pickerType == PickerTypeNodesSingleSelection && [self.nodePicker numberOfSelectedItems] > 0)
        {
            
        }
        else
        {
            NodePickerFileFolderListViewController *browserViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode
                                                                                                                         folderPermissions:nil
                                                                                                                         folderDisplayName:selectedNode.title
                                                                                                                                   session:self.session
                                                                                                                      nodePickerController:self.nodePicker];
            [self.navigationController pushViewController:browserViewController animated:YES];
        }
    }
    else
    {
        if (self.nodePicker.pickerType == PickerTypeNodesSingleSelection)
        {
            [tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
        else
        {
            [self.nodePicker selectItem:selectedNode];
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
    
    [self.nodePicker deselectItem:selectedNode];
    [self.tableView reloadData];
}

- (UIButton *)createFolderSelectionButton
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kFolderSelectionButtonWidth, kFolderSelectionButtongHeight)];
    [button addTarget:self action:@selector(selectFolderButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [button setBackgroundImage:[UIImage imageNamed:@"unselected_circle"] forState:UIControlStateNormal];
    return button;
}

- (void)selectFolderButtonClicked:(UIButton *)sender
{
    UITableViewCell *selectedCell = (UITableViewCell *)sender.superview;
    
    BOOL foundNodeCell = NO;
    while (!foundNodeCell)
    {
        if (![selectedCell isKindOfClass:[UITableViewCell class]])
        {
            selectedCell = (UITableViewCell *)selectedCell.superview;
        }
        else
        {
            foundNodeCell = YES;
        }
    }
    NSIndexPath *indexPathForSelectedCell = [self.tableView indexPathForCell:selectedCell];
    
    AlfrescoNode *selectedNode = self.tableViewData[indexPathForSelectedCell.row];
    [self.nodePicker deselectAllItems];
    [self.nodePicker selectItem:selectedNode];
    [self.tableView reloadData];
}

#pragma mark - Searchbar Delegate

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [self.tableView reloadData];
}

@end
