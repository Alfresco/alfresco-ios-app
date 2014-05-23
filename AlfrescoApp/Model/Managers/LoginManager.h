//
//  LoginManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "LoginViewController.h"

@class UserAccount;

@interface LoginManager : NSObject <LoginViewControllerDelegate, AlfrescoOAuthLoginDelegate>

+ (LoginManager *)sharedManager;
- (void)attemptLoginToAccount:(UserAccount *)account networkId:(NSString *)networkId completionBlock:(LoginAuthenticationCompletionBlock)loginCompletionBlock;
- (void)authenticateOnPremiseAccount:(UserAccount *)account password:(NSString *)password completionBlock:(LoginAuthenticationCompletionBlock)completionBlock;
- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
             navigationConroller:(UINavigationController *)navigationController
                 completionBlock:(LoginAuthenticationCompletionBlock)authenticationCompletionBlock;

@end
