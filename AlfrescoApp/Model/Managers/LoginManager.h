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

#import "LoginViewController.h"
#import "LoginManagerCoreDelegate.h"

@class UserAccount;

@interface LoginManager : NSObject <LoginViewControllerDelegate, LoginManagerCoreDelegate>

@property (nonatomic, assign, readonly) BOOL sessionExpired;

+ (LoginManager *)sharedManager;

- (void)attemptLoginToAccount:(UserAccount *)account
                    networkId:(NSString *)networkId
              completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock;
- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock;
- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
            navigationController:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;
- (void)authenticateWithSAMLOnPremiseAccount:(UserAccount *)account
                        navigationController:(UINavigationController *)navigationController
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;
- (void)showSAMLWebViewForAccount:(UserAccount *)account
             navigationController:(UINavigationController *)navigationController
                  completionBlock:(AlfrescoSAMLAuthCompletionBlock)completionBlock;
- (void)authenticateWithAIMSOnPremiseAccount:(UserAccount *)account
                             completionBlock:(LoginAuthenticationCompletionBlock)completionBlock;
- (void)showAIMSWebviewForAccount:(UserAccount *)account
             navigationController:(UINavigationController *)navigationController
                  completionBlock:(LoginAIMSCompletionBlock)completionBlock;
- (void)showLogOutAIMSWebviewForAccount:(UserAccount *)account
                   navigationController:(UINavigationController *)navigationController
                        completionBlock:(LogoutAIMSCompletionBlock)completionBlock;
- (void)saveInKeychainAIMSDataForAccount:(UserAccount *)account;
- (void)showSignInAlertWithSignedInBlock:(void (^)(void))completionBlock;
- (void)availableAuthTypeForAccount:(UserAccount *)account
                    completionBlock:(AvailableAuthenticationTypeCompletionBlock)completionBlock;
- (void)cancelActiveSessionRefreshTasks;

@end
