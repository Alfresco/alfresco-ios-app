//
//  NodePickerFavoritesViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 12/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NodePickerFavoritesViewController.h"
#import "SyncManager.h"
#import "FavouriteManager.h"
#import "NodePickerFileFolderListViewController.h"
#import "AlfrescoNodeCell.h"
#import "Utility.h"
#import "ThumbnailDownloader.h"

static CGFloat const kCellHeight = 64.0f;

@interface NodePickerFavoritesViewController ()

@property (nonatomic) AlfrescoNode *parentNode;
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, weak) NodePicker *nodePicker;

@end

@implementation NodePickerFavoritesViewController

- (instancetype)initWithParentNode:(AlfrescoNode *)node
                           session:(id<AlfrescoSession>)session
              nodePickerController:(NodePicker *)nodePicker
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:session];
    if (self)
    {
        _parentNode = node;
        _nodePicker = nodePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
    [self loadSyncNodesForFolder:self.parentNode];
    [self disablePullToRefresh];
    
    self.title = self.parentNode ? self.parentNode.name : NSLocalizedString(@"Favorites", @"Favorites Title");
    
    UINib *nib = [UINib nibWithNibName:@"AlfrescoNodeCell" bundle:nil];
    [self.tableView registerNib:nib forCellReuseIdentifier:kAlfrescoNodeCellIdentifier];
    
    if (self.nodePicker.nodePickerMode == NodePickerModeMultiSelect)
    {
        [self.tableView setEditing:YES];
        [self.tableView setAllowsMultipleSelectionDuringEditing:YES];
    }
    
    if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
    {
        if (self.parentNode)
        {
            [self.nodePicker replaceSelectedNodesWithNodes:@[self.parentNode]];
        }
    }
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self.nodePicker updateMultiSelectToolBarActions];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    [self.tableView reloadData];
}

- (void)cancelButtonPressed:(id)sender
{
    [self.nodePicker cancelNodePicker];
}

#pragma mark - Private Methods

- (void)loadSyncNodesForFolder:(AlfrescoNode *)folder
{
    if (folder)
    {
        self.tableViewData = [[SyncManager sharedManager] topLevelSyncNodesOrNodesInFolder:(AlfrescoFolder *)self.parentNode];
    }
    else
    {
        self.tableViewData = [[SyncManager sharedManager] syncDocumentsAndFoldersForSession:self.session withCompletionBlock:^(NSMutableArray *syncedNodes) {
            if (syncedNodes)
            {
                if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
                {
                    self.tableViewData = [self foldersInNodes:syncedNodes];
                }
                else
                {
                    self.tableViewData = syncedNodes;
                }
                [self.tableView reloadData];
            }
        }];
    }
    
    if (self.nodePicker.nodePickerType == NodePickerTypeFolders)
    {
        self.tableViewData = [self foldersInNodes:self.tableViewData];
    }
    [self.tableView reloadData];
}

- (NSMutableArray *)foldersInNodes:(NSArray *)nodes
{
    NSPredicate *folderPredicate = [NSPredicate predicateWithFormat:@"SELF.isFolder == YES"];
    NSMutableArray *folders = [[nodes filteredArrayUsingPredicate:folderPredicate] mutableCopy];
    return folders;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [self.nodePicker isSelectionEnabledForNode:self.tableViewData[indexPath.row]];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNodeCell *nodeCell = [tableView dequeueReusableCellWithIdentifier:kAlfrescoNodeCellIdentifier];
    
    SyncManager *syncManager = [SyncManager sharedManager];
    FavouriteManager *favoriteManager = [FavouriteManager sharedManager];
    
    AlfrescoNode *node = self.tableViewData[indexPath.row];
    SyncNodeStatus *nodeStatus = [syncManager syncStatusForNodeWithId:node.identifier];
    
    [nodeCell updateCellInfoWithNode:node nodeStatus:nodeStatus registerForNotifications:NO];
    BOOL isSyncOn = [syncManager isNodeInSyncList:node];
    
    [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:NO animate:NO];
    [favoriteManager isNodeFavorite:node session:self.session completionBlock:^(BOOL isFavorite, NSError *error) {
        
        [nodeCell updateStatusIconsIsSyncNode:isSyncOn isFavoriteNode:isFavorite animate:NO];
    }];
    
    if (node.isFolder)
    {
        nodeCell.image.image = smallImageForType(@"folder");
        nodeCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    else if (node.isDocument)
    {
        nodeCell.accessoryType = UITableViewCellAccessoryNone;
        
        AlfrescoDocument *document = (AlfrescoDocument *)node;
        ThumbnailDownloader *thumbnailManager = [ThumbnailDownloader sharedManager];
        UIImage *thumbnail = [thumbnailManager thumbnailForDocument:document renditionType:kRenditionImageDocLib];
        
        if (thumbnail)
        {
            [nodeCell.image setImage:thumbnail withFade:NO];
        }
        else
        {
            UIImage *placeholderImage = smallImageForType([document.name pathExtension]);
            nodeCell.image.image = placeholderImage;
            [thumbnailManager retrieveImageForDocument:document renditionType:kRenditionImageDocLib session:self.session completionBlock:^(UIImage *image, NSError *error) {
                if (image)
                {
                    [nodeCell.image setImage:image withFade:YES];
                }
            }];
        }
    }
    
    if ([self.nodePicker isNodeSelected:node])
    {
        [tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
    }
    
    return nodeCell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AlfrescoNode *selectedNode = self.tableViewData[indexPath.row];
    
    if (selectedNode.isFolder)
    {
        BOOL isSyncOn = [[SyncManager sharedManager] isSyncEnabled];
        UIViewController *viewController = nil;
        
        if (isSyncOn)
        {
            viewController = [[NodePickerFavoritesViewController alloc] initWithParentNode:selectedNode session:self.session nodePickerController:self.nodePicker];
            
        }
        else
        {
            viewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:(AlfrescoFolder *)selectedNode
                                                                          folderDisplayName:selectedNode.title
                                                                                    session:self.session
                                                                       nodePickerController:self.nodePicker];
        }
        [self.navigationController pushViewController:viewController animated:YES];
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
    AlfrescoNode *selectedNode = selectedNode = self.tableViewData[indexPath.row];
    
    [self.nodePicker deselectNode:selectedNode];
    [self.tableView reloadData];
}

@end
