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
