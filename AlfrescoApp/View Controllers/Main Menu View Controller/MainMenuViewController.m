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
 
#import "MainMenuViewController.h"
#import "MainMenuItemCell.h"
#import "SyncNavigationViewController.h"
#import "FileFolderListViewController.h"
#import "SitesListViewController.h"
#import "ActivitiesViewController.h"
#import "TaskViewController.h"
#import "SyncViewController.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "SyncManager.h"
#import "UniversalDevice.h"
#import "DetailSplitViewController.h"
#import "AppConfigurationManager.h"
#import "SettingsViewController.h"
#import "WebBrowserViewController.h"
#import "DownloadsViewController.h"
#import "ConnectivityManager.h"

#import "AvatarManager.h"
#import "DismissCompletionProtocol.h"

// where the repo items should be displayed in the tableview
static NSUInteger const kRepositoryItemsSectionNumber = 1;
static NSUInteger const kDownloadsRowNumber = 1;

static NSUInteger const kAccountsSectionNumber = 0;
static NSUInteger const kAccountsRowNumber = 0;

@interface MainMenuViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong, readwrite) NSMutableArray *tableData;
@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, assign, readwrite) BOOL hasRepositorySpecificSection;
@property (nonatomic, strong) NSIndexPath *deselectedIndexPath;

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
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountUpdated:) name:kAlfrescoAccountUpdatedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
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
    tableView.alwaysBounceVertical = NO;
    tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    tableView.separatorColor = [UIColor clearColor];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    tableView.backgroundColor = [UIColor mainMenuBackgroundColor];
    self.tableView = tableView;
    [view addSubview:self.tableView];
    
    view.autoresizesSubviews = YES;
    self.view = view;

    UINib *cellNib = [UINib nibWithNibName:NSStringFromClass([MainMenuItemCell class]) bundle:nil];
    [self.tableView registerNib:cellNib forCellReuseIdentifier:[MainMenuItemCell cellIdentifier]];
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
    MainMenuItemCell *cell = [tableView dequeueReusableCellWithIdentifier:[MainMenuItemCell cellIdentifier]];
    
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *currentItem = [sectionArray objectAtIndex:indexPath.row];
    cell.menuTextLabel.text = [NSLocalizedString(currentItem.localizedTitleKey, @"Localised Cell Title") uppercaseString];
    cell.menuTextLabel.textColor = [UIColor mainMenuLabelColor];
    cell.menuImageView.image = [[UIImage imageNamed:currentItem.imageName] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    cell.menuAccountNameLabel.text = @"";
    
    if ([currentItem.localizedTitleKey isEqualToString:@"accounts.title"])
    {
        NSString *currentUserAccountIdentifier = self.alfrescoSession.personIdentifier;
        cell.menuAccountNameLabel.text = [[[AccountManager sharedManager] selectedAccount] accountDescription];
        cell.menuAccountNameLabel.textColor = [UIColor mainMenuLabelColor];
        UIImage *avatar = [[AvatarManager sharedManager] avatarForIdentifier:currentUserAccountIdentifier];
        if (avatar)
        {
            [cell.menuImageView setImage:avatar withFade:NO];
        }
        else
        {
            UIImage *placeholderImage = cell.menuImageView.image;
            cell.menuImageView.image = placeholderImage;
            [[AvatarManager sharedManager] retrieveAvatarForPersonIdentifier:currentUserAccountIdentifier session:self.alfrescoSession completionBlock:^(UIImage *avatarImage, NSError *avatarError) {
                if (avatarImage)
                {
                    [cell.menuImageView setImage:avatarImage withFade:YES];
                }
            }];
        }
    }
    
    cell.backgroundColor = [UIColor clearColor];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    MainMenuItemCell *cell = (MainMenuItemCell *)[self tableView:tableView cellForRowAtIndexPath:indexPath];

    CGFloat height = [cell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize].height;
    
    return MAX(height, [MainMenuItemCell minimumCellHeight]);
}

#pragma mark - Table view delegate

