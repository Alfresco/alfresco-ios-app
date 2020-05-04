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
#import "UniversalDevice.h"
#import "LoginManager.h"
#import "LoginViewController.h"
#import "NavigationViewController.h"
#import "ConnectivityManager.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "NavigationViewController.h"
#import "LoginManagerCore.h"
#import "AlfrescoApp-Swift.h"

@interface LoginManager()
@property (nonatomic, strong) MBProgressHUD     *progressHUD;
@property (nonatomic, strong) LoginManagerCore  *loginCore;
@property (nonatomic, strong) AIMSLoginService  *aimsLoginService;

@property (nonatomic, strong) AlfrescoOAuthUILoginViewController *loginController;
@property (nonatomic, strong) AlfrescoSAMLUILoginViewController *samlLoginController;
@property (nonatomic, assign) BOOL didCancelLogin;
@property (nonatomic, assign) BOOL completionBlockCalledFromLoginViewController;

@end

@implementation LoginManager

+ (LoginManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static LoginManager *sharedLoginManager = nil;
    dispatch_once(&onceToken, ^{
        sharedLoginManager = [[self alloc] init];
    });
    return sharedLoginManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _loginCore = [LoginManagerCore new];
        _loginCore.delegate = self;
        _aimsLoginService = [AIMSLoginService new];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unauthorizedAccessNotificationReceived:) name:kAlfrescoAccessDeniedNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(unauthorizedAccessNotificationReceived:) name:kAlfrescoTokenExpiredNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityChanged:) name:kAlfrescoConnectivityChangedNotification object:nil];
    }
    return self;
}

- (BOOL)sessionExpired {
    return _loginCore.sessionExpired;
}

#pragma mark - Public interface

- (void)attemptLoginToAccount:(UserAccount *)account networkId:(NSString *)networkId
              completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock
{
    [self.aimsLoginService updateWith:account];
    [self.loginCore attemptLoginToAccount:account
                                networkId:networkId
                          completionBlock:loginCompletionBlock];
}

- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
            navigationController:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock {
    [self.loginCore authenticateCloudAccount:account
                                   networkId:networkId
                        navigationController:navigationController
                             completionBlock:authenticationCompletionBlock];
}

- (void)authenticateWithSAMLOnPremiseAccount:(UserAccount *)account
                        navigationController:(UINavigationController *)navigationController
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock {
    [self.loginCore authenticateWithSAMLOnPremiseAccount:account
                                    navigationController:navigationController
                                         completionBlock:authenticationCompletionBlock];
}

- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock {
    [self.loginCore authenticateOnPremiseAccount:account
                                        password:password
                                 completionBlock:completionBlock];
}

- (void)showSAMLWebViewForAccount:(UserAccount *)account
             navigationController:(UINavigationController *)navigationController
                  completionBlock:(AlfrescoSAMLAuthCompletionBlock)completionBlock {
    [self.loginCore showSAMLWebViewForAccount:account
                         navigationController:navigationController
                              completionBlock:completionBlock];
}

- (void)authenticateWithAIMSOnPremiseAccount:(UserAccount *)account
                             completionBlock:(LoginAuthenticationCompletionBlock)completionBlock
{
    [self.loginCore authenticateWithAIMSOnPremiseAccount:account
                                         completionBlock:completionBlock];
}

- (void)showAIMSWebviewForAccount:(UserAccount *)account
navigationController:(UINavigationController *)navigationController
                  completionBlock:(LoginAIMSCompletionBlock)completionBlock
{
    [self.aimsLoginService updateWith:account];
    [self.aimsLoginService loginOnViewController:navigationController
                                 completionBlock:completionBlock];
}

- (void)showLogOutAIMSWebviewForAccount:(UserAccount *)account
navigationController:(UINavigationController *)navigationController
                        completionBlock:(LogoutAIMSCompletionBlock)completionBlock {
    [self.aimsLoginService updateWith:account];
    [self.loginCore cancelAIMSActiveSessionRefreshTask];
    [self.aimsLoginService logoutOnViewController:navigationController
                                  completionBlock:completionBlock];
}

