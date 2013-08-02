//
//  LoginViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LoginViewController;

@protocol LoginViewControllerDelegate <NSObject>

- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToServer:(NSString *)server username:(NSString *)username password:(NSString *)password;

@end

@interface LoginViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

- (id)initWithServer:(NSString *)serverURLString serverDisplayName:(NSString *)serverDisplayName username:(NSString *)username delegate:(id<LoginViewControllerDelegate>)delegate;
- (void)updateUIForFailedLogin;

@end
