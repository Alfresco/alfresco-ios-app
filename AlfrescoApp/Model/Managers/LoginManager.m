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

- (void)authenticateCloudAccount:(Account *)account temporarySession:(BOOL)temporarySession navigationConroller:(UINavigationController *)navigationController completionBlock:(void (^)(BOOL successful))completionBlock
{
    void (^connectToCloudWithOAuthData)(AlfrescoOAuthData *) = ^(AlfrescoOAuthData *oauthData)
    {
        [AlfrescoCloudSession connectWithOAuthData:oauthData completionBlock:^(id<AlfrescoSession> session, NSError *error) {
            [navigationController popViewControllerAnimated:YES];
            if (nil == session)
            {
                if (completionBlock != NULL)
                {
                    completionBlock(NO);
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
                
                if (completionBlock != NULL)
                {
                    completionBlock(YES);
                }
            }
        }];
    };
    
    if (account.oauthData)
    {
        connectToCloudWithOAuthData(account.oauthData);
    }
    else
    {
        self.loginController = [[AlfrescoOAuthLoginViewController alloc] initWithAPIKey:ALFRESCO_CLOUD_OAUTH_KEY
                                                                              secretKey:ALFRESCO_CLOUD_OAUTH_SECRET
                                                                        completionBlock:^(AlfrescoOAuthData *oauthData, NSError *error) {
                                                                            
                                                                            if (oauthData)
                                                                            {
                                                                                account.oauthData = oauthData;
                                                                                connectToCloudWithOAuthData(oauthData);
                                                                            }
                                                                            else
                                                                            {
                                                                                completionBlock(NO);
                                                                            }
                                                                        }];
        self.loginController.oauthDelegate = self;
        [navigationController pushViewController:self.loginController animated:YES];
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
