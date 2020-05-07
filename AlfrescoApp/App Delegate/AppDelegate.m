/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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
#import "AccountManager.h"
#import "RootRevealViewController.h"
#import "SwitchViewController.h"
#import "OnboardingViewController.h"
#import "ContainerViewController.h"
#import "MigrationAssistant.h"
#import "AnalyticsManager.h"
#import "CoreDataCacheHelper.h"
#import "FileHandlerManager.h"
#import "PreferenceManager.h"
#import "ModalRotation.h"
#import "MDMUserDefaultsConfigurationHelper.h"
#import "MDMLaunchViewController.h"
#import "NSDictionary+Extension.h"
#import "UniversalDevice.h"
#import "MainMenuLocalConfigurationBuilder.h"
#import "SecurityManager.h"
#import "UnderlayViewController.h"
#import "RealmSyncManager+CoreDataMigration.h"
#import "RealmSyncCore.h"
#import "AppConfigurationManager.h"
@import Firebase;

@import MediaPlayer;

static NSString * const kMDMMissingRequiredKeysKey = @"MDMMissingKeysKey";

@interface AppDelegate() <AccountPickerPresentationDelegate>

@property (nonatomic, strong) UIViewController *appRootViewController;
@property (nonatomic, strong) CoreDataCacheHelper *cacheHelper;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) MainMenuConfigurationViewController *mainMenuViewController;
@property (nonatomic, strong) MDMUserDefaultsConfigurationHelper *appleConfigurationHelper;
@property (nonatomic, strong) MDMUserDefaultsConfigurationHelper *mobileIronConfigurationHelper;

@end