- (NSIndexPath *)tableView:(UITableView *)tableView willDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    self.deselectedIndexPath = indexPath;
    return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSArray *sectionArray = [self.tableData objectAtIndex:indexPath.section];
    MainMenuItem *selectedMenuItem = [sectionArray objectAtIndex:indexPath.row];
    
    if (selectedMenuItem.controllerType == MainMenuTypeHelp)
    {
        selectedMenuItem.viewController.modalPresentationStyle = UIModalPresentationPageSheet;
        [self presentViewController:selectedMenuItem.viewController animated:YES completion:nil];
    }
    else if (selectedMenuItem.controllerType == MainMenuTypeSettings)
    {
        selectedMenuItem.viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        [self presentViewController:selectedMenuItem.viewController animated:YES completion:nil];
    }
    else
    {
        [self informDelegateMenuItemSelected:selectedMenuItem];
        
        // expand the detail view controller for the iPad
        if (IS_IPAD)
        {
            DetailSplitViewController *detailSplitViewController = (DetailSplitViewController *)[UniversalDevice rootDetailViewController];
            [detailSplitViewController expandViewController];
        }
    }
}

#pragma mark - Notification Methods

- (void)sessionUpdated:(NSNotification *)notification
{
    self.alfrescoSession = (id<AlfrescoSession>)notification.object;
    
    [self reloadAccountSection];
}

- (void)appConfigurationUpdated:(NSNotification *)notification
{
    AppConfigurationManager *configurationManager = (AppConfigurationManager *)notification.object;
    // add a slight delay before configuring to ensure animations are smooth
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 0.2 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [self configureRepositoryMainMenuItems:configurationManager];
        [self configureLocalMainMenuItems:configurationManager];
    });
}

- (void)accountListEmpty:(NSNotification *)notification
{
    MainMenuItem *downloadsMenuItem = [self existingMenuItemWithType:MainMenuTypeDownloads];
    
    if (!downloadsMenuItem)
    {
        NSMutableArray *localMenuItems = self.tableData.lastObject;
        DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
        NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
        downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeDownloads
                                                               imageName:@"mainmenu-localfiles.png"
                                                       localizedTitleKey:@"downloads.title"
                                                          viewController:downloadsNavigationController
                                                         displayInDetail:NO];
        [localMenuItems insertObject:downloadsMenuItem atIndex:kDownloadsRowNumber];
        
        NSInteger localMainMenuItemsSectionIndex = [self.tableData indexOfObject:localMenuItems];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:localMainMenuItemsSectionIndex] withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)accountUpdated:(NSNotification *)notification
{
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    UserAccount *updatedAccount = notification.object;
    
    if ([selectedAccount.accountIdentifier isEqualToString:updatedAccount.accountIdentifier])
    {
        [self reloadAccountSection];
        [self.tableView selectRowAtIndexPath:[NSIndexPath indexPathForRow:kAccountsRowNumber inSection:kAccountsSectionNumber] animated:NO scrollPosition:UITableViewScrollPositionNone];
        [self configureRepositoryMainMenuItems:[AppConfigurationManager sharedManager]];
    }
}

