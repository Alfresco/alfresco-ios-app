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
 
#import "NodePickerSitesViewController.h"
#import "NodePickerFileFolderListViewController.h"
#import "UISearchBar+Paste.h"

static NSString * const kSitesFolderLocation = @"/Sites";
static NSString * const kFolderSearchCMISQuery = @"SELECT * FROM cmis:folder WHERE CONTAINS ('cmis:name:%@') AND IN_TREE('%@')";

@interface NodePickerSitesViewController ()

@property (nonatomic, weak) NodePicker *nodePicker;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentService;
@property (nonatomic, strong) AlfrescoSearchService *searchService;

@end

@implementation NodePickerSitesViewController

- (instancetype)initWithSession:(id<AlfrescoSession>)session nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithSession:session];
    if (self)
    {
        _nodePicker = nodePicker;
        [self createAlfrescoServicesWithSession:session];
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupTableView];
    [self setupCancelButton];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(deselectAllSelectedNodes:)
                                                 name:kAlfrescoPickerDeselectAllNotification
                                               object:nil];
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

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Functions

- (void) setupTableView
{
    [self.tableView setEditing:YES];
    [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    
    UIEdgeInsets edgeInset = UIEdgeInsetsMake(0.0, 0.0, kPickerMultiSelectToolBarHeight, 0.0);
    self.tableView.contentInset = edgeInset;
}

- (void)setupCancelButton
{
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self.nodePicker
                                                                                  action:@selector(cancel)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void)createAlfrescoServicesWithSession:(id<AlfrescoSession>)session
{
    self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
    self.documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    self.searchService = [[AlfrescoSearchService alloc] initWithSession:session];
}

#pragma mark - Notification Methods

- (void)deselectAllSelectedNodes:(id)sender
{
    [self.tableView reloadData];
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
    
    if (self.isDisplayingSearch)
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
    if (self.isDisplayingSearch)
    {
        AlfrescoNode *selectedNode = self.searchResults[indexPath.row];
        [self.nodePicker selectNode:selectedNode];
        
        if (self.nodePicker.mode == NodePickerModeSingleSelect)
        {
            [self.nodePicker pickingNodesComplete];
        }
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
    if (self.isDisplayingSearch)
    {
        AlfrescoNode *selectedNode = self.searchResults[indexPath.row];
        [self.nodePicker deselectNode:selectedNode];
    }
}

#pragma mark - UISearchBarDelegate Functions

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    if (self.nodePicker.type == NodePickerTypeFolders)
    {
        [self showSearchProgressHUD];
        [self.documentService retrieveNodeWithFolderPath:kSitesFolderLocation completionBlock:^(AlfrescoNode *node, NSError *error) {
            [self hideSearchProgressHUD];
            if (node)
            {
                [self showSearchProgressHUD];
                NSString *searchQuery = [NSString stringWithFormat:kFolderSearchCMISQuery, searchBar.text, node.identifier];
                [self.searchService searchWithStatement:searchQuery language:AlfrescoSearchLanguageCMIS completionBlock:^(NSArray *array, NSError *error) {
                    [self hideSearchProgressHUD];
                    if (array)
                    {
                        self.searchResults = array;
                        [self.tableView reloadData];
                    }
                    else
                    {
                        // display error
                        displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.search.failed", @"Site Search failed"), [ErrorDescriptions descriptionForError:error]]);
                        [Notifier notifyWithAlfrescoError:error];
                    }
                }];
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.sites.folder.failed", @"Sites Folder Error"), [ErrorDescriptions descriptionForError:error]]);
                [Notifier notifyWithAlfrescoError:error];
            }
        }];
    }
    else
    {
        [super searchBarSearchButtonClicked:searchBar];
    }
}

- (BOOL)searchBar:(UISearchBar *)searchBar shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    [searchBar enableReturnKeyForPastedText:text range:range];
    
    return YES;
}

@end
