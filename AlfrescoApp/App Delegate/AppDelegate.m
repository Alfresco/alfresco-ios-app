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
#import "DownloadsViewController.h"
#import "MoreViewController.h"
#import "Utility.h"
#import "LoginManager.h"
#import "FileURLHandler.h"
#import "LocationManager.h"

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

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.hasDeferredOpenURLToProcess = NO;
    
    self.window.rootViewController = [self buildMainAppUIWithSession:nil];
    
    [self.window makeKeyAndVisible];
    
    [[LoginManager sharedManager] attemptLogin];
    
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

#pragma mark - Private Functions

- (UIViewController *)buildMainAppUIWithSession:(id<AlfrescoSession>)session
{
    UIViewController *rootViewController = nil;
    
    // View controllers
    FileFolderListViewController *companyHomeViewController = [[FileFolderListViewController alloc] initWithFolder:nil session:session];
    SitesListViewController *sitesListViewController = [[SitesListViewController alloc] initWithSession:session];
    ActivitiesViewController *activitiesViewController = [[ActivitiesViewController alloc] initWithSession:session];
    MoreViewController *moreViewController = [[MoreViewController alloc] init];
    DownloadsViewController *downloadsViewController = [[DownloadsViewController alloc] initWithSession:session];
    
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
    
    NavigationViewController *downloadsNavigationController = [[NavigationViewController alloc] initWithRootViewController:downloadsViewController];
    [downloadsNavigationController setTitle:NSLocalizedString(@"downloads.title", @"Downloads Title")];
    [downloadsNavigationController.tabBarItem setImage:[UIImage imageNamed:@"downloads-tabbar.png"]];
    
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
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeDownloads withObject:downloadsNavigationController];
    [self.navigationControllers replaceObjectAtIndex:NavigationControllerTypeMore withObject:moreNavigationController];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.delegate = self;
    self.tabBarController.viewControllers = [NSArray arrayWithArray:self.navigationControllers];
    [self.tabBarController setSelectedViewController:sitesListNavigationController];
    
    rootViewController = self.tabBarController;
    
    if (IS_IPAD)
    {
        UISplitViewController *splitViewController = [[UISplitViewController alloc] init];
        PlaceholderViewController *placeholderViewController = [[PlaceholderViewController alloc] init];
        NavigationViewController *detailNavigationController = [[NavigationViewController alloc] initWithRootViewController:placeholderViewController];
        
        splitViewController.delegate = detailNavigationController;
        splitViewController.viewControllers = @[self.tabBarController, detailNavigationController];
        
        rootViewController = splitViewController;
    }
    
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

@end
