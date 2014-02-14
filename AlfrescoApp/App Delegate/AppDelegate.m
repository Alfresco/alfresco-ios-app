//
//  AppDelegate.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "AppDelegate.h"
#import "PlaceholderViewController.h"
#import "Utility.h"
#import "LoginManager.h"
#import "FileURLHandler.h"
#import "LocationManager.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"
#import "MainMenuViewController.h"
#import "SwitchViewController.h"
#import "AccountsViewController.h"
#import "OnboardingViewController.h"
#import "ContainerViewController.h"
#import "MigrationAssistant.h"
#import "AppConfigurationManager.h"
#import "UIColor+Custom.h"

#import <HockeySDK/HockeySDK.h>

@interface AppDelegate()

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
    
    [MigrationAssistant runMigrationAssistant];
    
    self.window.rootViewController = [self buildMainAppUIWithSession:nil];
    self.window.tintColor = [UIColor appTintColor];

    AccountManager *accountManager = [AccountManager sharedManager];
    [AppConfigurationManager sharedManager];
    
    BOOL isFirstLaunch = [self isAppFirstLaunch];
    if (isFirstLaunch)
    {
        [accountManager removeAllAccounts];
        [self updateAppFirstLaunchFlag];
    }
    else if (accountManager.selectedAccount)
    {
        [[LoginManager sharedManager] attemptLoginToAccount:accountManager.selectedAccount networkId:accountManager.selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
        }];
    }
    
    [self.window makeKeyAndVisible];
    
#ifdef DEBUG
//    [[AccountManager sharedManager] removeAllAccounts];
#endif

    // HockeyApp SDK - only for non-dev builds to avoid update prompt
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (![bundleVersion isEqualToString:@"dev"])
    {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"50a2db26b7e3926dcca100aebc019fdd"];
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return NO;
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[AccountManager sharedManager] saveAccountsToKeychain];
}

#pragma mark - Private Functions

- (UIViewController *)buildMainAppUIWithSession:(id<AlfrescoSession>)session
{
    RootRevealControllerViewController *rootRevealViewController = nil;
    
    AccountsViewController *accountsViewController = [[AccountsViewController alloc] initWithSession:session];
    NavigationViewController *accountsNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountsViewController];
    MainMenuItem *accountsItem = [[MainMenuItem alloc] initWithControllerType:NavigationControllerTypeAccounts
                                                                    imageName:@"mainmenu-accounts.png"
                                                            localizedTitleKey:@"accounts.title"
                                                               viewController:accountsNavigationController
                                                              displayInDetail:NO];
    
    SwitchViewController *switchController = [[SwitchViewController alloc] initWithInitialViewController:accountsNavigationController];
    
    MainMenuViewController *mainMenuController = [[MainMenuViewController alloc] initWithAccountsSectionItems:@[accountsItem]];
    mainMenuController.delegate = switchController;
    
    rootRevealViewController = [[RootRevealControllerViewController alloc] initWithMasterViewController:mainMenuController detailViewController:switchController];
    
    if (IS_IPAD)
    {
        PlaceholderViewController *placeholderViewController = [[PlaceholderViewController alloc] init];
        NavigationViewController *detailNavigationController = [[NavigationViewController alloc] initWithRootViewController:placeholderViewController];
        
        DetailSplitViewController *splitViewController = [[DetailSplitViewController alloc] initWithMasterViewController:switchController detailViewController:detailNavigationController];
        
        rootRevealViewController.masterViewController = mainMenuController;
        rootRevealViewController.detailViewController = splitViewController;
    }
    
    // check accounts and add this if applicable
    if ([[AccountManager sharedManager] totalNumberOfAddedAccounts] == 0)
    {
        OnboardingViewController *onboardingViewController = [[OnboardingViewController alloc] init];
        [rootRevealViewController addOverlayedViewController:onboardingViewController];
    }
    
    // add reveal controller to the container
    ContainerViewController *containerController = [[ContainerViewController alloc] initWithController:rootRevealViewController];
    
    return containerController;
}

- (BOOL)isAppFirstLaunch
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    return ([userDefaults objectForKey:kIsAppFirstLaunch] == nil);
}

- (void)updateAppFirstLaunchFlag
{
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setObject:[NSNumber numberWithBool:NO] forKey:kIsAppFirstLaunch];
    [userDefaults synchronize];
}

#pragma mark - Public Interface

- (NavigationViewController *)navigationControllerOfType:(MainMenuNavigationControllerType)navigationControllerType
{
//    return [self.navigationControllers objectAtIndex:navigationControllerType];
    // TODO
    return nil;
}

- (void)activateTabBarForNavigationControllerOfType:(MainMenuNavigationControllerType)navigationControllerType
{
    //    [self.tabBarController setSelectedIndex:navigationControllerType];
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
