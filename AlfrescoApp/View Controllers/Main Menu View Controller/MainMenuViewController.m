//
//  MainMenuViewController.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "MainMenuViewController.h"
#import "MainMenuItemCell.h"
#import "FileFolderListViewController.h"
#import "SitesListViewController.h"
#import "ActivitiesViewController.h"
#import "TaskViewController.h"
#import "SyncViewController.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "UniversalDevice.h"
#import "DetailSplitViewController.h"
#import "AppConfigurationManager.h"
#import "SettingsViewController.h"
#import "AboutViewController.h"
#import "PreviewViewController.h"
#import "DownloadsViewController.h"
#import "UIColor+Custom.h"

// where the repo items should be displayed in the tableview
static NSUInteger const kRepositoryItemsSectionNumber = 1;
static NSUInteger const kDownloadsRowNumber = 1;

@interface MainMenuViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong, readwrite) NSMutableArray *tableData;
@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, assign, readwrite) BOOL hasRepositorySpecificSection;

@end

@implementation MainMenuViewController

- (instancetype)initWithAccountsSectionItems:(NSArray *)accountSectionItems
{
    self = [super init];
    if (self)
    {
        _tableData = [NSMutableArray array];
        if (accountSectionItems)
        {
            [_tableData addObject:accountSectionItems];
        }
        
        NSMutableArray *defaultMenuItems = [self defaultMenuItems];
        if (defaultMenuItems.count > 0)
        {
            [_tableData addObject:defaultMenuItems];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdated:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appConfigurationUpdated:) name:kAlfrescoAppConfigurationUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountListEmpty:) name:kAlfrescoAccountsListEmptyNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.bounces = NO;
    tableView.backgroundView = nil;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.separatorColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.backgroundColor = [UIColor mainManuBackgroundColor];
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSArray *sectionArray = [self.tableData objectAtIndex:section];
    return sectionArray.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if (!cell)
    {
        cell = [[MainMenuItemCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:CellIdentifier];
    }
    
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *currentItem = [sectionArray objectAtIndex:indexPath.row];
    cell.textLabel.text = NSLocalizedString(currentItem.localizedTitleKey, @"Localised Cell Title") ;
    cell.imageView.image = [UIImage imageNamed:currentItem.imageName];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    cell.backgroundColor = [UIColor clearColor];
    
    return cell;
}

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *selectedMenuItem = [sectionArray objectAtIndex:indexPath.row];
    
    [self informDelegateMenuItemSelected:selectedMenuItem];
    
    // expand the detail view controller for the iPad
    if (IS_IPAD)
    {
        DetailSplitViewController *detailSplitViewController = (DetailSplitViewController *)[UniversalDevice rootDetailViewController];
        [detailSplitViewController expandViewController];
    }
}

#pragma mark - Notification Methods

- (void)sessionUpdated:(NSNotification *)notification
{
    self.alfrescoSession = (id<AlfrescoSession>)notification.object;
}

- (void)appConfigurationUpdated:(NSNotification *)notification
{
    AppConfigurationManager *configurationManager = (AppConfigurationManager *)notification.object;
    [self configureRepositoryMainMenuItems:configurationManager];
    [self configureLocalMainMenuItems:configurationManager];
}

- (void)accountListEmpty:(NSNotification *)notification
{
    MainMenuItem *downloadsMenuItem = [self existingMenuItemWithType:NavigationControllerTypeDownloads];
    
    if (!downloadsMenuItem)
    {
        NSMutableArray *localMenuItems = self.tableData.lastObject;
        DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
        NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
        downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeDownloads
                                                               imageName:@"download-main-menu.png"
                                                       localizedTitleKey:@"Downloads"
                                                          viewController:downloadsNavigationController
                                                         displayInDetail:NO];
        [localMenuItems insertObject:downloadsMenuItem atIndex:kDownloadsRowNumber];
        
        NSInteger localMainMenuItemsSectionIndex = [self.tableData indexOfObject:localMenuItems];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:localMainMenuItemsSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    }
}

#pragma mark - Private Functions

- (void)informDelegateMenuItemSelected:(MainMenuItem *)menuItem
{
    if ([self.delegate respondsToSelector:@selector(didSelectMenuItem:)])
    {
        [self.delegate didSelectMenuItem:menuItem];
    }
}

