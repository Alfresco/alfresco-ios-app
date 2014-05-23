//
//  CloudSignUpViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 06/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@class UserAccount;
@class CloudSignUpViewController;

@protocol CloudSignUpViewControllerDelegate <NSObject>

@optional
- (void)cloudSignupControllerWillDismiss:(CloudSignUpViewController *)controller;
- (void)cloudSignupControllerDidDismiss:(CloudSignUpViewController *)controller;

@end

@interface CloudSignUpViewController : ParentListViewController <UITextFieldDelegate>

/*
 * Initializer with account for which information is displayed or pass nil for account if signing up for new cloud account
 */
- (id)initWithAccount:(UserAccount *)account;

@property (nonatomic, weak) id<CloudSignUpViewControllerDelegate> delegate;

@end