- (void)saveInKeychainAIMSDataForAccount:(UserAccount *)account {
    [self.aimsLoginService updateWith:account];
    [self.aimsLoginService saveInKeychain];
}

- (void)availableAuthTypeForAccount:(UserAccount *)account
                    completionBlock:(AvailableAuthenticationTypeCompletionBlock)completionBlock
{
    [self.aimsLoginService availableAuthTypeForAccount:account
                                       completionBlock:completionBlock];
}

- (void)cancelActiveSessionRefreshTasks
{
    [self.loginCore cancelAIMSActiveSessionRefreshTask];
}

#pragma mark - LoginViewControllerDelegate Functions

- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToAccount:(UserAccount *)account username:(NSString *)username password:(NSString *)password
{
    [self showHUDOnView:loginViewController.view];
    
    __weak typeof(self) weakSelf = self;
    [self.loginCore authenticateOnPremiseAccount:account
                                        username:username
                                        password:password
                                 completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                     __strong typeof(self) strongSelf = weakSelf;
                                     
                                     [strongSelf hideHUD];
                                     
                                     if (successful)
                                     {
                                         strongSelf.loginCore.sessionExpired = NO;
                                         
                                         account.username = username;
                                         account.password = password;
                                         
                                         [[AccountManager sharedManager] saveAccountsToKeychain];
                                         
                                         
                                         if (self.loginCore.authenticationCompletionBlock != NULL)
                                         {
                                             self.completionBlockCalledFromLoginViewController = YES;
                                             self.loginCore.authenticationCompletionBlock(YES, alfrescoSession, error);
                                         }
                                         
                                         [loginViewController dismissViewControllerAnimated:YES
                                                                                 completion:nil];
                                         
                                         [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification
                                                                                             object:alfrescoSession
                                                                                           userInfo:nil];
                                     }
                                     else
                                     {
                                         [loginViewController updateUIForFailedLogin];
                                         displayErrorMessage([ErrorDescriptions descriptionForError:error]);
                                     }
    }];
}

#pragma mark - LoginManagerCoreProtocol

- (void)showSAMLLoginViewController:(AlfrescoSAMLUILoginViewController *)viewController
             inNavigationController:(UINavigationController *)navigationController {
    if (navigationController)
    {
        [navigationController pushViewController:viewController animated:YES];
    }
    else
    {
        navigationController = [[NavigationViewController alloc] initWithRootViewController:viewController];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self.loginCore
                                                                                action:@selector(cancelSamlAuthentication)];
        viewController.navigationItem.leftBarButtonItem = cancel;
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        self.samlLoginController = viewController;
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [UniversalDevice displayModalViewController:navigationController
                                       onController:appDelegate.window.rootViewController
                                withCompletionBlock:nil];
    }
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewAccountSAML];
}

- (void)showOauthLoginController:(AlfrescoOAuthUILoginViewController *)viewController
          inNavigationController:(UINavigationController *)navigationController {
    if (navigationController)
    {
        [navigationController pushViewController:viewController
                                        animated:YES];
    }
    else
    {
        NavigationViewController *oauthNavigationController =  [[NavigationViewController alloc] initWithRootViewController:viewController];
        UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self.loginCore
                                                                                action:@selector(cancelCloudAuthentication)];
        viewController.navigationItem.leftBarButtonItem = cancel;
        viewController.modalPresentationStyle = UIModalPresentationFormSheet;
        
        AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [UniversalDevice displayModalViewController:oauthNavigationController
                                       onController:appDelegate.window.rootViewController
                                withCompletionBlock:nil];
    }
}