@implementation AppDelegate

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.appleConfigurationHelper = [[MDMUserDefaultsConfigurationHelper alloc] initWithConfigurationKey:kAppleManagedConfigurationKey];
        self.mobileIronConfigurationHelper = [[MDMUserDefaultsConfigurationHelper alloc] initWithConfigurationKey:kMobileIronManagedConfigurationKey];
    }
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    /**
     * Functionality that won't be available unless you have other valid keys are:
     * - HockeyApp SDK integration. Requires "HOCKEYAPP_APPID"
     * - Flurry Analytics. Requires "FLURRY_API_KEY"
     * - Google Quickoffice Save Back. Requires "QUICKOFFICE_PARTNER_KEY"
     * - Google Analytics. Requires "GA_API_KEY"
     *
     */
    
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    /**
     * Note: CFBundleVersion is updated for AdHoc builds by calling the tools/set_build_number.sh script (configured in the build pre-action).
     * The script updates CFBundleVersion from a CF_BUNDLE_VERSION environment variable which we have configured at Alfresco
     * to be set to ${bamboo.buildNumner} when building using our internal Bamboo server.
     */
    NSString *bundleVersion = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    if (![bundleVersion isEqualToString:@"dev"])
    {
        [[AnalyticsManager sharedManager] startAnalytics];
    }
    
    BOOL safeMode = [[[PreferenceManager sharedManager] settingsPreferenceForIdentifier:kSettingsBundlePreferenceSafeModeKey] boolValue];
    
    if (!safeMode)
    {
        // Migrate any old accounts if required
        [MigrationAssistant runMigrationAssistant];
    }
    
    AccountManager *accountManager = [AccountManager sharedManager];
    accountManager.realmManager = [RealmManager sharedManager];
    accountManager.appConfigurationManager = [AppConfigurationManager sharedManager];
    accountManager.analyticsManager = [AnalyticsManager sharedManager];
    
    BOOL isFirstLaunch = [self isAppFirstLaunch];
    if (isFirstLaunch)
    {
        if (!safeMode)
        {
            [[AccountManager sharedManager] removeAllAccounts];
            [SecurityManager reset];
        }
        [self updateAppFirstLaunchFlag];
    }
    
    [MigrationAssistant runDownloadsMigration];
    
    if([[RealmSyncManager sharedManager] isCoreDataMigrationNeeded])
    {
        [[RealmSyncManager sharedManager] initiateMigrationProcess];
    }
    
    if ([[RealmSyncCore sharedSyncCore] isContentMigrationNeeded])
    {
        [[RealmSyncCore sharedSyncCore] initiateContentMigrationProcessForAccounts:[AccountManager sharedManager].allAccounts];
    }

    // Setup the app and build it's UI
    self.window.rootViewController = [self buildMainAppUIWithSession:nil displayingMainMenu:isFirstLaunch];
    self.window.tintColor = [UIColor appTintColor];
    
    [[SecurityManager sharedManager] setup];
    
    // Clean up cache
    self.cacheHelper = [[CoreDataCacheHelper alloc] init];
    [self.cacheHelper removeAllCachedDataOlderThanNumberOfDays:@(kNumberOfDaysToKeepCachedData)];
    
    // Register the delegate for session updates
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionReceivedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(sessionReceived:) name:kAlfrescoSessionRefreshedNotification object:nil];
    
    if ([[PreferenceManager sharedManager] shouldUsePasscodeLock] == NO)
    {
        // Make the window visible
        [self.window makeKeyAndVisible];
    }
    
    if (!safeMode)
    {
        // If there is a selected Account, attempt login
        AccountManager *accountManager = [AccountManager sharedManager];
        [accountManager removeCloudAccounts];
        if (accountManager.selectedAccount)
        {
            // Delay to allow the UI to update - reachability check can block the main thread
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [[LoginManager sharedManager] attemptLoginToAccount:accountManager.selectedAccount networkId:accountManager.selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                    if (!successful)
                    {
                        if (UserAccountTypeAIMS != accountManager.selectedAccount.accountType) {
                            if (accountManager.selectedAccount.password.length > 0)
                            {
                                displayErrorMessage([ErrorDescriptions descriptionForError:error]);
                            }
                            else
                            {
                                // Missing details - possibly first launch of an MDM-configured account
                                if ([accountManager.selectedAccount.username length] == 0)
                                {
                                    displayWarningMessageWithTitle(NSLocalizedString(@"accountdetails.fields.accountSettings", @"Enter user name and password"), NSLocalizedString(@"accountdetails.header.authentication", "Account Details"));
                                }
                                else
                                {
                                    displayWarningMessageWithTitle(NSLocalizedString(@"accountdetails.fields.confirmPassword", @"Confirm password"), NSLocalizedString(@"accountdetails.header.authentication", "Account Details"));
                                }
                            }
                        }
                    } else {
                        // TODO: assess whether to handle this for all calls
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
                    }
                    
                    if ([launchOptions objectForKey:UIApplicationLaunchOptionsURLKey])
                    {
                        NSURL *url = [launchOptions objectForKey:UIApplicationLaunchOptionsURLKey];
                        [[FileHandlerManager sharedManager] handleURL:url sourceApplication:nil annotation:nil session:alfrescoSession];
                        self.mainMenuViewController.autoselectDefaultMenuOption = NO;
                    }
                }];
            });
        }
    }
    
    if (safeMode)
    {
        // Switch safe mode off
        [[PreferenceManager sharedManager] updateSettingsPreferenceToValue:@NO preferenceIdentifier:kSettingsBundlePreferenceSafeModeKey];
    }
    
    return YES;
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey, id> *)options
{
    NSString *sourceApplication = options[UIApplicationOpenURLOptionsSourceApplicationKey];
    NSString *annotation = options[UIApplicationOpenURLOptionsAnnotationKey];
    return [[FileHandlerManager sharedManager] handleURL:url sourceApplication:sourceApplication annotation:annotation session:self.session];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [[AccountManager sharedManager] saveAccountsToKeychain];
}

