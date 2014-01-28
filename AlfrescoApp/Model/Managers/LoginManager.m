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

@interface LoginManager()

@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) __block NSString *currentLoginURLString;
@property (nonatomic, strong) __block AlfrescoRequest *currentLoginRequest;
@property (nonatomic, strong) AlfrescoOAuthLoginViewController *loginController;
@property (nonatomic, copy) void (^authenticationCompletionBlock)(BOOL success, id<AlfrescoSession> alfrescoSession);
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

- (void)attemptLoginToAccount:(UserAccount *)account networkId:(NSString *)networkId completionBlock:(void (^)(BOOL successful, id<AlfrescoSession> alfrescoSession))loginCompletionBlock
{
    void (^logInSuccessful)(BOOL, id<AlfrescoSession>) = ^(BOOL successful, id<AlfrescoSession> session)
    {
        if (loginCompletionBlock != NULL)
        {
            loginCompletionBlock(successful, session);
        }
    };
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        if (account.accountType == UserAccountTypeOnPremise)
        {
            if (!account.password || [account.password isEqualToString:@""])
            {
                [self displayLoginViewControllerWithAccount:account username:account.username];
                logInSuccessful(NO, nil);
                return;
            }
            
            AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [self showHUDOnView:delegate.window];
            [self authenticateOnPremiseAccount:account password:account.password completionBlock:^(BOOL successful, id<AlfrescoSession> session) {
                [self hideHUD];
                if (!successful)
                {
                    [self displayLoginViewControllerWithAccount:account username:account.username];
                }
                logInSuccessful(successful, session);
            }];
        }
        else
        {
            [self authenticateCloudAccount:account networkId:networkId navigationConroller:nil completionBlock:^(BOOL successful, id<AlfrescoSession> session) {
                
                logInSuccessful(successful, session);
            }];
        }
    }
    else
    {
        NSString *messageTitle = NSLocalizedString(@"error.no.internet.access.title", @"No Internet Error Title");
        NSString *messageBody = NSLocalizedString(@"error.no.internet.access.message", @"No Internet Error Message");
        displayErrorMessageWithTitle(messageBody, messageTitle);
        logInSuccessful(NO, nil);
    }
}

#pragma mark - Cloud authentication Methods

- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
             navigationConroller:(UINavigationController *)navigationController
                 completionBlock:(void (^)(BOOL successful, id<AlfrescoSession> alfrescoSession))authenticationCompletionBlock
{
    self.authenticationCompletionBlock = authenticationCompletionBlock;
    void (^authenticationComplete)(id<AlfrescoSession>) = ^(id<AlfrescoSession> session) {
        if (!session)
        {
            if (authenticationCompletionBlock != NULL)
            {
                authenticationCompletionBlock(NO, session);
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
                        authenticationCompletionBlock(YES, session);
                    }
                }
                else
                {
                    if (authenticationCompletionBlock != NULL)
                    {
                        authenticationCompletionBlock(NO, nil);
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
                    
                    authenticationComplete(session);
                }];
            }
            else
            {
                authenticationComplete(nil);
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
                            authenticationComplete(nil);
                        }
                        else
                        {
                            account.oauthData = refreshedOAuthData;
                            [[AccountManager sharedManager] saveAccountsToKeychain];
                            
                            // try to connect once OAuthData is refreshed
                            [self connectWithOAuthData:refreshedOAuthData networkId:networkId completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                                authenticationComplete(session);
                            }];
                        }
                    }];
                }
                else
                {
                    authenticationComplete(nil);
                }
            }
            else
            {
                authenticationComplete(cloudSession);
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
            self.authenticationCompletionBlock(NO, nil);
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

- (void)authenticateOnPremiseAccount:(UserAccount *)account password:(NSString *)password completionBlock:(void (^)(BOOL successful, id<AlfrescoSession> alfrescoSession))completionBlock
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
    
    self.currentLoginURLString = [Utility serverURLStringFromAccount:account];
    self.currentLoginRequest = [AlfrescoRepositorySession connectWithUrl:[NSURL URLWithString:self.currentLoginURLString]
                                                                username:account.username
                                                                password:password
                                                              parameters:sessionParameters
                                                         completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                                                             if (session)
                                                             {
                                                                 [UniversalDevice clearDetailViewController];
                                                                 
                                                                 self.currentLoginURLString = nil;
                                                                 self.currentLoginRequest = nil;
                                                                 
                                                                 if (completionBlock != NULL)
                                                                 {
                                                                     completionBlock(YES, session);
                                                                 }
                                                             }
                                                             else
                                                             {
                                                                 if (completionBlock != NULL)
                                                                 {
                                                                     completionBlock(NO, nil);
                                                                 }
                                                             }
                                                         }];
}

- (void)showHUDOnView:(UIView *)view
{
    MBProgressHUD *progress = [[MBProgressHUD alloc] initWithView:view];
    progress.labelText = NSLocalizedString(@"login.hud.label", @"Connecting...");
    [view addSubview:progress];
    [progress show:YES];
    
    self.progressHUD = progress;
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
    [self authenticateOnPremiseAccount:account password:(NSString *)password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession) {
        [self hideHUD];
        if (successful)
        {
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