- (void)accountRemoved:(NSNotification *)notification
{
    [[AvatarManager sharedManager] deleteAvatarForIdentifier:self.alfrescoSession.personIdentifier];
    
    UserAccount *selectedAccount = [[AccountManager sharedManager] selectedAccount];
    UserAccount *removedAccount = notification.object;
    
    if ([selectedAccount.accountIdentifier isEqualToString:removedAccount.accountIdentifier])
    {
        self.alfrescoSession = nil;
        [self reloadAccountSection];
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
    DismissCompletionBlock dismissCompletionBlock = ^(void) {
        // Restore previously selected menu item when modal views are dismissed
        if (self.deselectedIndexPath)
        {
            [self.tableView selectRowAtIndexPath:self.deselectedIndexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
    };
    
    SettingsViewController *settingsViewController = [[SettingsViewController alloc] initWithSession:self.alfrescoSession];
    settingsViewController.dismissCompletionBlock = dismissCompletionBlock;
    NavigationViewController *settingsNavigationController = [[NavigationViewController alloc] initWithRootViewController:settingsViewController];
    MainMenuItem *settingsMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSettings
                                                                        imageName:@"mainmenu-settings.png"
                                                                localizedTitleKey:@"settings.title"
                                                                   viewController:settingsNavigationController
                                                                  displayInDetail:YES];
    
    NSURL *userGuidUrl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"UserGuide" ofType:@"pdf"]];
    WebBrowserViewController *helpViewController = [[WebBrowserViewController alloc] initWithURL:userGuidUrl initialTitle:NSLocalizedString(@"help.title", @"Help") errorLoadingURL:nil];
    helpViewController.dismissCompletionBlock = dismissCompletionBlock;
    NavigationViewController *helpNavigationController = [[NavigationViewController alloc] initWithRootViewController:helpViewController];
    MainMenuItem *helpMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeHelp
                                                                    imageName:@"mainmenu-help.png"
                                                            localizedTitleKey:@"help.title"
                                                               viewController:helpNavigationController
                                                              displayInDetail:YES];
    
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
    NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
    MainMenuItem *downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeDownloads
                                                           imageName:@"mainmenu-localfiles.png"
                                                   localizedTitleKey:@"downloads.title"
                                                      viewController:downloadsNavigationController
                                                     displayInDetail:NO];
    
    return [@[downloadsMenuItem, settingsMenuItem, helpMenuItem] mutableCopy];
}

