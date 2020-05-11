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

#import "LoginManagerCore.h"
#import "Constants.h"
#import "UserAccount.h"
#import "ConnectivityManager.h"
#import "AccountManager.h"
#import "Utilities.h"


@interface LoginManagerCore()

@property (nonatomic, assign) BOOL                              loginAttemptInProgress;
@property (nonatomic, assign) BOOL                              didCancelLogin;

@property (nonatomic, strong) __block NSString                  *currentLoginURLString;
@property (nonatomic, strong) __block AlfrescoRequest           *currentLoginRequest;

// Cloud parameters
@property (nonatomic, strong) NSString                          *cloudAPIKey;
@property (nonatomic, strong) NSString                          *cloudSecretKey;

@property (nonatomic, strong) AlfrescoOAuthUILoginViewController*loginController;
@property (nonatomic, strong) AlfrescoSAMLUILoginViewController *samlLoginController;

// AIMS
@property (nonatomic, strong) NSTimer                           *aimsSessionTimer;

@property (nonatomic, copy) void (^authenticationCompletionBlock)(BOOL success, id<AlfrescoSession> alfrescoSession, NSError *error);

@end

@implementation LoginManagerCore


- (void)attemptLoginToAccount:(UserAccount *)account
                    networkId:(NSString *)networkId
              completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock
{
    if (self.loginAttemptInProgress)
    {
        return;
    }
    
    self.loginAttemptInProgress = YES;
    
    if (account == nil)
    {
        return;
    }
    
    __weak typeof(self)weakSelf = self;
    void (^handleOauthAuthenticationBlock)(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) = ^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if ([self.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
        {
            [self.delegate willEndVisualAuthenticationProgress];
        }
        
        if(successful)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionRefreshedNotification
                                                                object:alfrescoSession];
        } else {
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoShowAccountPickerNotification
                                                                object:account];
        }
        
        if (loginCompletionBlock)
        {
            loginCompletionBlock(successful, alfrescoSession, error);
        }
        
        strongSelf.loginAttemptInProgress = NO;
    };
    
    self.authenticationCompletionBlock = ^(BOOL successful, id<AlfrescoSession> session, NSError *error){
        if (successful)
        {
            weakSelf.sessionExpired = NO;
        }
        
        if (loginCompletionBlock != NULL)
        {
            loginCompletionBlock(successful, session, error);
        }
    };
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        if ([self.delegate respondsToSelector:@selector(willBeginVisualAuthenticationProgress)]) {
            [self.delegate willBeginVisualAuthenticationProgress];
        }
        
        if (account.accountType == UserAccountTypeOnPremise)
        {
            NSString *urlString = [Utilities serverURLAddressStringFromAccount:account];
            
            __weak typeof(self) weakSelf = self;
            [AlfrescoSAMLAuthHelper
             checkIfSAMLIsEnabledForServerWithUrlString:urlString
             completionBlock:^(AlfrescoSAMLData *samlData, NSError *error) {
                __strong typeof(self) strongSelf = weakSelf;
                
                if ([strongSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)]) {
                    [strongSelf.delegate willEndVisualAuthenticationProgress];
                }
                
                void (^showSAMLWebViewAndAuthenticate)(void) = ^void (){
                    [weakSelf showSAMLWebViewForAccount:account
                                   navigationController:nil
                                        completionBlock:^(AlfrescoSAMLData *samlData, NSError *error)
                     {
                        if (samlData)
                        {
                            account.samlData.samlTicket = samlData.samlTicket;
                            [weakSelf authenticateWithSAMLOnPremiseAccount:account
                                                      navigationController:nil
                                                           completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                if (successful)
                                {
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionRefreshedNotification object:alfrescoSession];
                                }
                                weakSelf.authenticationCompletionBlock(successful, alfrescoSession, error);
                                weakSelf.loginAttemptInProgress = NO;
                                [weakSelf.samlLoginController dismissViewControllerAnimated:YES
                                                                                 completion:nil];
                            }];
                        }
                    }];
                };
                
                if (error || [samlData isSamlEnabled] == NO) // SAML not enabled
                {
                    BOOL switchedAuthenticationMethod = NO;
                    
                    if (account.samlData)
                    {
                        switchedAuthenticationMethod = YES;
                    }
                    account.samlData = nil;
                    
                    if (switchedAuthenticationMethod)
                    {
                        strongSelf.sessionExpired = YES;
                        
                        if ([strongSelf.delegate respondsToSelector:@selector(trackAnalyticsEventWithCategory:action:label:value:)])
                        {
                            [strongSelf.delegate trackAnalyticsEventWithCategory:kAnalyticsEventCategoryAccount
                                                                          action:kAnalyticsEventActionChangeAuthentication
                                                                           label:kAnalyticsEventLabelBasic
                                                                           value:nil];
                        }
                        
                        void (^signInAlertCompletionBlock)(void) = ^void (){
                            if (account.username.length == 0 || account.password.length == 0)
                            {
                                if ([weakSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
                                {
                                    [weakSelf.delegate willEndVisualAuthenticationProgress];
                                }
                                
                                if ([weakSelf.delegate respondsToSelector:@selector(displayLoginViewControllerWithAccount:username:)])
                                {
                                    [weakSelf.delegate displayLoginViewControllerWithAccount:account
                                                                                    username:account.username];
                                }
                                
                                weakSelf.authenticationCompletionBlock(NO, nil, nil);
                                weakSelf.loginAttemptInProgress = NO;
                                return;
                            }
                            
                            [weakSelf
                             authenticateOnPremiseAccount:account
                             password:account.password
                             completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *error) {
                                if ([weakSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
                                {
                                    [weakSelf.delegate willEndVisualAuthenticationProgress];
                                }
                                
                                if(successful)
                                {
                                    weakSelf.sessionExpired = NO;
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionRefreshedNotification object:session];
                                }
                                if (error &&
                                    error.code != kAlfrescoErrorCodeNoNetworkConnection &&
                                    error.code != kAlfrescoErrorCodeNetworkRequestCancelled)
                                {
                                    if ([weakSelf.delegate respondsToSelector:@selector(displayLoginViewControllerWithAccount:username:)])
                                    {
                                        [weakSelf.delegate displayLoginViewControllerWithAccount:account
                                                                                        username:account.username];
                                    }
                                }
                                weakSelf.authenticationCompletionBlock(successful, session, error);
                                weakSelf.loginAttemptInProgress = NO;
                            }];
                        };
                        
                        if ([strongSelf.delegate respondsToSelector:@selector(showSignInAlertWithSignedInBlock:)])
                        {
                            [strongSelf.delegate showSignInAlertWithSignedInBlock:signInAlertCompletionBlock];
                        }
                    }
                    else
                    {
                        if (account.username.length == 0 || account.password.length == 0)
                        {
                            if ([strongSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
                            {
                                [strongSelf.delegate willEndVisualAuthenticationProgress];
                            }
                            
                            if ([strongSelf.delegate respondsToSelector:@selector(displayLoginViewControllerWithAccount:username:)])
                            {
                                [strongSelf.delegate displayLoginViewControllerWithAccount:account
                                                                                  username:account.username];
                            }
                            
                            strongSelf.authenticationCompletionBlock(NO, nil, nil);
                            strongSelf.loginAttemptInProgress = NO;
                            return;
                        }
                        
                        [strongSelf
                         authenticateOnPremiseAccount:account
                         password:account.password
                         completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *error) {
                            if ([weakSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
                            {
                                [weakSelf.delegate willEndVisualAuthenticationProgress];
                            }
                            
                            if(successful)
                            {
                                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionRefreshedNotification
                                                                                    object:session];
                            }
                            if (error && error.code != kAlfrescoErrorCodeNoNetworkConnection &&
                                error.code != kAlfrescoErrorCodeNetworkRequestCancelled)
                            {
                                if ([weakSelf.delegate respondsToSelector:@selector(displayLoginViewControllerWithAccount:username:)])
                                {
                                    [weakSelf.delegate displayLoginViewControllerWithAccount:account
                                                                                    username:account.username];
                                }
                            }
                            weakSelf.authenticationCompletionBlock(successful, session, error);
                            weakSelf.loginAttemptInProgress = NO;
                        }];
                    }
                } else // SAML enabled
                {
                    if (account.samlData)
                    {
                        // The IDP might have been changed. Set the SAMLInfo.
                        account.samlData.samlInfo = samlData.samlInfo;
                        
                        if (account.samlData.samlTicket)
                        {
                            [strongSelf authenticateWithSAMLOnPremiseAccount:account
                                                        navigationController:nil
                                                             completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                if ([weakSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
                                {
                                    [weakSelf.delegate willEndVisualAuthenticationProgress];
                                }
                                
                                if (error)
                                {
                                    account.samlData.samlTicket = nil;
                                    showSAMLWebViewAndAuthenticate();
                                }
                                else
                                {
                                    weakSelf.authenticationCompletionBlock(successful, alfrescoSession, nil);
                                    weakSelf.loginAttemptInProgress = NO;
                                }
                            }];
                        }
                        else
                        {
                            showSAMLWebViewAndAuthenticate();
                        }
                    }
                    else
                    {
                        account.samlData = samlData;
                        self.sessionExpired = YES;
                        
                        if ([self.delegate respondsToSelector:@selector(trackEventWithCategory:action:label:value:)])
                        {
                            [self.delegate trackAnalyticsEventWithCategory:kAnalyticsEventCategoryAccount
                                                                    action:kAnalyticsEventActionChangeAuthentication
                                                                     label:kAnalyticsEventLabelSAML
                                                                     value:nil];
                        }
                        
                        if ([strongSelf.delegate respondsToSelector:@selector(showSignInAlertWithSignedInBlock:)])
                        {
                            [strongSelf.delegate showSignInAlertWithSignedInBlock:showSAMLWebViewAndAuthenticate];
                        }
                    }
                }
            }];
        }
        else if (account.accountType == UserAccountTypeAIMS)
        {
            [self authenticateWithAIMSOnPremiseAccount:account
                                       completionBlock:handleOauthAuthenticationBlock];
        }
        else
        {
            [self authenticateCloudAccount:account
                                 networkId:networkId
                      navigationController:nil
                           completionBlock:handleOauthAuthenticationBlock];
        }
    }
    else if (![[AccountManager sharedManager].selectedAccount.accountIdentifier isEqualToString:account.accountIdentifier])
    {
        // Assuming there is no internet connection and the user tries to switch account.
        self.authenticationCompletionBlock(YES, nil, nil);
        self.loginAttemptInProgress = NO;
    }
    else
    {
        NSError *unreachableError = [NSError errorWithDomain:kAlfrescoErrorDomainName code:kAlfrescoErrorCodeNoNetworkConnection userInfo:nil];
        self.authenticationCompletionBlock(NO, nil, unreachableError);
        self.loginAttemptInProgress = NO;
    }
}


