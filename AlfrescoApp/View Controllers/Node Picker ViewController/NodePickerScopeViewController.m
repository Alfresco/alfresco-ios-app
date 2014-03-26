//
//  NodePickerScopeViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 11/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NodePickerScopeViewController.h"
#import "AppConfigurationManager.h"
#import "MainMenuItem.h"
#import "NodePickerFileFolderListViewController.h"
#import "NodePickerSitesViewController.h"
#import "NodePickerFavoritesViewController.h"
#import "SyncViewController.h"
#import "SyncManager.h"
#import "NodePickerScopeCell.h"
#import "UIColor+Custom.h"

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
    
    self.title = NSLocalizedString(@"nodes.picker.scope.title", @"Node Picker Scope");
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
            MainMenuItem *companyHomeMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeRepository
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
            MainMenuItem *sitesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSites
                                                                             imageName:@"mainmenu-sites.png"
                                                                     localizedTitleKey:@"sites.title"
                                                                        viewController:sitesListViewController
                                                                       displayInDetail:NO];
            [self.tableViewData addObject:sitesMenuItem];
        }
        
        BOOL showFavorites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationFavoritesKey];
        if (showFavorites)
        {
            BOOL isSyncEnabled = [[SyncManager sharedManager] isSyncEnabled];
            NodePickerFavoritesViewController *syncViewController = [[NodePickerFavoritesViewController alloc] initWithParentNode:nil session:self.session nodePickerController:self.nodePicker];
            MainMenuItem *favoritesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSync
                                                                                 imageName:isSyncEnabled ? @"mainmenu-sync.png" : @"mainmenu-favourites.png"
                                                                         localizedTitleKey:isSyncEnabled ? @"sync.title" : @"favourites.title"
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
            MainMenuItem *sharedFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSharedFiles
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
            MainMenuItem *myFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeMyFiles
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NodePickerScopeCell *cell = [self.tableView dequeueReusableCellWithIdentifier:kNodePickerScopeCellIdentifier];
    
    MainMenuItem *currentItem = self.tableViewData[indexPath.row];
    cell.label.text = [NSLocalizedString(currentItem.localizedTitleKey, @"Localised Cell Title") uppercaseString];
    cell.imageView.tintColor = [UIColor appTintColor];
    cell.imageView.image = [[UIImage imageNamed:currentItem.imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    
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
