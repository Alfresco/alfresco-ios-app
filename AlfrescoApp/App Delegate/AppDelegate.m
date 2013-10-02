//
//  AppDelegate.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AppDelegate.h"
#import "SitesListViewController.h"
#import "FileFolderListViewController.h"
#import "PlaceholderViewController.h"
#import "ActivitiesViewController.h"
#import "TaskViewController.h"
#import "MoreViewController.h"
#import "Utility.h"
#import "LoginManager.h"
#import "FileURLHandler.h"
#import "LocationManager.h"
#import "Account.h"
#import "AccountManager.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"

static NSString * const kAlfrescoAppDataModel = @"AlfrescoApp";
static NSString * const kAlfrescoAppDataStore = @"alfrescoApp.sqlite";

@interface AppDelegate()

@property (nonatomic, strong) NSMutableArray *navigationControllers;
@property (nonatomic, strong) UITabBarController *tabBarController;

// Storage for deferred application:openURL:sourceApplication:annotation:
@property (nonatomic, assign) BOOL hasDeferredOpenURLToProcess;
@property (nonatomic, strong) id<URLHandlerProtocol> deferredHandler;
@property (nonatomic, strong) NSURL *deferredURL;
@property (nonatomic, strong) NSString *deferredSourceApplication;
@property (nonatomic, strong) id deferredAnnotation;
@property (nonatomic, strong) UIViewController *appRootViewController;

@property (nonatomic, strong, readwrite) NSManagedObjectContext *managedObjectContext;
@property (nonatomic, strong, readwrite) NSManagedObjectModel *managedObjectModel;
@property (nonatomic, strong, readwrite) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.hasDeferredOpenURLToProcess = NO;
    
    self.window.rootViewController = [self buildMainAppUIWithSession:nil];
    
    [self.window makeKeyAndVisible];
    
    // login to default account
    NSArray *allAccounts = [[AccountManager sharedManager] allAccounts];
    
#ifdef DEBUG
//    [[AccountManager sharedManager] removeAllAccounts];
#endif
    
    // REMOVE THIS - TESTING PURPOSES ONLY
    if (!allAccounts || allAccounts.count == 0)
    {
        Account *testAccount = [[Account alloc] initWithUsername:@"admin" password:@"incorrectPassword" description:@"test" serverAddress:@"localhost" port:@"8080"];
        [[AccountManager sharedManager] addAccount:testAccount];
    }
    
    [[LoginManager sharedManager] attemptLoginToAccount:allAccounts[0]];
    
    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    if (self.hasDeferredOpenURLToProcess)
    {
        // If we've already deferred an openURL request, then tell iOS that we won't handle another one
        return NO;
    }

//    NSArray *urlHandlers = @[
//                             // Handler for "Open In..." links from other apps
//                             [[FileURLHandler alloc] init]
//                             ];

//    // Loop through handlers for the first one that claims to support the inbound url
//    for (id<URLHandlerProtocol>handler in urlHandlers)
//    {
//        if ([handler canHandleURL:url])
//        {
//            if (self.isGDiOSAuthorised)
//            {
//                // User is authorised with GD, so we can access the secure storage
//                return [handler handleURL:url sourceApplication:sourceApplication annotation:annotation];
//            }
//            else
//            {
//                // We'll need to defer handling the inbound request until the user is authorised
//                self.hasDeferredOpenURLToProcess = YES;
//                self.deferredHandler = handler;
//                self.deferredURL = url;
//                self.deferredSourceApplication = sourceApplication;
//                self.deferredAnnotation = annotation;
//                
//                // Return YES to indicate to iOS we'll be handling the Open In... request.
//                return YES;
//            }
//        }
//    }
    
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[AccountManager sharedManager] saveAccountsToKeychain];
}

#pragma mark - Private Functions

