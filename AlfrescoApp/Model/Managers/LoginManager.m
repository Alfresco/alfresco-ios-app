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
#import "Account.h"
#import "AccountManager.h"
#import "NavigationViewController.h"

@interface LoginManager()

@property (nonatomic, strong) MBProgressHUD *progressHUD;
@property (nonatomic, strong) __block NSString *currentLoginURLString;
@property (nonatomic, strong) __block AlfrescoRequest *currentLoginRequest;
@property (nonatomic, strong) AlfrescoOAuthLoginViewController *loginController;
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

- (void)attemptLoginToAccount:(Account *)account
{
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        if (account.accountType == AccountTypeOnPremise)
        {
            if (account)
            {
                if (!account.password || [account.password isEqualToString:@""])
                {
                    [self displayLoginViewControllerWithAccount:account username:account.username];
                    return;
                }
                
                AppDelegate *delegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
                [self showHUDOnView:delegate.window];
                [self authenticateOnPremiseAccount:account password:account.password temporarySession:NO completionBlock:^(BOOL successful) {
                    [self hideHUD];
                    if (!successful)
                    {
                        [self displayLoginViewControllerWithAccount:account username:account.username];
                    }
                }];
            }
            else
            {
                [self displayLoginViewControllerWithAccount:account username:nil];
            }
        }
        else
        {
            [self authenticateCloudAccount:account temporarySession:NO navigationConroller:nil completionBlock:^(BOOL successful) {
                
            }];
        }
    }
    else
    {
        NSString *messageTitle = NSLocalizedString(@"error.no.internet.access.title", @"No Internet Error Title");
        NSString *messageBody = NSLocalizedString(@"error.no.internet.access.message", @"No Internet Error Message");
        displayErrorMessageWithTitle(messageBody, messageTitle);
    }
}

#pragma mark - Cloud authentication Methods

- (void)authenticateCloudAccount:(Account *)account temporarySession:(BOOL)temporarySession navigationConroller:(UINavigationController *)navigationController completionBlock:(void (^)(BOOL successful))authenticationCompletionBlock
{
    void (^authenticationComplete)(id<AlfrescoSession>) = ^(id<AlfrescoSession> session)
    {
        if (!session)
        {
            if (authenticationCompletionBlock != NULL)
            {
                authenticationCompletionBlock(NO);
            }
        }
        else
        {
            [UniversalDevice clearDetailViewController];
            if (!temporarySession)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:session userInfo:nil];
            }
            
            account.repositoryId = session.repositoryInfo.identifier;
            
            if (authenticationCompletionBlock != NULL)
            {
                authenticationCompletionBlock(YES);
            }
        }
    };
    
    AlfrescoOAuthLoginViewController * (^showOAuthLoginViewController)(void) = ^ AlfrescoOAuthLoginViewController * (void)
    {
        NavigationViewController *oauthNavigationController = nil;
        AlfrescoOAuthLoginViewController *oauthLoginController =  [[AlfrescoOAuthLoginViewController alloc] initWithAPIKey:ALFRESCO_CLOUD_OAUTH_KEY
                                                                                                                 secretKey:ALFRESCO_CLOUD_OAUTH_SECRET
                                                                                                           completionBlock:^(AlfrescoOAuthData *oauthData, NSError *error) {
                                                                                                               
                                                                                                               if (oauthData)
                                                                                                               {
                                                                                                                   account.oauthData = oauthData;
                                                                                                                   
                                                                                                                   [AlfrescoCloudSession connectWithOAuthData:oauthData completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                                                                                                                       if (navigationController)
                                                                                                                       {
                                                                                                                           [navigationController popViewControllerAnimated:YES];
                                                                                                                       }
                                                                                                                       else
                                                                                                                       {
                                                                                                                           [oauthNavigationController dismissViewControllerAnimated:YES completion:nil];
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
            oauthNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            
            AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
            [UniversalDevice displayModalViewController:oauthNavigationController onController:appDelegate.window.rootViewController withCompletionBlock:nil];
        }
        return oauthLoginController;
    };
    
    if (account.oauthData)
    {
        [AlfrescoCloudSession connectWithOAuthData:account.oauthData completionBlock:^(id<AlfrescoSession> cloudSession, NSError *connectionError) {
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
                            [AlfrescoCloudSession connectWithOAuthData:refreshedOAuthData completionBlock:^(id<AlfrescoSession> session, NSError *error) {
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

#pragma mark - OAuth delegate
- (void)oauthLoginDidFailWithError:(NSError *)error
{
    AlfrescoLogDebug(@"OAuth Failed");
}

#pragma mark - Private Functions

- (void)displayLoginViewControllerWithAccount:(Account *)account username:(NSString *)username
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    
    LoginViewController *loginViewController = [[LoginViewController alloc] initWithAccount:account delegate:self];
    NavigationViewController *loginNavigationController = [[NavigationViewController alloc] initWithRootViewController:loginViewController];
    
    [UniversalDevice displayModalViewController:loginNavigationController onController:appDelegate.window.rootViewController withCompletionBlock:nil];
}

- (void)authenticateOnPremiseAccount:(Account *)account password:(NSString *)password temporarySession:(BOOL)temporarySession completionBlock:(void (^)(BOOL successful))completionBlock
{
    NSDictionary *sessionParameters = @{kAlfrescoMetadataExtraction : [NSNumber numberWithBool:YES],
                                        kAlfrescoThumbnailCreation : [NSNumber numberWithBool:YES]};
    
    self.currentLoginURLString = [Utility serverURLStringFromAccount:account];
    self.currentLoginRequest = [AlfrescoRepositorySession connectWithUrl:[NSURL URLWithString:self.currentLoginURLString]
                                                                username:account.username
                                                                password:password
                                                              parameters:sessionParameters
                                                         completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                                                             if (session)
                                                             {
                                                                 [UniversalDevice clearDetailViewController];
                                                                 
                                                                 if (!temporarySession)
                                                                 {
                                                                     [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:session userInfo:nil];
                                                                 }
                                                                 
                                                                 account.repositoryId = session.repositoryInfo.identifier;
                                                                 
                                                                 self.currentLoginURLString = nil;
                                                                 self.currentLoginRequest = nil;
                                                                 
                                                                 if (completionBlock != NULL)
                                                                 {
                                                                     completionBlock(YES);
                                                                 }
                                                             }
                                                             else
                                                             {
                                                                 if (completionBlock != NULL)
                                                                 {
                                                                     completionBlock(NO);
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
    [self attemptLoginToAccount:[AccountManager sharedManager].selectedAccount];
}

- (void)cancelLoginRequest
{
    [self hideHUD];
    [self.currentLoginRequest cancel];
    self.currentLoginRequest = nil;
    self.currentLoginURLString = nil;
}

#pragma mark - LoginViewControllerDelegate Functions

- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToAccount:(Account *)account username:(NSString *)username password:(NSString *)password
{
    [self showHUDOnView:loginViewController.view];
    [self authenticateOnPremiseAccount:account password:(NSString *)password temporarySession:NO completionBlock:^(BOOL successful) {
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
    }];
}

@end
