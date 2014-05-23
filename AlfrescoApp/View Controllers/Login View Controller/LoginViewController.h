//
//  LoginViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@class LoginViewController;
@class UserAccount;

@protocol LoginViewControllerDelegate <NSObject>

@optional
// both are optional, however, if using - initWithAccount:delegate: you must implemet loginViewController:didPressRequestLoginToAccount:username:password:
- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToAccount:(UserAccount *)account username:(NSString *)username password:(NSString *)password;
- (void)loginViewController:(LoginViewController *)loginViewController didPressRequestLoginToServer:(NSString *)server username:(NSString *)username password:(NSString *)password;
- (void)loginViewController:(LoginViewController *)loginViewController didPressCancel:(UIBarButtonItem *)button;

@end

@interface LoginViewController : UIViewController <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>

- (id)initWithAccount:(UserAccount *)account delegate:(id<LoginViewControllerDelegate>)delegate;
- (id)initWithServer:(NSString *)serverURLString serverDisplayName:(NSString *)serverDisplayName username:(NSString *)username delegate:(id<LoginViewControllerDelegate>)delegate;
- (void)updateUIForFailedLogin;

@end