- (void)showSignInAlertWithSignedInBlock:(void (^)(void))completionBlock
{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"error.host.unreachable.title", @"Connection Error")
                                                                             message:NSLocalizedString(@"error.session.expired", @"Your session has expired. Sign in to continue.")
                                                                      preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *signInAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"login.sign.in", @"Sign In")
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * _Nonnull action) {
        if (completionBlock)
        {
            completionBlock();
        }
    }];
    
    [alertController addAction:signInAction];
    
    UIAlertAction *okAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"OK", @"OK")
                                                       style:UIAlertActionStyleCancel
                                                     handler:^(UIAlertAction * _Nonnull action) {
        [alertController dismissViewControllerAnimated:YES
                                            completion:nil];
    }];
    
    [alertController addAction:okAction];
    
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [UniversalDevice displayModalViewController:alertController
                                   onController:appDelegate.window.rootViewController
                            withCompletionBlock:nil];
}

- (void)displayLoginViewControllerWithAccount:(UserAccount *)account
                                     username:(NSString *)username
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithAccount:account delegate:self];
    NavigationViewController *loginNavigationController = [[NavigationViewController alloc] initWithRootViewController:loginViewController];
    
    [UniversalDevice displayModalViewController:loginNavigationController onController:appDelegate.window.rootViewController withCompletionBlock:nil];
}

- (void)willBeginVisualAuthenticationProgress {
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    [self showHUDOnView:delegate.window];
}

- (void)willEndVisualAuthenticationProgress
{
    [self hideHUD];
}

- (void)clearDetailViewController
{
    [UniversalDevice clearDetailViewController];
}

- (void)trackAnalyticsEventWithCategory:(NSString *)eventCategory
                                 action:(NSString *)eventAction
                                  label:(NSString *)eventLabel
                                  value:(NSNumber *)value
{
    [[AnalyticsManager sharedManager] trackEventWithCategory:eventCategory
                                                      action:eventAction
                                                       label:eventLabel
                                                       value:value];
}

- (void)trackAnalyticsScreenWithName:(NSString *)screenName {
    [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
}

- (void)refreshSessionForAccount:(UserAccount *)account
                 completionBlock:(LoginAIMSCompletionBlock)completionBlock
{
    [self.aimsLoginService refreshSessionFor:account
                             completionBlock:completionBlock];
}

- (void)disableAutoSelectMenuOption
{
    AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    delegate.mainMenuViewController.autoselectDefaultMenuOption = NO;
}

#pragma mark - Private Functions

- (void)showHUDOnView:(UIView *)view
{
    MBProgressHUD *progress = [[MBProgressHUD alloc] initWithView:view];
    progress.removeFromSuperViewOnHide = YES;
    progress.label.text = NSLocalizedString(@"login.hud.label", @"Connecting...");
    progress.detailsLabel.text = NSLocalizedString(@"login.hud.cancel.label", @"Tap To Cancel");
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self
                                                                          action:@selector(tappedCancelLoginRequest:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [progress addGestureRecognizer:tap];
    
    [view addSubview:progress];
    [progress showAnimated:YES];
    
    if (self.progressHUD)
    {
        [self.progressHUD removeFromSuperview];
        self.progressHUD = nil;
    }
    
    self.progressHUD = progress;
}

- (void)tappedCancelLoginRequest:(UIGestureRecognizer *)gesture
{
    [self.loginCore cancelLoginRequest];
}

- (void)hideHUD
{
    [self.progressHUD hideAnimated:YES];
    self.progressHUD = nil;
}

- (void)unauthorizedAccessNotificationReceived:(NSNotification *)notification
{
    // try logging again
    UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
    [self attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
}

- (void)reachabilityChanged:(NSNotification *)notification
{
    BOOL hasInternetConnection = [[ConnectivityManager sharedManager] hasInternetConnection];
    if(hasInternetConnection)
    {
        UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
        
        __weak typeof(self) weakSelf = self;
        [self attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            
            if(successful && !strongSelf.completionBlockCalledFromLoginViewController)
            {
                [strongSelf disableAutoSelectMenuOption];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification
                                                                    object:alfrescoSession
                                                                  userInfo:nil];
            }
            else if (strongSelf.completionBlockCalledFromLoginViewController)
            {
                strongSelf.completionBlockCalledFromLoginViewController = NO;
            }
        }];
    }
}

@end