- (UIInterfaceOrientationMask)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
    // default is to support all orientations
    UIInterfaceOrientationMask supportedOrientations = UIInterfaceOrientationMaskAll;
    
    if (!IS_IPAD)
    {
        // iPhones and iPods only support portrait by default
        supportedOrientations = UIInterfaceOrientationMaskPortrait;
        
        // unless content is being displayed modally
        UIViewController *modalViewController = self.window.rootViewController.presentedViewController;
        if (modalViewController)
        {
            if ([modalViewController isKindOfClass:[NavigationViewController class]])
            {
                NavigationViewController *navController = (NavigationViewController *)modalViewController;
                UIViewController *presentedController = navController.topViewController;
                
                if ([presentedController conformsToProtocol:@protocol(ModalRotation)])
                {
                    supportedOrientations = [presentedController supportedInterfaceOrientations];
                }
            }
            else
            {
                if ([modalViewController conformsToProtocol:@protocol(ModalRotation)])
                {
                    supportedOrientations = [modalViewController supportedInterfaceOrientations];
                }
            }
        }
    }
    
    return supportedOrientations;
}

#pragma mark - Private Functions

- (UIViewController *)buildMainAppUIWithSession:(id<AlfrescoSession>)session displayingMainMenu:(BOOL)displayMainMenu
{
    RootRevealViewController *rootRevealViewController = nil;
    
    BOOL isManaged = self.appleConfigurationHelper.isManaged || self.mobileIronConfigurationHelper.isManaged;
    
    // This is currently set to a dictionary that is passed around with appropiate values set.
    // This will probably require rework in the app to support server side configuration
    NSMutableDictionary *initialConfiguration = [NSMutableDictionary dictionary];
    
    if (isManaged)
    {
        [initialConfiguration setObject:@NO forKey:kAppConfigurationCanAddAccountsKey];
        [initialConfiguration setObject:@NO forKey:kAppConfigurationCanEditAccountsKey];
        [initialConfiguration setObject:@NO forKey:kAppConfigurationCanRemoveAccountsKey];
    }
    
    AccountsViewController *accountsViewController = [[AccountsViewController alloc] initWithConfiguration:initialConfiguration session:session];
    NavigationViewController *accountsNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountsViewController];
    accountsViewController.presentationPickerDelegate = self;
    
    SwitchViewController *switchController = [[SwitchViewController alloc] initWithInitialViewController:accountsNavigationController];
    
    // Main Menu Configuration
    MainMenuLocalConfigurationBuilder *menuBuilder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:[AccountManager sharedManager].selectedAccount session:self.session];
    menuBuilder.managedAccountConfiguration = initialConfiguration;
    MainMenuConfigurationViewController *mainMenuController = [[MainMenuConfigurationViewController alloc] initWithTitle:nil menuBuilder:menuBuilder delegate:switchController];
    mainMenuController.backgroundColour = [UIColor mainMenuBackgroundColor];
    mainMenuController.selectionColor = [UIColor appTintColor];
    
    self.mainMenuViewController = mainMenuController;
    
    rootRevealViewController = [[RootRevealViewController alloc] initWithMasterViewController:mainMenuController detailViewController:switchController];
    rootRevealViewController.delegate = (id<RootRevealViewControllerDelegate>)self.mainMenuViewController;
    
    if (IS_IPAD)
    {
        PlaceholderViewController *placeholderViewController = [[PlaceholderViewController alloc] init];
        NavigationViewController *detailNavigationController = [[NavigationViewController alloc] initWithRootViewController:placeholderViewController];
        
        DetailSplitViewController *splitViewController = [[DetailSplitViewController alloc] initWithMasterViewController:switchController detailViewController:detailNavigationController];
        
        rootRevealViewController.masterViewController = mainMenuController;
        rootRevealViewController.detailViewController = splitViewController;
    }
    
    NSUInteger numberOfAccountsSetup = [[AccountManager sharedManager] totalNumberOfAddedAccounts];
    
    if (isManaged)
    {
        NSDictionary *managedDictionary = (self.appleConfigurationHelper.isManaged) ? self.appleConfigurationHelper.rootManagedDictionary : self.mobileIronConfigurationHelper.rootManagedDictionary;
        
        [self configureManagedObjectWithDictionary:managedDictionary completionBlock:^(BOOL successful, BOOL addedAccount, UserAccount *configuredAccount, NSError *configurationError) {
            if (successful)
            {
                [[AccountManager sharedManager] selectAccount:configuredAccount selectNetwork:nil alfrescoSession:session];
            }
            else
            {
                NSArray *missingKeys = configurationError.userInfo[kMDMMissingRequiredKeysKey];
                MDMLaunchViewController *mdmLaunchViewController = [[MDMLaunchViewController alloc] initWithMissingMDMKeys:missingKeys];
                [rootRevealViewController addOverlayedViewController:mdmLaunchViewController];
            }
        }];
    }
    else if (numberOfAccountsSetup == 0)
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
    
    NSString *labelString = [[AnalyticsManager sharedManager] serverTypeStringForSession:self.session];
    
    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategorySession
                                                      action:kAnalyticsEventActionInfo
                                                       label:labelString
                                                       value:@1
                                                customMetric:AnalyticsMetricNone
                                                 metricValue:nil
                                                     session:self.session];
    
    if([[RealmSyncManager sharedManager] shouldShowSyncInfoPanel])
    {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"SyncRefactorInfoPanel" bundle:[NSBundle mainBundle]];
        UnderlayViewController *underlayViewController = (UnderlayViewController *)[storyboard instantiateViewControllerWithIdentifier:NSStringFromClass([UnderlayViewController class])];
        underlayViewController.view.alpha = 0.0;
        
        RootRevealViewController *rootRevealViewController = (RootRevealViewController *)[UniversalDevice revealViewController];
        if([rootRevealViewController hasOverlayController])
        {
            [rootRevealViewController removeOverlayedViewControllerWithAnimation:YES];
        }
        [rootRevealViewController addOverlayedViewController:underlayViewController];
        [UIView animateWithDuration:0.3f animations:^{
            underlayViewController.view.alpha = 1.0;
        } completion:nil];
    }
}