#pragma mark - SAML Authentication Methods

- (void)showSAMLWebViewForAccount:(UserAccount *)account
             navigationController:(UINavigationController *)navigationController
                  completionBlock:(AlfrescoSAMLAuthCompletionBlock)completionBlock
{
    NSString *urlString = [Utilities serverURLAddressStringFromAccount:account];
    
    AlfrescoSAMLUILoginViewController *lvc =
    [[AlfrescoSAMLUILoginViewController alloc] initWithBaseURLString:urlString
                                                     completionBlock:^(AlfrescoSAMLData *alfrescoSamlData, NSError *error) {
        
        if (completionBlock)
        {
            completionBlock(alfrescoSamlData, error);
        }
    }];
    
    
    if (!navigationController)
    {
        self.samlLoginController = lvc;
    }
    
    if ([self.delegate respondsToSelector:@selector(showSAMLLoginViewController:inNavigationController:)])
    {
        [self.delegate showSAMLLoginViewController:lvc
                            inNavigationController:navigationController];
    }
}

- (void)authenticateWithSAMLOnPremiseAccount:(UserAccount *)account
                        navigationController:(UINavigationController *)navigationController
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock
{
    NSString *urlString = [Utilities serverURLAddressStringFromAccount:account];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (account.samlData.samlTicket)
    {
        [AlfrescoRepositorySession connectWithUrl:url
                                         SAMLData:account.samlData
                                  completionBlock:^(id<AlfrescoSession> session, NSError *error) {
            if (authenticationCompletionBlock)
            {
                account.paidAccount = [session.repositoryInfo.edition isEqualToString:kRepositoryEditionEnterprise];
                
                if (session)
                {
                    authenticationCompletionBlock(YES, session, nil);
                }
                else
                {
                    authenticationCompletionBlock(NO, nil, error);
                }
            }
        }];
    }
    else
    {
        authenticationCompletionBlock(NO, nil, nil);
    }
}