- (void)configureLocalMainMenuItems:(AppConfigurationManager *)configurationManager
{
    NSMutableArray *localMenuItems = self.tableData.lastObject;
    BOOL localMenuItemsChanged = NO;
    
    BOOL showLocalFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationLocalFilesKey];
    MainMenuItem *downloadsMenuItem = [self existingMenuItemWithType:MainMenuTypeDownloads];
    if (showLocalFiles && !downloadsMenuItem)
    {
        DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:self.alfrescoSession];
        NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
        downloadsMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeDownloads
                                                               imageName:@"mainmenu-localfiles.png"
                                                       localizedTitleKey:@"downloads.title"
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
        
        // Activites
        BOOL showActivities = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationActivitiesKey];
        MainMenuItem *activitiesMenuItem = [self existingMenuItemWithType:MainMenuTypeActivities];
        if (showActivities && !activitiesMenuItem)
        {
            ActivitiesViewController *activitiesViewController = [[ActivitiesViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *activitiesNavigationController = [[NavigationViewController alloc] initWithRootViewController:activitiesViewController];
            activitiesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeActivities
                                                                    imageName:@"mainmenu-activities.png"
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
        
        // Tasks
        BOOL showTasks = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationTasksKey];
        MainMenuItem *tasksMenuItem = [self existingMenuItemWithType:MainMenuTypeTasks];
        if (showTasks && !tasksMenuItem)
        {
            TaskViewController *taskViewController = [[TaskViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *taskNavigationController = [[NavigationViewController alloc] initWithRootViewController:taskViewController];
            tasksMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeTasks
                                                               imageName:@"mainmenu-tasks.png"
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
        
        // Favourites
        BOOL showFavorites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationFavoritesKey];
        MainMenuItem *favoritesMenuItem = [self existingMenuItemWithType:MainMenuTypeSync];
        if (showFavorites)
        {
            BOOL isSyncOn = [[SyncManager sharedManager] isSyncPreferenceOn];
            
            if (!favoritesMenuItem)
            {
                SyncViewController *syncViewController = [[SyncViewController alloc] initWithParentNode:nil andSession:self.alfrescoSession];
                SyncNavigationViewController *syncNavigationController = [[SyncNavigationViewController alloc] initWithRootViewController:syncViewController];
                favoritesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSync
                                                                       imageName:isSyncOn ? @"mainmenu-sync.png" : @"mainmenu-favourites.png"
                                                               localizedTitleKey:isSyncOn ? @"sync.title" : @"favourites.title"
                                                                  viewController:syncNavigationController
                                                                 displayInDetail:NO];
                [repositoryMenuItems insertObject:favoritesMenuItem atIndex:nextIndex];
                repositoryMenuItemsChanged = YES;
                
            }
            else
            {
                MainMenuItem *menuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSync
                                                                            imageName:isSyncOn ? @"mainmenu-sync.png" : @"mainmenu-favourites.png"
                                                                    localizedTitleKey:isSyncOn ? @"sync.title" : @"favourites.title"
                                                                       viewController:favoritesMenuItem.viewController
                                                                      displayInDetail:NO];
                [repositoryMenuItems replaceObjectAtIndex:[repositoryMenuItems indexOfObject:favoritesMenuItem] withObject:menuItem];
                favoritesMenuItem = menuItem;
                repositoryMenuItemsChanged = YES;
            }
        }
        else if (!showFavorites && favoritesMenuItem)
        {
            [repositoryMenuItems removeObject:favoritesMenuItem];
            repositoryMenuItemsChanged = YES;
        }
        itemIndex = [repositoryMenuItems indexOfObject:favoritesMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        // Sites
        BOOL showSites = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSitesKey];
        MainMenuItem *sitesMenuItem = [self existingMenuItemWithType:MainMenuTypeSites];
        if (showSites && !sitesMenuItem)
        {
            SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:self.alfrescoSession];
            NavigationViewController *sitesListNavigationController = [[NavigationViewController alloc] initWithRootViewController:sitesListViewController];
            sitesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSites
                                                               imageName:@"mainmenu-sites.png"
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
        
        // My Files
        BOOL showMyFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationMyFilesKey];
        MainMenuItem *myFilesMenuItem = [self existingMenuItemWithType:MainMenuTypeMyFiles];
        if (showMyFiles)
        {
            if (myFilesMenuItem)
            {
                [repositoryMenuItems removeObject:myFilesMenuItem];
            }
            FileFolderListViewController *myFilesViewController = [[FileFolderListViewController alloc] initWithFolder:configurationManager.myFiles
                                                                                                     folderPermissions:configurationManager.myFilesPermissions
                                                                                                     folderDisplayName:NSLocalizedString(@"myFiles.title", @"My Files")
                                                                                                               session:self.alfrescoSession];
            NavigationViewController *myFilesNavigationController = [[NavigationViewController alloc] initWithRootViewController:myFilesViewController];
            myFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeMyFiles
                                                                 imageName:@"mainmenu-myfiles.png"
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
        itemIndex = [repositoryMenuItems indexOfObject:myFilesMenuItem];
        nextIndex = (itemIndex != NSNotFound) ? ++itemIndex : nextIndex;
        
        // Shared Files
        BOOL showSharedFiles = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationSharedFilesKey];
        MainMenuItem *sharedFilesMenuItem = [self existingMenuItemWithType:MainMenuTypeSharedFiles];
        if (showSharedFiles)
        {
            if (sharedFilesMenuItem)
            {
                [repositoryMenuItems removeObject:sharedFilesMenuItem];
            }
            FileFolderListViewController *sharedFilesViewController = [[FileFolderListViewController alloc] initWithFolder:configurationManager.sharedFiles
                                                                                                         folderPermissions:configurationManager.sharedFilesPermissions
                                                                                                         folderDisplayName:NSLocalizedString(@"sharedFiles.title", @"Shared Files")
                                                                                                                   session:self.alfrescoSession];
            NavigationViewController *sharedFilesNavigationController = [[NavigationViewController alloc] initWithRootViewController:sharedFilesViewController];
            sharedFilesMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeSharedFiles
                                                                     imageName:@"mainmenu-sharedfiles.png"
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
        
        // Repository
        BOOL showRepository = [configurationManager visibilityForMainMenuItemWithKey:kAppConfigurationRepositoryKey];
        MainMenuItem *companyHomeMenuItem = [self existingMenuItemWithType:MainMenuTypeRepository];
        if (showRepository && !companyHomeMenuItem)
        {
            FileFolderListViewController *companyHomeViewController = [[FileFolderListViewController alloc] initWithFolder:nil session:self.alfrescoSession];
            NavigationViewController *companyHomeNavigationController = [[NavigationViewController alloc] initWithRootViewController:companyHomeViewController];
            companyHomeMenuItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeRepository
                                                                     imageName:@"mainmenu-repository.png"
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
        
        if (repositoryMenuItems.count == 0)
        {
            [self removeAllRepositoryItems];
        }
        else if (repositoryMenuItemsChanged && repositoryMenuItems.count > 0)
        {
            [self updateRepositoryItems:repositoryMenuItems];
        }
        
        // select Sites tab if exists otherwise default to Accounts
        NSInteger indexOfItemDisplayed = NSNotFound;
        
        UINavigationController *currentlyDisplayedController = [self currentlyDisplayedNavigationController];
        
        // If currently displayed view is Sync view then Sync view is displayed after session renewal e.g User Pulled to refresh
        if ([currentlyDisplayedController.viewControllers.firstObject isKindOfClass:[SyncViewController class]])
        {
            [self displayViewControllerWithType:MainMenuTypeSync];
            indexOfItemDisplayed = [repositoryMenuItems indexOfObject:favoritesMenuItem];
        }
        else
        {
            if ([[ConnectivityManager sharedManager] hasInternetConnection] && [self existingMenuItemWithType:MainMenuTypeSites])
            {
                [self displayViewControllerWithType:MainMenuTypeSites];
                indexOfItemDisplayed = [repositoryMenuItems indexOfObject:sitesMenuItem];
            }
            else
            {
                [self displayViewControllerWithType:MainMenuTypeAccounts];
            }
        }
        
        // select cell for displayed menu item
        NSIndexPath *selectedItemIndexPath = nil;
        if (indexOfItemDisplayed != NSNotFound)
        {
            selectedItemIndexPath = [NSIndexPath indexPathForRow:indexOfItemDisplayed inSection:kRepositoryItemsSectionNumber];
        }
        else
        {
            selectedItemIndexPath = [NSIndexPath indexPathForRow:kAccountsRowNumber inSection:kAccountsSectionNumber];
        }
        [self.tableView selectRowAtIndexPath:selectedItemIndexPath animated:YES scrollPosition:UITableViewScrollPositionNone];
    }
    else
    {
        [self removeAllRepositoryItems];
    }
}

- (MainMenuItem *)existingMenuItemWithType:(MainMenuType)menuItemType
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

- (void)reloadAccountSection
{
    // Reload the accounts section
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:kAccountsRowNumber inSection:kAccountsSectionNumber]] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark - Public Functions