- (NSMutableArray *)defaultMenuItems
{
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithSession:self.alfrescoSession];
    NavigationViewController *settingsNavigationController = [[NavigationViewController alloc] initWithRootViewController:settingsViewController];
    MainMenuItem *settingsMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSettings
                                                                        imageName:@"settings-main-menu.png"
                                                                localizedTitleKey:@"settings.title"
                                                                   viewController:settingsNavigationController
                                                                  displayInDetail:YES];
    
    AboutViewController *aboutViewController = [[AboutViewController alloc] init];
    NavigationViewController *aboutNavigationController = [[NavigationViewController alloc] initWithRootViewController:aboutViewController];
    MainMenuItem *aboutMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeAbout
                                                                     imageName:@"about-more.png"
                                                             localizedTitleKey:@"about.title"
                                                                viewController:aboutNavigationController
                                                               displayInDetail:YES];
    
    PreviewViewController *helpViewController = [[PreviewViewController alloc] initWithBundleDocument:@"UserGuide.pdf"];
    NavigationViewController *helpNavigationController = [[NavigationViewController alloc] initWithRootViewController:helpViewController];
    MainMenuItem *helpMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeHelp
                                                                    imageName:@"help-more.png"
                                                            localizedTitleKey:@"Help"
                                                               viewController:helpNavigationController
                                                              displayInDetail:YES];
    
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
    NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
    MainMenuItem *downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeDownloads
                                                           imageName:@"download-main-menu.png"
                                                   localizedTitleKey:@"Downloads"
                                                      viewController:downloadsNavigationController
                                                     displayInDetail:NO];
    
    return [@[settingsMenuItem, downloadsMenuItem, aboutMenuItem, helpMenuItem] mutableCopy];
}