- (UIViewController *)buildMainAppUIWithSession:(id<AlfrescoSession>)session
{
    UIViewController *rootViewController = nil;
    
    // View controllers
    FileFolderListViewController *companyHomeViewController = [[FileFolderListViewController alloc] initWithFolder:nil session:session];
    SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:session];
    ActivitiesViewController *activitiesViewController = [[ActivitiesViewController alloc] initWithSession:session];
    MoreViewController *moreViewController = [[MoreViewController alloc] init];
    TaskViewController *taskViewController = [[TaskViewController alloc] initWithSession:session];
    
    // Navigation controllers
    NavigationViewController *companyHomeNavigationController = [[NavigationViewController alloc] initWithRootViewController:companyHomeViewController];
    [companyHomeNavigationController setTitle:NSLocalizedString(@"companyHome.title", @"Company Home Title")];
    [companyHomeNavigationController.tabBarItem setImage:[UIImage imageNamed:@"repository-tabbar.png"]];
    
    NavigationViewController *sitesListNavigationController = [[NavigationViewController alloc] initWithRootViewController:sitesListViewController];
    [sitesListNavigationController setTitle:NSLocalizedString(@"sites.title", @"Sites Title")];
    [sitesListNavigationController.tabBarItem setImage:[UIImage imageNamed:@"sites-tabbar.png"]];
    
    NavigationViewController *activitiesNavigationController = [[NavigationViewController alloc] initWithRootViewController:activitiesViewController];
    [activitiesViewController setTitle:NSLocalizedString(@"activities.title", @"Activities Title")];
    [activitiesNavigationController.tabBarItem setImage:[UIImage imageNamed:@"activities-tabbar.png"]];
    
    NavigationViewController *taskNavigationController = [[NavigationViewController alloc] initWithRootViewController:taskViewController];
    [taskNavigationController setTitle:NSLocalizedString(@"tasks.title", @"Tasks Title")];
    [taskNavigationController.tabBarItem setImage:[UIImage imageNamed:@"downloads-tabbar.png"]];
    
    NavigationViewController *moreNavigationController = [[NavigationViewController alloc] initWithRootViewController:moreViewController];
    moreNavigationController.tabBarItem = [[UITabBarItem alloc] initWithTabBarSystemItem:UITabBarSystemItemMore tag:0];
    
    // This section looks over-engineered, but does guarantee the array indices (and UITabBar order) match the enum values
    self.navigationControllers = [NSMutableArray arrayWithCapacity:NavigationControllerType_MAX_ENUM];
    for (NSUInteger index = 0; index < NavigationControllerType_MAX_ENUM; index++)
    {
        [self.navigationControllers addObject:[NSNull null]];
    }
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeActivities withObject:activitiesNavigationController];
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeRepository withObject:companyHomeNavigationController];
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeSites withObject:sitesListNavigationController];
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeTasks withObject:taskNavigationController];
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeMore withObject:moreNavigationController];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;
    self.tabBarController.viewControllers = [NSArray arrayWithArray:self.navigationControllers];
    [self.tabBarController setSelectedViewController:sitesListNavigationController];
    
    rootViewController = self.tabBarController;
    
    RootRevealControllerViewController *rootRevealViewController = [[RootRevealControllerViewController alloc] initWithMasterViewController:nil detailViewController:self.tabBarController];
    
    if (IS_IPAD)
    {
        PlaceholderViewController *placeholderViewController = [[PlaceholderViewController alloc] init];
        NavigationViewController *detailNavigationController = [[NavigationViewController alloc] initWithRootViewController:placeholderViewController];
        
        DetailSplitViewController *splitViewController = [[DetailSplitViewController alloc] initWithMasterViewController:self.tabBarController detailViewController:detailNavigationController];
        
        splitViewController.delegate = detailNavigationController;
        
        rootRevealViewController = [[RootRevealControllerViewController alloc] initWithMasterViewController:nil detailViewController:splitViewController];
    }
    
    rootViewController = rootRevealViewController;
    
    return rootViewController;
}

#pragma mark - Public Interface

- (NavigationViewController *)navigationControllerOfType:(NavigationControllerType)navigationControllerType
{
    return [self.navigationControllers objectAtIndex:navigationControllerType];
}

- (void)activateTabBarForNavigationControllerOfType:(NavigationControllerType)navigationControllerType
{
    [self.tabBarController setSelectedIndex:navigationControllerType];
}

#pragma mark - UITabbarControllerDelegate Functions

- (BOOL)tabBarController:(UITabBarController *)tabBarController shouldSelectViewController:(UIViewController *)viewController
{
    // Avoid popping to the root view controller when double tapping the about tab
    if ([viewController.tabBarItem.title isEqualToString:NSLocalizedString(@"about.title", @"About Title")] && tabBarController.selectedViewController == viewController)
    {
        return NO;
    }
    
    return YES;
}

#pragma mark - Core Data stack

- (void)saveContext
{
    NSError *error = nil;
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

// Returns the managed object context for the application.
// If the context doesn't already exist, it is created and bound to the persistent store coordinator for the application.
- (NSManagedObjectContext *)managedObjectContext
{
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (coordinator != nil) {
        _managedObjectContext = [[NSManagedObjectContext alloc] init];
        [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    }
    return _managedObjectContext;
}

// Returns the managed object model for the application.
// If the model doesn't already exist, it is created from the application's model.
- (NSManagedObjectModel *)managedObjectModel
{
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }
    NSURL *modelURL = [[NSBundle mainBundle] URLForResource:kAlfrescoAppDataModel withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
}

// Returns the persistent store coordinator for the application.
// If the coordinator doesn't already exist, it is created and the application's store added to it.
- (NSPersistentStoreCoordinator *)persistentStoreCoordinator
{
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    NSURL *storeURL = [[self applicationDocumentsDirectory] URLByAppendingPathComponent:kAlfrescoAppDataStore];
    
    NSError *error = nil;
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        /*
         Replace this implementation with code to handle the error appropriately.
         
         abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
         
         Typical reasons for an error here include:
         * The persistent store is not accessible;
         * The schema for the persistent store is incompatible with current managed object model.
         Check the error message to determine what the actual problem was.
         
         
         If the persistent store is not accessible, there is typically something wrong with the file path. Often, a file URL is pointing into the application's resources directory instead of a writeable directory.
         
         If you encounter schema incompatibility errors during development, you can reduce their frequency by:
         * Simply deleting the existing store:
         [[NSFileManager defaultManager] removeItemAtURL:storeURL error:nil]
         
         * Performing automatic lightweight migration by passing the following dictionary as the options parameter:
         @{NSMigratePersistentStoresAutomaticallyOption:@YES, NSInferMappingModelAutomaticallyOption:@YES}
         
         Lightweight migration will only work for a limited set of schema changes; consult "Core Data Model Versioning and Data Migration Programming Guide" for details.
         
         */
        NSLog(@"Unresolved error %@, %@", error, [error userInfo]);
        abort();
    }
    
    return _persistentStoreCoordinator;
}

#pragma mark - Application's Documents directory

// Returns the URL to the application's Documents directory.
- (NSURL *)applicationDocumentsDirectory
{
    return [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
}

@end