- (void)cancelSamlAuthentication
{
    [self.samlLoginController dismissViewControllerAnimated:YES completion:^{
        self.loginAttemptInProgress = NO;
        
        if (self.authenticationCompletionBlock != NULL)
        {
            self.authenticationCompletionBlock(NO, nil, nil);
        }
    }];
}

#pragma mark - Cloud authentication Methods

- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
            navigationController:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock
{
    self.didCancelLogin = NO;
    self.authenticationCompletionBlock = authenticationCompletionBlock;
    
    NSDictionary *customParameters = [self loadCustomCloudOAuthParameters];
    
    __weak typeof(self) weakSelf = self;
    void (^authenticationComplete)(id<AlfrescoSession>, NSError *error) = ^(id<AlfrescoSession> session, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (error)
        {
            if (authenticationCompletionBlock != NULL)
            {
                authenticationCompletionBlock(NO, session, error);
            }
        }
        else
        {
            if (!strongSelf.didCancelLogin)
            {
                strongSelf.currentLoginRequest = [(AlfrescoCloudSession *)session retrieveNetworksWithCompletionBlock:^(NSArray *networks, NSError *error) {
                    if (networks && error == nil)
                    {
                        // Primary sort: isHomeNetwork
                        NSSortDescriptor *homeNetworkSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"isHomeNetwork" ascending:NO];
                        // Seconday sort: alphabetical by identifier
                        NSSortDescriptor *identifierSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"identifier" ascending:YES];
                        
                        NSArray *sortedNetworks = [networks sortedArrayUsingDescriptors:@[homeNetworkSortDescriptor, identifierSortDescriptor]];
                        account.accountNetworks = [sortedNetworks valueForKeyPath:@"identifier"];
                        
                        // The home network defines the user's account paid status
                        account.paidAccount = ((AlfrescoCloudNetwork *)sortedNetworks[0]).isPaidNetwork;
                        
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
        }
    };
    
    AlfrescoOAuthUILoginViewController * (^showOAuthLoginViewController)(void) = ^AlfrescoOAuthUILoginViewController * (void) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if ([strongSelf.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
        {
            [strongSelf.delegate willEndVisualAuthenticationProgress];
        }
        
        AlfrescoOAuthUILoginViewController *oauthLoginController =
        [[AlfrescoOAuthUILoginViewController alloc] initWithAPIKey:self.cloudAPIKey
                                                         secretKey:self.cloudSecretKey
                                                        parameters:customParameters
                                                   completionBlock:^(AlfrescoOAuthData *oauthData, NSError *error) {
            if (oauthData)
            {
                account.oauthData = oauthData;
                
                weakSelf.currentLoginRequest =
                [weakSelf connectWithOAuthData:oauthData
                                     networkId:networkId
                               completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                    if (navigationController)
                    {
                        [navigationController popViewControllerAnimated:YES];
                    }
                    else
                    {
                        [weakSelf.loginController dismissViewControllerAnimated:YES
                                                                     completion:nil];
                    }
                    
                    authenticationComplete(session, error);
                }];
            }
            else
            {
                authenticationComplete(nil, error);
            }
        }];
        
        if ([strongSelf.delegate respondsToSelector:@selector(showOauthLoginController:inNavigationController:)])
        {
            [strongSelf.delegate showOauthLoginController:oauthLoginController
                                   inNavigationController:navigationController];
        }
        
        if ([strongSelf.delegate respondsToSelector:@selector(trackAnalyticsScreenWithName:)])
        {
            [strongSelf.delegate trackAnalyticsScreenWithName:kAnalyticsViewAccountOAuth];
        }
        
        return oauthLoginController;
    };
    
    if (account.oauthData)
    {
        __weak typeof(self) weakSelf = self;
        self.currentLoginRequest =
        [self connectWithOAuthData:account.oauthData
                         networkId:networkId
                   completionBlock:^(id<AlfrescoSession> cloudSession, NSError *connectionError) {
            __strong typeof(self) strongSelf = weakSelf;
            
            [navigationController popViewControllerAnimated:YES];
            if (nil == cloudSession)
            {
                if (connectionError.code == kAlfrescoErrorCodeAccessTokenExpired)
                {
                    // refresh token
                    AlfrescoOAuthHelper *oauthHelper = [[AlfrescoOAuthHelper alloc] initWithParameters:customParameters
                                                                                              delegate:strongSelf];
                    strongSelf.currentLoginRequest =
                    [oauthHelper refreshAccessToken:account.oauthData
                                    completionBlock:^(AlfrescoOAuthData *refreshedOAuthData, NSError *refreshError) {
                        if (nil == refreshedOAuthData)
                        {
                            // if refresh token is expired or invalid present OAuth LoginView
                            if (refreshError.code == kAlfrescoErrorCodeRefreshTokenExpired ||
                                refreshError.code == kAlfrescoErrorCodeRefreshTokenInvalid)
                            {
                                weakSelf.loginController = showOAuthLoginViewController();
                                weakSelf.loginController.oauthDelegate = self;
                            }
                            authenticationComplete(nil, refreshError);
                        }
                        else
                        {
                            account.oauthData = refreshedOAuthData;
                            [[AccountManager sharedManager] saveAccountsToKeychain];
                            
                            // try to connect once OAuthData is refreshed
                            if (!weakSelf.didCancelLogin)
                            {
                                weakSelf.currentLoginRequest =
                                [weakSelf connectWithOAuthData:refreshedOAuthData
                                                     networkId:networkId
                                               completionBlock:^(id<AlfrescoSession> retrySession, NSError *retryError) {
                                    authenticationComplete(retrySession, retryError);
                                }];
                            }
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

- (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                                networkId:(NSString *)networkId
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock
{
    AlfrescoRequest *cloudRequest = nil;
    NSDictionary *customParameters = [self loadCustomCloudOAuthParameters];
    
    if (networkId)
    {
        cloudRequest = [AlfrescoCloudSession connectWithOAuthData:oauthData
                                                 networkIdentifer:networkId
                                                       parameters:customParameters
                                                  completionBlock:completionBlock];
    }
    else
    {
        cloudRequest = [AlfrescoCloudSession connectWithOAuthData:oauthData
                                                       parameters:customParameters
                                                  completionBlock:completionBlock];
    }
    
    return cloudRequest;
}

- (NSDictionary *)loadCustomCloudOAuthParameters
{
    NSDictionary *parameters = nil;
    
    // Initially reset to defaults
    self.cloudAPIKey = @"";
    self.cloudSecretKey = @"";
    
    // Checks for a cloud-config.plist file in the "Local Files" area with custom connection parameters
    NSString *plistPath = [[[AlfrescoFileManager sharedManager] downloadsContentFolderPath] stringByAppendingPathComponent:kCloudConfigFile];
    NSDictionary *config = [NSDictionary dictionaryWithContentsOfFile:plistPath];
    NSString *customCloudURL = config[kCloudConfigParamURL];
    
    if (config && customCloudURL)
    {
        self.cloudAPIKey = config[kCloudConfigParamAPIKey];
        self.cloudSecretKey = config[kCloudConfigParamSecretKey];
        parameters = @{kInternalSessionCloudURL: customCloudURL};
    }
    
    return parameters;
}

- (void)cancelCloudAuthentication
{
    [self.loginController dismissViewControllerAnimated:YES
                                             completion:^{
        if (self.authenticationCompletionBlock != NULL)
        {
            self.authenticationCompletionBlock(NO, nil, nil);
        }
    }];
}


#pragma mark - AIMS authentication methods

- (void)authenticateWithAIMSOnPremiseAccount:(UserAccount *)account
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock
{
    __weak typeof(self) weakSelf = self;
    void (^handleAuthenticationResponse)(id<AlfrescoSession>, NSError *error) = ^(id<AlfrescoSession> session, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            __strong typeof(self) strongSelf = weakSelf;
            
            if (authenticationCompletionBlock)
            {
                account.paidAccount = [session.repositoryInfo.edition isEqualToString:kRepositoryEditionEnterprise];
                
                if (session)
                {
                    [[AccountManager sharedManager] selectAccount:account
                                                    selectNetwork:account.selectedNetworkId
                                                  alfrescoSession:session];
                    [strongSelf scheduleAIMSAcessTokenRefreshHandlerCurrentAccount];
                    authenticationCompletionBlock(YES, session, nil);
                }
                else
                {
                    authenticationCompletionBlock(NO, nil, error);
                }
            }
        });
    };
    
    
    NSString *urlString = [Utilities serverURLAddressStringFromAccount:account];
    NSURL *url = [NSURL URLWithString:urlString];
    
    if (account.oauthData)
    {
        [AlfrescoRepositorySession connectWithUrl:url
                                        oauthData:account.oauthData
                                  completionBlock:^(id<AlfrescoSession> session, NSError *error) {
            __strong typeof(self) strongSelf = weakSelf;
            
            if (error.code == kAlfrescoErrorCodeAccessTokenExpired ||
                error.code == kAlfrescoErrorCodeUnauthorisedAccess ||
                error.code == kAlfrescoErrorCodeAuthorizationCodeInvalid)
            {
                if ([strongSelf.delegate respondsToSelector:@selector(refreshSessionForAccount:completionBlock:)])
                {
                    [strongSelf.delegate refreshSessionForAccount:account
                                                  completionBlock:^(UserAccount *refreshedAccount, NSError *error) {
                        if (!error) {
                            if ([weakSelf.delegate respondsToSelector:@selector(disableAutoSelectMenuOption)]) {
                                [weakSelf.delegate disableAutoSelectMenuOption];
                            }
                            
                            [AlfrescoRepositorySession connectWithUrl:url
                                                            oauthData:refreshedAccount.oauthData
                                                      completionBlock:handleAuthenticationResponse];
                        } else {
                            handleAuthenticationResponse(session, error);
                        };
                    }];
                }
            } else {
                handleAuthenticationResponse(session, error);
            }
        }];
    }
    else
    {
        authenticationCompletionBlock(NO, nil, nil);
    }
}

- (void)scheduleAIMSAcessTokenRefreshHandlerCurrentAccount
{
    [self.aimsSessionTimer invalidate];
    
    UserAccount *currentAccount = [AccountManager sharedManager].selectedAccount;
    NSTimeInterval aimsAccessTokenRefreshInterval = currentAccount.oauthData.expiresIn.integerValue - [[NSDate date] timeIntervalSince1970] - kAlfrescoDefaultAIMSAccessTokenRefreshTimeBuffer;
    
    if (aimsAccessTokenRefreshInterval < kAlfrescoDefaultAIMSAccessTokenRefreshTimeBuffer / 2) {
        return;
    }
    __weak typeof(self) weakSelf = self;
    self.aimsSessionTimer = [NSTimer scheduledTimerWithTimeInterval:aimsAccessTokenRefreshInterval
                                                            repeats:YES
                                                              block:^(NSTimer * _Nonnull timer) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, kNilOptions), ^{
            if ([weakSelf.delegate respondsToSelector:@selector(refreshSessionForAccount:completionBlock:)]) {
                [weakSelf.delegate refreshSessionForAccount:currentAccount
                                              completionBlock:^(UserAccount *refreshedAccount, NSError *error)
                {
                    if (!error && refreshedAccount)
                    {
                        NSString *urlString = [Utilities serverURLAddressStringFromAccount:refreshedAccount];
                        NSURL *url = [NSURL URLWithString:urlString];
                        
                        if ([weakSelf.delegate respondsToSelector:@selector(disableAutoSelectMenuOption)])
                        {
                            [weakSelf.delegate disableAutoSelectMenuOption];
                        }
                        
                        [AlfrescoRepositorySession connectWithUrl:url
                                                        oauthData:refreshedAccount.oauthData
                                                  completionBlock:^(id<AlfrescoSession> session, NSError *error) {
                            dispatch_async(dispatch_get_main_queue(), ^{
                                UserAccount *currentAccount = [AccountManager sharedManager].selectedAccount;
                                if (currentAccount == refreshedAccount) {
                                    [[AccountManager sharedManager] selectAccount:refreshedAccount
                                                                    selectNetwork:refreshedAccount.selectedNetworkId
                                                                  alfrescoSession:session];
                                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionRefreshedNotification
                                                                                        object:session
                                                                                      userInfo:nil];
                                    [weakSelf scheduleAIMSAcessTokenRefreshHandlerCurrentAccount];
                                }
                            });
                        }];
                    }
                }];
            }
        });
    }];
}

#pragma mark - OAuth delegate

- (void)oauthLoginDidFailWithError:(NSError *)error
{
    AlfrescoLogDebug(@"OAuth Failed");
}

#pragma mark - Private interface

- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock
{
    [self authenticateOnPremiseAccount:account
                              username:account.username
                              password:password
                       completionBlock:completionBlock];
}

- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            username:(NSString *)username
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock
{
    NSDictionary *sessionParameters = [@{kAlfrescoMetadataExtraction: @YES,
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
    
    self.currentLoginURLString = [Utilities serverURLAddressStringFromAccount:account];
    
    __weak typeof(self) weakSelf = self;
    self.currentLoginRequest =
    [AlfrescoRepositorySession connectWithUrl:[NSURL URLWithString:self.currentLoginURLString]
                                     username:username
                                     password:password
                                   parameters:sessionParameters
                              completionBlock:^(id<AlfrescoSession> session, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (session)
        {
            if ([strongSelf.delegate respondsToSelector:@selector(clearDetailViewController)]) {
                [strongSelf.delegate clearDetailViewController];
            }
            
            strongSelf.currentLoginURLString = nil;
            strongSelf.currentLoginRequest = nil;
            
            account.paidAccount = [session.repositoryInfo.edition isEqualToString:kRepositoryEditionEnterprise];
            
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

- (void)cancelLoginRequest
{
    if ([self.delegate respondsToSelector:@selector(willEndVisualAuthenticationProgress)])
    {
        [self.delegate willEndVisualAuthenticationProgress];
    }
    
    [self.currentLoginRequest cancel];
    self.didCancelLogin = YES;
    self.currentLoginRequest = nil;
    self.currentLoginURLString = nil;
}

- (void)cancelAIMSActiveSessionRefreshTask
{
    [self.aimsSessionTimer invalidate];
}

@end
