/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "NodePickerScopeViewController.h"
#import "AppConfigurationManager.h"
#import "MainMenuItem.h"
#import "NodePickerFileFolderListViewController.h"
#import "NodePickerSitesViewController.h"
#import "NodePickerFavoritesViewController.h"
#import "SyncViewController.h"
#import "SyncManager.h"
#import "NodePickerScopeCell.h"


static CGFloat const kCellHeight = 64.0f;

NSString * const kNodePickerScopeCellIdentifier = @"NodePickerScopeCellIdentifier";

@interface NodePickerScopeViewController ()

@property (nonatomic, strong) NSMutableArray *tableViewData;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, weak) NodePicker *nodePicker;

@end

@implementation NodePickerScopeViewController

- (id)initWithSession:(id<AlfrescoSession>)session nodePickerController:(NodePicker *)nodePicker;
{
    self = [super initWithStyle:UITableViewStyleGrouped];
    if (self)
    {
        _session = session;
        _nodePicker = nodePicker;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"nodes.picker.list.title", @"Attachments");
    [self configureScopeView];
    
    UINib *cellNib = [UINib nibWithNibName:@"NodePickerScopeCell" bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:kNodePickerScopeCellIdentifier];
    
    UIBarButtonItem *cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                  target:self
                                                                                  action:@selector(cancelButtonPressed:)];
    self.navigationItem.rightBarButtonItem = cancelButton;
}

- (void) viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self.nodePicker hideMultiSelectToolBar];
    self.navigationItem.hidesBackButton = YES;
}

- (void)cancelButtonPressed:(id)sender
{
    [self.nodePicker cancel];
}

- (void)configureScopeView
{
    self.tableViewData = [NSMutableArray array];
    
    AppConfigurationManager *configurationManager = [AppConfigurationManager sharedManager];
    
    if (configurationManager.showRepositorySpecificItems)
    {
        BOOL showRepository = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationRepositoryKey];
        if (showRepository)
        {
            NodePickerFileFolderListViewController *companyHomeViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:nil folderDisplayName:@"companyHome.title" session:self.session nodePickerController:self.nodePicker];
            MainMenuItem *companyHomeMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeRepository
                                                                                   imageName:@"mainmenu-repository.png"
                                                                           localizedTitleKey:@"companyHome.title"
                                                                              viewController:companyHomeViewController
                                                                             displayInDetail:NO];
            [self.tableViewData addObject:companyHomeMenuItem];
        }
        
        BOOL showSites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSitesKey];
        if (showSites)
        {
            NodePickerSitesViewController *sitesListViewController = [[NodePickerSitesViewController alloc] initWithSession:self.session nodePickerController:self.nodePicker];
            MainMenuItem *sitesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSites
                                                                             imageName:@"mainmenu-sites.png"
                                                                     localizedTitleKey:@"sites.title"
                                                                        viewController:sitesListViewController
                                                                       displayInDetail:NO];
            [self.tableViewData addObject:sitesMenuItem];
        }
        
        BOOL showFavorites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationFavoritesKey];
        if (showFavorites)
        {
            BOOL isSyncOn = [[SyncManager sharedManager] isSyncPreferenceOn];
            NodePickerFavoritesViewController *syncViewController = [[NodePickerFavoritesViewController alloc] initWithParentNode:nil session:self.session nodePickerController:self.nodePicker];
            MainMenuItem *favoritesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSync
                                                                                 imageName:isSyncOn ? @"mainmenu-sync.png" : @"mainmenu-favourites.png"
                                                                         localizedTitleKey:isSyncOn ? @"sync.title" : @"favourites.title"
                                                                            viewController:syncViewController
                                                                           displayInDetail:NO];
            [self.tableViewData addObject:favoritesMenuItem];
        }
        
        BOOL showSharedFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSharedFilesKey];
        if (showSharedFiles)
        {
            NodePickerFileFolderListViewController *sharedFilesViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:configurationManager.sharedFiles
                                                                                                                             folderDisplayName:NSLocalizedString(@"sharedFiles.title", @"Shared Files")
                                                                                                                                       session:self.session
                                                                                                                          nodePickerController:self.nodePicker];
            MainMenuItem *sharedFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSharedFiles
                                                                                   imageName:@"mainmenu-sharedfiles.png"
                                                                           localizedTitleKey:@"sharedFiles.title"
                                                                              viewController:sharedFilesViewController
                                                                             displayInDetail:NO];
            [self.tableViewData addObject:sharedFilesMenuItem];
        }
        
        BOOL showMyFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationMyFilesKey];
        if (showMyFiles)
        {
            NodePickerFileFolderListViewController *myFilesViewController = [[NodePickerFileFolderListViewController alloc] initWithFolder:configurationManager.myFiles
                                                                                                                         folderDisplayName:NSLocalizedString(@"myFiles.title", @"My Files")
                                                                                                                                   session:self.session
                                                                                                                      nodePickerController:self.nodePicker];
            MainMenuItem *myFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeMyFiles
                                                                               imageName:@"mainmenu-myfiles.png"
                                                                       localizedTitleKey:@"myFiles.title"
                                                                          viewController:myFilesViewController
                                                                         displayInDetail:NO];
            [self.tableViewData addObject:myFilesMenuItem];
        }
    }
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kCellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NodePickerScopeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kNodePickerScopeCellIdentifier];
    
    MainMenuItem *currentItem = self.tableViewData[indexPath.row];
    cell.label.text = NSLocalizedString(currentItem.localizedTitleKey, @"Localised Cell Title");
    cell.thumbnail.tintColor = [UIColor appTintColor];
    [cell.thumbnail setImage:[[UIImage imageNamed:currentItem.imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] withFade:NO];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuItem *selectedMenuItem = self.tableViewData[indexPath.row];
    UIViewController *viewController = selectedMenuItem.viewController;
    
    if (viewController)
    {
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

@end
