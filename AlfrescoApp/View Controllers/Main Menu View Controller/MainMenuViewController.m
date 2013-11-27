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

// where the repo items should be displayed in the tableview
static NSUInteger const kRepositoryItemsSectionNumber = 1;

@interface MainMenuViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong, readwrite) NSMutableArray *tableData;
@property (nonatomic, weak, readwrite) UITableView *tableView;
@property (nonatomic, assign, readwrite) BOOL hasRepositorySpecificSection;

@end

@implementation MainMenuViewController

- (instancetype)initWithAccountsSectionItems:(NSArray *)accountSectionItems localSectionItems:(NSArray *)localSectionItems
{
    self = [super init];
    if (self)
    {
        self.tableData = [NSMutableArray array];
        if (accountSectionItems)
        {
            [self.tableData addObject:accountSectionItems];
        }
        
        if (localSectionItems)
        {
            [self.tableData addObject:localSectionItems];
        }
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionUpdated:) name:kAlfrescoSessionReceivedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(noMoreAccounts:) name:kAlfrescoAccountsListEmptyNotification object:nil];
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
}

#pragma mark - Private Functions

- (void)informDelegateMenuItemSelected:(MainMenuItem *)menuItem
{
    [self.delegate didSelectMenuItem:menuItem];
}

- (void)sessionUpdated:(NSNotification *)notification
{
    // this will eventually be be moved from this controller once the mobile server module is added and the app
    // needs to carry out multiple dynamic behaviours.
    id<AlfrescoSession> session = (id<AlfrescoSession>)notification.object;
    
    FileFolderListViewController *companyHomeViewController = [[FileFolderListViewController alloc] initWithFolder:nil session:session];
    SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:session];
    ActivitiesViewController *activitiesViewController = [[ActivitiesViewController alloc] initWithSession:session];
    TaskViewController *taskViewController = [[TaskViewController alloc] initWithSession:session];
    SyncViewController *syncViewController = [[SyncViewController alloc] initWithParentNode:nil andSession:session];
    
    NavigationViewController *companyHomeNavigationController = [[NavigationViewController alloc] initWithRootViewController:companyHomeViewController];
    NavigationViewController *sitesListNavigationController = [[NavigationViewController alloc] initWithRootViewController:sitesListViewController];
    NavigationViewController *activitiesNavigationController = [[NavigationViewController alloc] initWithRootViewController:activitiesViewController];
    NavigationViewController *taskNavigationController = [[NavigationViewController alloc] initWithRootViewController:taskViewController];
    NavigationViewController *syncNavigationController = [[NavigationViewController alloc] initWithRootViewController:syncViewController];
    
    MainMenuItem *activitiesItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeActivities
                                                                      imageName:@"activities-main-menu.png"
                                                              localizedTitleKey:@"activities.title"
                                                                 viewController:activitiesNavigationController
                                                                displayInDetail:NO];
    MainMenuItem *repositoryItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeRepository
                                                                      imageName:@"repository-tabbar.png"
                                                              localizedTitleKey:@"companyHome.title"
                                                                 viewController:companyHomeNavigationController
                                                                displayInDetail:NO];
    MainMenuItem *sitesItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSites
                                                                 imageName:@"sites-main-menu.png"
                                                         localizedTitleKey:@"sites.title"
                                                            viewController:sitesListNavigationController
                                                           displayInDetail:NO];
    MainMenuItem *tasksItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeTasks
                                                                 imageName:@"tasks-main-menu.png"
                                                         localizedTitleKey:@"tasks.title"
                                                            viewController:taskNavigationController
                                                           displayInDetail:NO];
    MainMenuItem *syncItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeSync
                                                                imageName:@"favourites-main-menu.png"
                                                        localizedTitleKey:@"sync.title"
                                                           viewController:syncNavigationController
                                                          displayInDetail:NO];
    
    [self addRepositoryItems:@[activitiesItem, repositoryItem, sitesItem, tasksItem, syncItem]];
    [self displayViewControllerWithType:NavigationControllerTypeSites];
}

- (void)accountRemoved:(NSNotification *)notification
{
    UserAccount *accountRemoved = (UserAccount *)notification.object;
    
    if ([[[AccountManager sharedManager] selectedAccount] isEqual:accountRemoved])
    {
        [self removeAllRepositoryItems];
    }
}

- (void)noMoreAccounts:(NSNotification *)notification
{
    [self removeAllRepositoryItems];
}

#pragma mark - Public Functions

- (void)displayViewControllerWithType:(MainMenuNavigationControllerType)controllerType
{
    [self.tableData enumerateObjectsUsingBlock:^(NSArray *sectionArray, NSUInteger idx, BOOL *stop) {
        [sectionArray enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
            MainMenuItem *currentMenuItem = (MainMenuItem *)obj;
            if (currentMenuItem.controllerType == controllerType)
            {
                [self.delegate didSelectMenuItem:currentMenuItem];
            }
        }];
    }];
}

- (void)addRepositoryItems:(NSArray *)repositoryItems
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
        [self displayViewControllerWithType:NavigationControllerTypeAccounts];
    }
}

@end
