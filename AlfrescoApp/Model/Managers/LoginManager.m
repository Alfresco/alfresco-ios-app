//
//  LoginManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AppDelegate.h"
#import "UniversalDevice.h"
#import "LoginManager.h"
#import "Utility.h"
#import "LoginViewController.h"
#import "NavigationViewController.h"
#import "MBProgressHUD.h"
#import "ConnectivityManager.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "NavigationViewController.h"
#import "AccountInfoViewController.h"

@interface LoginManager()

@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) __block NSString *currentLoginURLString;
@property (nonatomic, strong) __block AlfrescoRequest *currentLoginRequest;
@property (nonatomic, strong) AlfrescoOAuthLoginViewController *loginController;
@property (nonatomic, copy) void (^authenticationCompletionBlock)(BOOL success, id<AlfrescoSession> alfrescoSession, NSError *error);
@end

@implementation LoginManager

#pragma mark - Public Functions

+ (id)sharedManager
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
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(unauthorizedAccessNotificationReceived:)
                                                     name:kAlfrescoAccessDeniedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(appPolicyUpdated:)
                                                     name:kAlfrescoApplicationPolicyUpdatedNotification
                                                   object:nil];
    }
    return self;
}

- (void)attemptLoginToAccount:(UserAccount *)account networkId:(NSString *)networkId completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock
{
    self.authenticationCompletionBlock = ^(BOOL successful, id<AlfrescoSession> session, NSError *error)
    {
        if (loginCompletionBlock != NULL)
        {
            loginCompletionBlock(successful, session, error);
        }
    };
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
        [self showHUDOnView:delegate.window];
        
        if (account.accountType == UserAccountTypeOnPremise)
        {
            if (!account.password || [account.password isEqualToString:@""])
            {
                [self hideHUD];
                [self displayLoginViewControllerWithAccount:account username:account.username];
                self.authenticationCompletionBlock(NO, nil, nil);
                return;
            }
            
            
            [self authenticateOnPremiseAccount:account password:account.password completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *error) {
                [self hideHUD];
                if (!successful && error.code != kAlfrescoErrorCodeNetworkRequestCancelled)
                {
                    [self displayLoginViewControllerWithAccount:account username:account.username];
                }
                self.authenticationCompletionBlock(successful, session, error);
            }];
        }
        else
        {
            [self authenticateCloudAccount:account networkId:networkId navigationConroller:nil completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *error) {
                [self hideHUD];
                loginCompletionBlock(successful, session, error);
            }];
        }
    }
    else
    {
        NSString *messageTitle = NSLocalizedString(@"error.no.internet.access.title", @"No Internet Error Title");
        NSString *messageBody = NSLocalizedString(@"error.no.internet.access.message", @"No Internet Error Message");
        displayErrorMessageWithTitle(messageBody, messageTitle);
        self.authenticationCompletionBlock(NO, nil, nil);
    }
}

#pragma mark - Cloud authentication Methods

- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
             navigationConroller:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock
{
    self.authenticationCompletionBlock = authenticationCompletionBlock;
    void (^authenticationComplete)(id<AlfrescoSession>, NSError *error) = ^(id<AlfrescoSession> session, NSError *error) {
        if (!session)
        {
            if (authenticationCompletionBlock != NULL)
            {
                authenticationCompletionBlock(NO, session, error);
            }
        }
        else
        {
            [(AlfrescoCloudSession *)session retrieveNetworksWithCompletionBlock:^(NSArray *networks, NSError *error) {
                
                if (networks && error == nil)
                {
                    NSMutableArray *sortedNetworks = [NSMutableArray array];
                    for (AlfrescoCloudNetwork *network in networks)
                    {
                        NSInteger index = 0;
                        if (!network.isHomeNetwork)
                        {
                            NSComparator comparator = ^(NSString *network1, NSString *network2)
                            {
                                return (NSComparisonResult)[network1 caseInsensitiveCompare:network2];
                            };
                            index = [sortedNetworks indexOfObject:network.identifier inSortedRange:NSMakeRange(0, sortedNetworks.count) options:NSBinarySearchingInsertionIndex usingComparator:comparator];
                        }
                        [sortedNetworks insertObject:network.identifier atIndex:index];
                    }
                    account.accountNetworks = sortedNetworks;
                    
                    if (authenticationCompletionBlock != NULL)
                    {
                        authenticationCompletionBlock(YES, session, error);
                    }
                }
                else
                {
                    if (authenticationCompletionBlock != NULL)
                    {
                        authenticationCompletionBlock(NO, nil, error);
                    }
                }
            }];
        }
    };
    
    AlfrescoOAuthLoginViewController * (^showOAuthLoginViewController)(void) = ^AlfrescoOAuthLoginViewController * (void) {
        NavigationViewController *oauthNavigationController = nil;
        AlfrescoOAuthLoginViewController *oauthLoginController =  [[AlfrescoOAuthLoginViewController alloc] initWithAPIKey:ALFRESCO_CLOUD_OAUTH_KEY secretKey:ALFRESCO_CLOUD_OAUTH_SECRET completionBlock:^(AlfrescoOAuthData *oauthData, NSError *error) {
            
            if (oauthData)
            {
                account.oauthData = oauthData;
                
                [self connectWithOAuthData:oauthData networkId:networkId completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                    if (navigationController)
                    {
                        [navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        [self.loginController dismissViewControllerAnimated:YES completion:nil];
                    }
                    
                    authenticationComplete(session, error);
                }];
            }
            else
            {
                authenticationComplete(nil, error);
            }
        }];
        
        if (navigationController)
        {
            [navigationController pushViewController:oauthLoginController animated:YES];
        }
        else
        {
            oauthNavigationController = [[NavigationViewController alloc] initWithRootViewController:oauthLoginController];
            UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                    target:self
                                                                                    action:@selector(cancelCloudAuthentication:)];
            oauthLoginController.navigationItem.leftBarButtonItem = cancel;
            oauthNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [UniversalDevice displayModalViewController:oauthNavigationController onController:appDelegate.window.rootViewController withCompletionBlock:nil];
        }
        return oauthLoginController;
    };
    
    if (account.oauthData)
    {
        [self connectWithOAuthData:account.oauthData networkId:networkId completionBlock:^(id<AlfrescoSession> cloudSession, NSError *connectionError) {
            [navigationController popViewControllerAnimated:YES];
            if (nil == cloudSession)
            {
                if (connectionError.code == kAlfrescoErrorCodeAccessTokenExpired)
                {
                    // refresh token
                    AlfrescoOAuthHelper *oauthHelper = [[AlfrescoOAuthHelper alloc] initWithParameters:nil delegate:self];
                    [oauthHelper refreshAccessToken:account.oauthData completionBlock:^(AlfrescoOAuthData *refreshedOAuthData, NSError *refreshError) {
                        if (nil == refreshedOAuthData)
                        {
                            // if refresh token is expired or invalid present OAuth LoginView
                            if (refreshError.code == kAlfrescoErrorCodeRefreshTokenExpired || refreshError.code == kAlfrescoErrorCodeRefreshTokenInvalid)
                            {
                                self.loginController = showOAuthLoginViewController();
                                self.loginController.oauthDelegate = self;
                            }
                            authenticationComplete(nil, refreshError);
                        }
                        else
                        {
                            account.oauthData = refreshedOAuthData;
                            [[AccountManager sharedManager] saveAccountsToKeychain];
                            
                            // try to connect once OAuthData is refreshed
                            [self connectWithOAuthData:refreshedOAuthData networkId:networkId completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                                authenticationComplete(session, refreshError);
                            }];
                        }
                    }];
                }
                else
                {
                    authenticationComplete(nil, connectionError);
                }
            }
            else
            {
                authenticationComplete(cloudSession, connectionError);
            }
        }];
    }
    else
    {
        self.loginController = showOAuthLoginViewController();
        self.loginController.oauthDelegate = self;
    }
}

- (void)connectWithOAuthData:(AlfrescoOAuthData *)oauthData networkId:(NSString *)networkId completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    if (networkId)
    {
        [AlfrescoCloudSession connectWithOAuthData:oauthData networkIdentifer:networkId completionBlock:completionBlock];
    }
    else
    {
        [AlfrescoCloudSession connectWithOAuthData:oauthData completionBlock:completionBlock];
    }
}

- (void)cancelCloudAuthentication:(id)sender
{
    [self.loginController dismissViewControllerAnimated:YES completion:^{
        if (self.authenticationCompletionBlock != NULL)
        {
            self.authenticationCompletionBlock(NO, nil, nil);
        }
    }];
}

#pragma mark - OAuth delegate
- (void)oauthLoginDidFailWithError:(NSError *)error
{
    AlfrescoLogDebug(@"OAuth Failed");
}

#pragma mark - Private Functions

- (void)displayLoginViewControllerWithAccount:(UserAccount *)account username:(NSString *)username
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithAccount:account delegate:self];
    NavigationViewController *loginNavigationController = [[NavigationViewController alloc] initWithRootViewController:loginViewController];
    
    [UniversalDevice displayModalViewController:loginNavigationController onController:appDelegate.window.rootViewController withCompletionBlock:nil];
}

