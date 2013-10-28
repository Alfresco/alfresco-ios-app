//
//  LoginManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "LoginViewController.h"

@class Account;

@interface LoginManager : NSObject <LoginViewControllerDelegate>

+ (id)sharedManager;
- (void)attemptLoginToAccount:(Account *)account;
- (void)loginToAccount:(Account *)account username:(NSString *)username password:(NSString *)password temporarySession:(BOOL)temporarySession completionBlock:(void (^)(BOOL successful))completionBlock;

@end