- (void)configureManagedObjectWithDictionary:(NSDictionary *)managedDictionary completionBlock:(void (^)(BOOL successful, BOOL addedAccount, UserAccount *configuredAccount, NSError *configurationError))completionBlock
{
    // Variables to pass through to the completionBlock
    BOOL isSuccessful = NO;
    BOOL didAddAccount = NO;
    UserAccount *userAccount = nil;
    NSError *configurationError = nil;
    
    NSUInteger numberOfAccountsSetup = [[AccountManager sharedManager] totalNumberOfAddedAccounts];
    
    NSArray *requiredKeys = @[kAlfrescoMDMRepositoryURLKey];
    NSArray *missingKeys = [managedDictionary findMissingKeysFromArray:requiredKeys];
    
    if (numberOfAccountsSetup == 0)
    {
        if (missingKeys.count == 0)
        {
            // Create a new account and add it to the keychain
            NSURL *serverURL = [NSURL URLWithString:managedDictionary[kAlfrescoMDMRepositoryURLKey]];
            
            userAccount = [[UserAccount alloc] initWithAccountType:UserAccountTypeOnPremise];
            userAccount.accountDescription = managedDictionary[kAlfrescoMDMDisplayNameKey];
            userAccount.serverAddress = serverURL.host;
            NSString *defaultPort = [serverURL.scheme caseInsensitiveCompare:kProtocolHTTPS] == NSOrderedSame ? kAlfrescoDefaultHTTPSPortString : kAlfrescoDefaultHTTPPortString;
            userAccount.serverPort = serverURL.port.stringValue ?: defaultPort;
            userAccount.protocol = serverURL.scheme;
            userAccount.serviceDocument = serverURL.path;
            userAccount.username = managedDictionary[kAlfrescoMDMUsernameKey];
            [[AccountManager sharedManager] addAccount:userAccount];
            
            isSuccessful = YES;
            didAddAccount = YES;
        }
        else
        {
            isSuccessful = NO;
            
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"mdm.missing.keys.description", @"Missing Keys Description"), missingKeys];
            configurationError = [NSError errorWithDomain:errorMessage code:-1 userInfo:@{kMDMMissingRequiredKeysKey : missingKeys}];
        }
    }
    else
    {
        if (missingKeys.count == 0)
        {
            // Grab the first account from the keychain
            userAccount = [[AccountManager sharedManager] allAccounts][0];

            // If the server address has changed then we assume username and password are now invalid
            NSURL *mdmServerURL = [NSURL URLWithString:managedDictionary[kAlfrescoMDMRepositoryURLKey]];
            if (![userAccount.serverAddress isEqualToString:mdmServerURL.host])
            {
                userAccount.serverAddress = mdmServerURL.host;
                userAccount.username = nil;
                userAccount.password = nil;
            }

            NSString *defaultPort = [mdmServerURL.scheme caseInsensitiveCompare:kProtocolHTTPS] == NSOrderedSame ? kAlfrescoDefaultHTTPSPortString : kAlfrescoDefaultHTTPPortString;
            userAccount.serverPort = mdmServerURL.port.stringValue ?: defaultPort;

            userAccount.protocol = mdmServerURL.scheme;
            userAccount.serviceDocument = mdmServerURL.path;

            NSString *mdmUsername = managedDictionary[kAlfrescoMDMUsernameKey];
            if (mdmUsername && ![userAccount.username isEqualToString:mdmUsername])
            {
                userAccount.username = mdmUsername;
                userAccount.password = nil;
            }
            
            isSuccessful = YES;
            didAddAccount = NO;
        }
        else
        {
            isSuccessful = NO;
            
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedString(@"mdm.missing.keys.description", @"Missing Keys Description"), missingKeys];
            configurationError = [NSError errorWithDomain:errorMessage code:-1 userInfo:@{kMDMMissingRequiredKeysKey : missingKeys}];
        }
    }
    
    if (completionBlock != NULL)
    {
        completionBlock(isSuccessful, didAddAccount, userAccount, configurationError);
    }
}