- (void)displayViewControllerWithType:(MainMenuType)controllerType
{
    MainMenuItem *menuItem = [self existingMenuItemWithType:controllerType];
    if (menuItem && [self.delegate respondsToSelector:@selector(didSelectMenuItem:)])
    {
        [self.delegate didSelectMenuItem:menuItem];
    }
}

- (UINavigationController *)currentlyDisplayedNavigationController
{
    UINavigationController *displayedController = nil;
    if ([self.delegate respondsToSelector:@selector(currentlyDisplayedController)])
    {
        displayedController = (UINavigationController *)[self.delegate currentlyDisplayedController];
    }
    return displayedController;
}

- (void)updateRepositoryItems:(NSArray *)repositoryItems
{
    if (!self.hasRepositorySpecificSection)
    {
        [self.tableData insertObject:repositoryItems atIndex:kRepositoryItemsSectionNumber];
        [self.tableView insertSections:[NSIndexSet indexSetWithIndex:kRepositoryItemsSectionNumber] withRowAnimation:UITableViewRowAnimationAutomatic];
        self.hasRepositorySpecificSection = YES;
    }
    else
    {
        [self.tableData replaceObjectAtIndex:kRepositoryItemsSectionNumber withObject:repositoryItems];
        [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:kRepositoryItemsSectionNumber] withRowAnimation:UITableViewRowAnimationAutomatic];
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
