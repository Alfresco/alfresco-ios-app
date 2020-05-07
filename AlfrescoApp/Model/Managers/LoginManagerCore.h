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

#import <Foundation/Foundation.h>
#import "LoginManagerCoreDelegate.h"

@interface LoginManagerCore : NSObject <AlfrescoOAuthLoginDelegate>

@property (nonatomic, weak) id<LoginManagerCoreDelegate>    delegate;
@property (nonatomic, assign) BOOL                          sessionExpired;
@property (nonatomic, readonly) void (^authenticationCompletionBlock)(BOOL success, id<AlfrescoSession> alfrescoSession, NSError *error);

- (void)attemptLoginToAccount:(UserAccount *)account
                    networkId:(NSString *)networkId
              completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock;
- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            username:(NSString *)username
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock;
- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
            navigationController:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;
- (void)authenticateOnPremiseAccount:(UserAccount *)account
                            password:(NSString *)password
                     completionBlock:(LoginAuthenticationCompletionBlock)completionBlock;
- (void)authenticateWithSAMLOnPremiseAccount:(UserAccount *)account
                        navigationController:(UINavigationController *)navigationController
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;
- (void)authenticateWithAIMSOnPremiseAccount:(UserAccount *)account
                             completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;
- (void)showSAMLWebViewForAccount:(UserAccount *)account
             navigationController:(UINavigationController *)navigationController
                  completionBlock:(AlfrescoSAMLAuthCompletionBlock)completionBlock;

- (void)cancelSamlAuthentication;
- (void)cancelCloudAuthentication;
- (void)cancelLoginRequest;
- (void)cancelAIMSActiveSessionRefreshTask;

@end