#pragma mark - MobileIron AppConnect Wrapping Method

- (NSString *)appConnectConfigChangedTo:(NSDictionary *)config
{
    __block NSString *configurationErrorString = nil;
    
    [self.mobileIronConfigurationHelper setManagedDictionary:config];
    
    RootRevealViewController *rootRevealController = (RootRevealViewController *)[UniversalDevice revealViewController];
    
    if ((rootRevealController.hasOverlayController) && ([rootRevealController.overlayedViewController isKindOfClass:[OnboardingViewController class]]))
    {
        [rootRevealController removeOverlayedViewControllerWithAnimation:NO];
    }
    
    [self configureManagedObjectWithDictionary:config completionBlock:^(BOOL successful, BOOL addedAccount, UserAccount *configuredAccount, NSError *configurationError) {
        if (successful)
        {
            // We need to notify the app to disable the account addition, modification and removal
            NSDictionary *accountConfiguration = @{kAppConfigurationCanAddAccountsKey : @NO,
                                                   kAppConfigurationCanEditAccountsKey : @NO,
                                                   kAppConfigurationCanRemoveAccountsKey : @NO};
            
            [[NSNotificationCenter defaultCenter] postNotificationName:kAppConfigurationAccountsConfigurationUpdatedNotification object:accountConfiguration];
            
            if (addedAccount)
            {
                // Login to the account after it has been configured
                [[LoginManager sharedManager] attemptLoginToAccount:configuredAccount networkId:nil completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                    if (successful)
                    {
                        [[AccountManager sharedManager] selectAccount:configuredAccount selectNetwork:nil alfrescoSession:nil];
                    }
                }];
            }
            else
            {
                [[AccountManager sharedManager] selectAccount:configuredAccount selectNetwork:nil alfrescoSession:nil];
            }
        }
        else
        {
            NSArray *missingKeys = configurationError.userInfo[kMDMMissingRequiredKeysKey];
            MDMLaunchViewController *mdmLaunchViewController = [[MDMLaunchViewController alloc] initWithMissingMDMKeys:missingKeys];
            [rootRevealController addOverlayedViewController:mdmLaunchViewController];
            
            configurationErrorString = configurationError.localizedDescription;
        }
    }];
    
    return configurationErrorString;
}

#pragma mark - AccountPickerPresentation Delegate

- (UIViewController *)accountPickerPresentationViewController
{
    return self.window.rootViewController;
}

@end