- (void)authenticateOnPremiseAccount:(UserAccount *)account password:(NSString *)password completionBlock:(LoginAuthenticationCompletionBlock)completionBlock
{
    NSDictionary *sessionParameters = [@{kAlfrescoMetadataExtraction : @YES,
                                         kAlfrescoThumbnailCreation : @YES} mutableCopy];
    if (account.accountCertificate)
    {
        NSURLCredential *certificateCredential = [NSURLCredential credentialWithIdentity:account.accountCertificate.identityRef
                                                                            certificates:account.accountCertificate.certificateChain
                                                                             persistence:NSURLCredentialPersistenceForSession];
        sessionParameters = @{kAlfrescoMetadataExtraction : @YES,
                              kAlfrescoThumbnailCreation : @YES,
                              kAlfrescoConnectUsingClientSSLCertificate : @YES,
                              kAlfrescoClientCertificateCredentials : certificateCredential};
    }
    
    BOOL hostIsReachable = [[ConnectivityManager sharedManager] canReachHostName:account.serverAddress];
    if (hostIsReachable)
    {
        self.currentLoginURLString = [Utility serverURLStringFromAccount:account];
        self.currentLoginRequest = [AlfrescoRepositorySession connectWithUrl:[NSURL URLWithString:self.currentLoginURLString] username:account.username password:password parameters:sessionParameters completionBlock:^(id<AlfrescoSession> session, NSError *error) {
            if (session)
            {
                [UniversalDevice clearDetailViewController];
                
                self.currentLoginURLString = nil;
                self.currentLoginRequest = nil;
                
                if (completionBlock != NULL)
                {
                    completionBlock(YES, session, nil);
                }
            }
            else
            {
                if (completionBlock != NULL)
                {
                    completionBlock(NO, nil, error);
                }
            }
        }];
    }
    else
    {
        [self hideHUD];
        AccountInfoViewController *accountViewController = [[AccountInfoViewController alloc] initWithAccount:account accountActivityType:AccountActivityTypeLoginFailed];
        NavigationViewController *nav = [[NavigationViewController alloc] initWithRootViewController:accountViewController];
        [UniversalDevice displayModalViewController:nav onController:[UniversalDevice containerViewController] withCompletionBlock:^{
            displayErrorMessageWithTitle(NSLocalizedString(@"login.host.unreachable.message", @"Connect VPN. Check account."), NSLocalizedString(@"login.host.unreachable.title", @"Connection error"));
        }];
    }
}

- (void)showHUDOnView:(UIView *)view
{
    MBProgressHUD *progress = [[MBProgressHUD alloc] initWithView:view];
    progress.labelText = NSLocalizedString(@"login.hud.label", @"Connecting...");
    progress.detailsLabelText = NSLocalizedString(@"login.hud.cancel.label", @"Tap To Cancel");
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedCancelLoginRequest:)];
    tap.numberOfTapsRequired = 1;
    tap.numberOfTouchesRequired = 1;
    [progress addGestureRecognizer:tap];
    
    [view addSubview:progress];
    [progress show:YES];
    
    self.progressHUD = progress;
}

- (void)tappedCancelLoginRequest:(UIGestureRecognizer *)gesture
{
    [self cancelLoginRequest];
}

- (void)hideHUD
{
    [self.progressHUD hide:YES];
    self.progressHUD = nil;
}

- (void)unauthorizedAccessNotificationReceived:(NSNotification *)notification
{
    // try logging again
    UserAccount *selectedAccount = [AccountManager sharedManager].selectedAccount;
    [self attemptLoginToAccount:selectedAccount networkId:selectedAccount.selectedNetworkId completionBlock:nil];
}

- (void)cancelLoginRequest
{
    [self hideHUD];
    [self.currentLoginRequest cancel];
    self.currentLoginRequest = nil;
    self.currentLoginURLString = nil;
}

#pragma mark - LoginViewControllerDelegate Functions

- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToAccount:(UserAccount *)account username:(NSString *)username password:(NSString *)password
{
    [self showHUDOnView:loginViewController.view];
    [self authenticateOnPremiseAccount:account password:(NSString *)password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        [self hideHUD];
        if (successful)
        {
            account.password = password;
            [[AccountManager sharedManager] saveAccountsToKeychain];
            if (self.authenticationCompletionBlock != NULL)
            {
                self.authenticationCompletionBlock(YES, alfrescoSession, error);
            }
            [loginViewController dismissViewControllerAnimated:YES completion:nil];
        }
        else
        {
            [loginViewController updateUIForFailedLogin];
            displayErrorMessage(NSLocalizedString(@"error.login.failed", @"Login Failed Message"));
        }
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
    }];
}

@end
