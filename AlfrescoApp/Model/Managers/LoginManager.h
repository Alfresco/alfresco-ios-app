//
//  LoginManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginViewController.h"

@class UserAccount;

@interface LoginManager : NSObject <LoginViewControllerDelegate, AlfrescoOAuthLoginDelegate>

+ (id)sharedManager;
- (void)attemptLoginToAccount:(UserAccount *)account networkId:(NSString *)networkId completionBlock:(void (^)(BOOL successful))loginCompletionBlock;
- (void)authenticateOnPremiseAccount:(UserAccount *)account password:(NSString *)password temporarySession:(BOOL)temporarySession completionBlock:(void (^)(BOOL successful))completionBlock;
- (void)authenticateCloudAccount:(UserAccount *)account
                       networkId:(NSString *)networkId
                temporarySession:(BOOL)temporarySession
             navigationConroller:(UINavigationController *)navigationController
                 completionBlock:(void (^)(BOOL successful))authenticationCompletionBlock;

@end
