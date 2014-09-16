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
 
#import "AppDelegate.h"
#import "PlaceholderViewController.h"
#import "LoginManager.h"
#import "LocationManager.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "RootRevealControllerViewController.h"
#import "DetailSplitViewController.h"
#import "SwitchViewController.h"
#import "AccountsViewController.h"
#import "OnboardingViewController.h"
#import "ContainerViewController.h"
#import "MigrationAssistant.h"
#import "AppConfigurationManager.h"

#import "AnalyticsManager.h"
#import "CoreDataCacheHelper.h"
#import "FileHandlerManager.h"

#import <HockeySDK/HockeySDK.h>

@interface AppDelegate()

@property (nonatomic, strong) UIViewController *appRootViewController;
@property (nonatomic, strong) CoreDataCacheHelper *cacheHelper;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) MainMenuViewController *mainMenuViewController;

@end

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /**
     * This version of the app has been coded in such a way to require valid Alfresco Cloud OAuth key and secret tokens.
     * These should be populated in the AlfrescoApp.xcconfig file, either via an environment variable or directly in the file.
     * - "CLOUD_OAUTH_KEY"
     * - "CLOUD_OAUTH_SECRET"
     * If these values are not present, the app will still attempt to present cloud authentication options.
     *
     * Functionality that won't be available unless you have other valid keys are:
     * - HockeyApp SDK integration. Requires "HOCKEYAPP_APPID"
     * - Flurry Analytics. Requires "FLURRY_API_KEY"
     * - Google Quickoffice Save Back. Requires "QUICKOFFICE_PARTNER_KEY"
     *
     * Functionality that is not made available to third-party apps:
     * - Alfresco Cloud sign-up. This is a private implementation available to Alfresco only.
     */
    if (CLOUD_OAUTH_KEY.length == 0) AlfrescoLogError(@"CLOUD_OAUTH_KEY must have non-zero length");
    if (CLOUD_OAUTH_SECRET.length == 0) AlfrescoLogError(@"CLOUD_OAUTH_SECRET must have non-zero length");
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    /**
     * Note: CFBundleVersion is updated for AdHoc builds by calling the tools/set_build_number.sh script (configured in the build pre-action).
     * The script updates CFBundleVersion from a CF_BUNDLE_VERSION environment variable which we have configured at Alfresco
     * to be set to ${bamboo.buildNumner} when building using our internal Bamboo server.
     */
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (![bundleVersion isEqualToString:@"dev"])
    {
        // HockeyApp SDK
        if (HOCKEYAPP_APPID.length > 0)
        {
            [[BITHockeyManager sharedHockeyManager] configureWithIdentifier:HOCKEYAPP_APPID];
            [[BITHockeyManager sharedHockeyManager] startManager];
            [[BITHockeyManager sharedHockeyManager].authenticator authenticateInstallation];
        }
        
        // Flurry Analytics
        if (FLURRY_API_KEY.length > 0)
        {
            [[AnalyticsManager sharedManager] startAnalytics];
        }
    }
    
    // Migrate any old accounts if required
    [MigrationAssistant runMigrationAssistant];
    
    BOOL isFirstLaunch = [self isAppFirstLaunch];
    if (isFirstLaunch)
    {
        [[AccountManager sharedManager] removeAllAccounts];
        [self updateAppFirstLaunchFlag];
    }
    
    // Setup the app and build it's UI
    self.window.rootViewController = [self buildMainAppUIWithSession:nil displayingMainMenu:isFirstLaunch];
    self.window.tintColor = [UIColor appTintColor];
    
    // Clean up cache
    self.cacheHelper = [[CoreDataCacheHelper alloc] init];
    [self.cacheHelper removeAllCachedDataOlderThanNumberOfDays:@(kNumberOfDaysToKeepCachedData)];
    
    // Register the delegate for session updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    
    // Make the window visible
    [self.window makeKeyAndVisible];
    
    // If there is a selected Account, attempt login
    AccountManager *accountManager = [AccountManager sharedManager];
    if (accountManager.selectedAccount)
    {
        // Delay to allow the UI to update - reachability check can block the main thread
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [[LoginManager sharedManager] attemptLoginToAccount:accountManager.selectedAccount networkId:accountManager.selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                if (!successful)
                {
                    displayErrorMessage([ErrorDescriptions descriptionForError:error]);
                }
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
            }];
        });
    }

    [AppConfigurationManager sharedManager];
    
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

- (UIViewController *)buildMainAppUIWithSession:(id<AlfrescoSession>)session displayingMainMenu:(BOOL)displayMainMenu
{
    RootRevealControllerViewController *rootRevealViewController = nil;
    
    AccountsViewController *accountsViewController = [[AccountsViewController alloc] initWithSession:session];
    NavigationViewController *accountsNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountsViewController];
    MainMenuItem *accountsItem = [[MainMenuItem alloc] initWithControllerType:MainMenuTypeAccounts
                                                                    imageName:@"mainmenu-accounts.png"
                                                            localizedTitleKey:@"accounts.title"
                                                               viewController:accountsNavigationController
                                                              displayInDetail:NO];
    
    SwitchViewController *switchController = [[SwitchViewController alloc] initWithInitialViewController:accountsNavigationController];
    
    MainMenuViewController *mainMenuController = [[MainMenuViewController alloc] initWithAccountsSectionItems:@[accountsItem]];
    mainMenuController.delegate = switchController;
    self.mainMenuViewController = mainMenuController;
    
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
    
    // Expand the main menu if required
    if (displayMainMenu)
    {
        [rootRevealViewController expandViewController];
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
