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
#import "AnalyticsManager.h"
#import "CoreDataCacheHelper.h"
#import "FileHandlerManager.h"

#import <HockeySDK/HockeySDK.h>

@interface AppDelegate()

@property (nonatomic, strong) UIViewController *appRootViewController;
@property (nonatomic, strong) CoreDataCacheHelper *cacheHelper;
@property (nonatomic, strong) id<AlfrescoSession> session;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // Migrate any old accounts if required
    [MigrationAssistant runMigrationAssistant];
    
    // Setup the app and build it's UI
    self.window.rootViewController = [self buildMainAppUIWithSession:nil];
    self.window.tintColor = [UIColor appTintColor];
    
    // Clean up cache
    self.cacheHelper = [[CoreDataCacheHelper alloc] init];
    [self.cacheHelper removeAllCachedDataOlderThanNumberOfDays:@(kNumberOfDaysToKeepCachedData)];
    
    // Register the delegate for session updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    
    // Make the window visible
    [self.window makeKeyAndVisible];

    [AppConfigurationManager sharedManager];
    
    // If a selected account is selected, attempt a login
    AccountManager *accountManager = [AccountManager sharedManager];
    if (accountManager.selectedAccount)
    {
        [[LoginManager sharedManager] attemptLoginToAccount:accountManager.selectedAccount networkId:accountManager.selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
        }];
    }
    
    // HockeyApp SDK - only for non-dev builds to avoid update prompt
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (![bundleVersion isEqualToString:@"dev"])
    {
        [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:@"50a2db26b7e3926dcca100aebc019fdd"];
        [[BITHockeyManager sharedHockeyManager] startManager];
        [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
    }
    
    // Start analytics only for non-dev builds
    if (![bundleVersion isEqualToString:@"dev"])
    {
        [[AnalyticsManager sharedManager] startAnalytics];
    }

    return YES;
}

- (BOOL)application:(UIApplication *)application openURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation
{
    return [[FileHandlerManager sharedManager] handleURL:url sourceApplication:sourceApplication annotation:annotation session:self.session];
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
    
    BOOL isFirstLaunch = [self isAppFirstLaunch];
    if (isFirstLaunch)
    {
        [[AccountManager sharedManager] removeAllAccounts];
        [self updateAppFirstLaunchFlag];
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

- (void)sessionReceived:(NSNotification *)notification
{
    self.session = notification.object;
}

@end
