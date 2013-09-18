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

@end