- (void)configureLocalMainMenuItems:(AppConfigurationManager *)configurationManager
{
    NSMutableArray *localMenuItems = self.tableData.lastObject;
    BOOL localMenuItemsChanged = NO;
    
    BOOL showLocalFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationLocalFilesKey];
    MainMenuItem *downloadsMenuItem = [self existingMenuItemWithType:NavigationControllerTypeDownloads];
    if (showLocalFiles && !downloadsMenuItem)
    {
        DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
        NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
        downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeDownloads
                                                               imageName:@"download-main-menu.png"
                                                       localizedTitleKey:@"Downloads"
                                                          viewController:downloadsNavigationController
                                                         displayInDetail:NO];
        [localMenuItems insertObject:downloadsMenuItem atIndex:kDownloadsRowNumber];
        localMenuItemsChanged = YES;
    }
    else if (!showLocalFiles && downloadsMenuItem)
    {
        [localMenuItems removeObject:downloadsMenuItem];
        localMenuItemsChanged = YES;
    }
    
    if (localMenuItemsChanged)
    {
        NSInteger localMainMenuItemsSectionIndex = [self.tableData indexOfObject:localMenuItems];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:localMainMenuItemsSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)configureRepositoryMainMenuItems:(AppConfigurationManager *)configurationManager
{
    if (configurationManager.showRepositorySpecificItems)
    {
        NSMutableArray *repositoryMenuItems = self.hasRepositorySpecificSection ? self.tableData[kRepositoryItemsSectionNumber] : [NSMutableArray array];
        BOOL repositoryMenuItemsChanged = NO;
        NSInteger nextIndex = 0;
        
        BOOL showActivities = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationActivitiesKey];
        MainMenuItem *activitiesMenuItem = [self existingMenuItemWithType:NavigationControllerTypeActivities];
        if (showActivities && !activitiesMenuItem)
        {
            ActivitiesViewController *activitiesViewController = [[ActivitiesViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *activitiesNavigationController = [[NavigationViewController alloc] initWithRootViewController:activitiesViewController];
            activitiesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeActivities
                                                                    imageName:@"activities-main-menu.png"
                                                            localizedTitleKey:@"activities.title"
                                                               viewController:activitiesNavigationController
                                                              displayInDetail:NO];
            [repositoryMenuItems insertObject:activitiesMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showActivities && activitiesMenuItem)
        {
            [repositoryMenuItems removeObject:activitiesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        NSInteger itemIndex = [repositoryMenuItems indexOfObject:activitiesMenuItem];  // find index for recent item and setup nextIndex for next item
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showRepository = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationRepositoryKey];
        MainMenuItem *companyHomeMenuItem = [self existingMenuItemWithType:NavigationControllerTypeRepository];
        if (showRepository && !companyHomeMenuItem)
        {
            FileFolderListViewController *companyHomeViewController = [[FileFolderListViewController alloc] initWithFolder:nil session:self.alfrescoSession];
            NavigationViewController *companyHomeNavigationController = [[NavigationViewController alloc] initWithRootViewController:companyHomeViewController];
            companyHomeMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeRepository
                                                                     imageName:@"repository-tabbar.png"
                                                             localizedTitleKey:@"companyHome.title"
                                                                viewController:companyHomeNavigationController
                                                               displayInDetail:NO];
            [repositoryMenuItems insertObject:companyHomeMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showRepository && companyHomeMenuItem)
        {
            [repositoryMenuItems removeObject:companyHomeMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:companyHomeMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showSites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSitesKey];
        MainMenuItem *sitesMenuItem = [self existingMenuItemWithType:NavigationControllerTypeSites];
        if (showSites && !sitesMenuItem)
        {
            SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *sitesListNavigationController = [[NavigationViewController alloc] initWithRootViewController:sitesListViewController];
            sitesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSites
                                                               imageName:@"sites-main-menu.png"
                                                       localizedTitleKey:@"sites.title"
                                                          viewController:sitesListNavigationController
                                                         displayInDetail:NO];
            [repositoryMenuItems insertObject:sitesMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showSites && sitesMenuItem)
        {
            [repositoryMenuItems removeObject:sitesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:sitesMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showTasks = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationTasksKey];
        MainMenuItem *tasksMenuItem = [self existingMenuItemWithType:NavigationControllerTypeTasks];
        if (showTasks && !tasksMenuItem)
        {
            TaskViewController *taskViewController = [[TaskViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *taskNavigationController = [[NavigationViewController alloc] initWithRootViewController:taskViewController];
            tasksMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeTasks
                                                               imageName:@"tasks-main-menu.png"
                                                       localizedTitleKey:@"tasks.title"
                                                          viewController:taskNavigationController
                                                         displayInDetail:NO];
            [repositoryMenuItems insertObject:tasksMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showTasks && tasksMenuItem)
        {
            [repositoryMenuItems removeObject:tasksMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:tasksMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showFavorites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationFavoritesKey];
        MainMenuItem *favoritesMenuItem = [self existingMenuItemWithType:NavigationControllerTypeSync];
        if (showFavorites && !favoritesMenuItem)
        {
            SyncViewController *syncViewController = [[SyncViewController alloc] initWithParentNode:nil andSession:self.alfrescoSession];
            NavigationViewController *syncNavigationController = [[NavigationViewController alloc] initWithRootViewController:syncViewController];
            favoritesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSync
                                                                   imageName:@"favourites-main-menu.png"
                                                           localizedTitleKey:@"sync.title"
                                                              viewController:syncNavigationController
                                                             displayInDetail:NO];
            [repositoryMenuItems insertObject:favoritesMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showFavorites && favoritesMenuItem)
        {
            [repositoryMenuItems removeObject:favoritesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:favoritesMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showSharedFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSharedFilesKey];
        MainMenuItem *sharedFilesMenuItem = [self existingMenuItemWithType:NavigationControllerTypeSharedFiles];
        if (showSharedFiles)
        {
            if (sharedFilesMenuItem)
            {
                [repositoryMenuItems removeObject:sharedFilesMenuItem];
            }
            FileFolderListViewController *sharedFilesViewController = [[FileFolderListViewController alloc] initWithFolder:configurationManager.sharedFiles
                                                                                                         folderPermissions:nil
                                                                                                         folderDisplayName:NSLocalizedString(@"sharedFiles.title", @"Shared Files")
                                                                                                                   session:self.alfrescoSession];
            NavigationViewController *sharedFilesNavigationController = [[NavigationViewController alloc] initWithRootViewController:sharedFilesViewController];
            sharedFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSharedFiles
                                                                     imageName:@"site.png"
                                                             localizedTitleKey:@"sharedFiles.title"
                                                                viewController:sharedFilesNavigationController
                                                               displayInDetail:NO];
            [repositoryMenuItems insertObject:sharedFilesMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showSharedFiles && sharedFilesMenuItem)
        {
            [repositoryMenuItems removeObject:sharedFilesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:sharedFilesMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        BOOL showMyFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationMyFilesKey];
        MainMenuItem *myFilesMenuItem = [self existingMenuItemWithType:NavigationControllerTypeMyFiles];
        if (showMyFiles)
        {
            if (myFilesMenuItem)
            {
                [repositoryMenuItems removeObject:myFilesMenuItem];
            }
            FileFolderListViewController *myFilesViewController = [[FileFolderListViewController alloc] initWithFolder:configurationManager.myFiles
                                                                                                     folderPermissions:nil
                                                                                                     folderDisplayName:NSLocalizedString(@"myFiles.title", @"My Files")
                                                                                                               session:self.alfrescoSession];
            NavigationViewController *myFilesNavigationController = [[NavigationViewController alloc] initWithRootViewController:myFilesViewController];
            myFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeMyFiles
                                                                 imageName:@"folder.png"
                                                         localizedTitleKey:@"myFiles.title"
                                                            viewController:myFilesNavigationController
                                                           displayInDetail:NO];
            [repositoryMenuItems insertObject:myFilesMenuItem atIndex:nextIndex];
            repositoryMenuItemsChanged = YES;
        }
        else if (!showMyFiles && myFilesMenuItem)
        {
            [repositoryMenuItems removeObject:myFilesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        
        if (repositoryMenuItems.count == 0)
        {
            [self removeAllRepositoryItems];
        }
        else if (repositoryMenuItemsChanged && repositoryMenuItems.count > 0)
        {
            [self updateRepositoryItems:repositoryMenuItems];
        }
        
        // select Sites tab if exists otherwise default to Accounts
        if ([self existingMenuItemWithType:NavigationControllerTypeSites])
        {
            [self displayViewControllerWithType:NavigationControllerTypeSites];
        }
        else
        {
            [self displayViewControllerWithType:NavigationControllerTypeAccounts];
        }
    }
    else
    {
        [self removeAllRepositoryItems];
    }
}

- (MainMenuItem *)existingMenuItemWithType:(MainMenuNavigationControllerType)menuItemType
{
    __block MainMenuItem *foundItem = nil;
    [self.tableData enumerateObjectsUsingBlock:^(NSArray *sectionArray, NSUInteger idx, BOOL *stop) {
        [sectionArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MainMenuItem *mainMenuItem = (MainMenuItem *)obj;
            if (mainMenuItem.controllerType == menuItemType)
            {
                foundItem = mainMenuItem;
                *stop = YES;
            }
        }];
    }];
    return foundItem;
}

#pragma mark - Public Functions

- (void)displayViewControllerWithType:(MainMenuNavigationControllerType)controllerType
{
    MainMenuItem *menuItem = [self existingMenuItemWithType:controllerType];
    if (menuItem && [self.delegate respondsToSelector:@selector(didSelectMenuItem:)])
    {
        [self.delegate didSelectMenuItem:menuItem];
    }
}

- (void)updateRepositoryItems:(NSArray *)repositoryItems
{
    if (!self.hasRepositorySpecificSection)
    {
        [self.tableData insertObject:repositoryItems atIndex:kRepositoryItemsSectionNumber];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kRepositoryItemsSectionNumber] withRowAnimation:UITableViewRowAnimationFade];
        self.hasRepositorySpecificSection = YES;
    }
    else
    {
        [self.tableData replaceObjectAtIndex:kRepositoryItemsSectionNumber withObject:repositoryItems];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kRepositoryItemsSectionNumber] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)removeAllRepositoryItems
{
    if (self.hasRepositorySpecificSection)
    {
        [self.tableData removeObjectAtIndex:kRepositoryItemsSectionNumber];
        [self.tableView deleteSections:[NSIndexSet indexSetWithIndex:kRepositoryItemsSectionNumber] withRowAnimation:UITableViewRowAnimationFade];
        self.hasRepositorySpecificSection = NO;
    }
}

@end
