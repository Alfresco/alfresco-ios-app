//
//  AccountInfoViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"

@class UserAccount;
@class AccountInfoViewController;

typedef NS_ENUM(NSInteger, AccountActivityType)
{
    AccountActivityTypeNewAccount,
    AccountActivityTypeEditAccount,
    AccountActivityTypeViewAccount
};

@protocol AccountInfoViewControllerDelegate <NSObject>

@optional
- (void)accountInfoViewControllerWillDismiss:(AccountInfoViewController *)controller;
- (void)accountInfoViewControllerDidDismiss:(AccountInfoViewController *)controller;
- (void)accountInfoViewController:(AccountInfoViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account;
- (void)accountInfoViewController:(AccountInfoViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account;

@end

@interface AccountInfoViewController : ParentListViewController <UITextFieldDelegate>

@property (nonatomic, weak) id<AccountInfoViewControllerDelegate> delegate;

/**
 Only use this initialiser to init this view controller. Passing through nil for the account will display an empty controller
 which can be used for a new account setup.
 */
- (id)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType;

@end
