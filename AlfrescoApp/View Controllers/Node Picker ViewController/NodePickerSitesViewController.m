//
//  NodePickerSitesControllerViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NodePickerSitesViewController.h"
#import "NodePickerFileFolderListViewController.h"

@interface NodePickerSitesViewController ()

@property (nonatomic, weak) NodePicker *nodePicker;

@end

@implementation NodePickerSitesViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithSession:session];
    if (self)
    {
        _nodePicker = nodePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
    
    [self.searchController.searchResultsTableView setEditing:YES];
    [self.searchController.searchResultsTableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kPickerMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
    self.searchController.searchResultsTableView.contentInset = edgeInset;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
}

- (void)cancelButtonPressed:(id)sender
{
    [self.nodePicker cancel];
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.nodePicker updateMultiSelectToolBarActions];
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        [self.nodePicker deselectAllNodes];
    }
}

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.searchController.searchResultsTableView reloadData];
}

#pragma mark - TableView Delegate and Datasource

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [super tableView:tableView cellForRowAtIndexPath:indexPath];
    cell.accessoryView = nil;
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    if ([cell isKindOfClass:[SitesCell class]])
    {
        ((SitesCell *)cell).expandButton.hidden = YES;
    }
    
    if (tableView == self.searchController.searchResultsTableView)
    {
        AlfrescoNode *selectedNode = self.searchResults[indexPath.row];
        if ([self.nodePicker isNodeSelected:selectedNode])
        {
            [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchController.searchResultsTableView)
    {
        AlfrescoNode *selectedNode = self.searchResults[indexPath.row];
        [self.nodePicker selectNode:selectedNode];
    }
    else
    {
        AlfrescoSite *selectedSite = [self.tableViewData objectAtIndex:indexPath.row];
        
        [self showHUD];
        [self.siteService retrieveDocumentLibraryFolderForSite:selectedSite.shortName completionBlock:^(AlfrescoFolder *folder, NSError *error) {
            [self hideHUD];
            if (folder)
            {
                NodePickerFileFolderListViewController *browserListViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:folder folderDisplayName:selectedSite.title session:self.session nodePickerController:self.nodePicker];
                [self.navigationController pushViewController:browserListViewController animated:YES];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
            else
            {
                // show error
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.documentlibrary.failed", @"Doc Library Retrieval"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
                [tableView deselectRowAtIndexPath:indexPath animated:YES];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (tableView == self.searchController.searchResultsTableView)
    {
        AlfrescoNode *selectedNode = self.searchResults[indexPath.row];
        [self.nodePicker deselectNode:selectedNode];
    }
}

@end
