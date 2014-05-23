//
//  AccountInfoViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@class UserAccount;
@class AccountInfoViewController;

typedef NS_ENUM(NSInteger, AccountActivityType)
{
    AccountActivityTypeNewAccount,
    AccountActivityTypeEditAccount,
    AccountActivityTypeLoginFailed
};

@protocol AccountInfoViewControllerDelegate <NSObject>

@optional
- (void)accountInfoViewControllerWillDismiss:(AccountInfoViewController *)controller;
- (void)accountInfoViewControllerDidDismiss:(AccountInfoViewController *)controller;
- (void)accountInfoViewController:(AccountInfoViewController *)controller willDismissAfterAddingAccount:(UserAccount *)account;
- (void)accountInfoViewController:(AccountInfoViewController *)controller didDismissAfterAddingAccount:(UserAccount *)account;

@end

@interface AccountInfoViewController : ParentListViewController <UITextFieldDelegate>

/**
 This delegate is being made strong to ensure that the callbacks to the delegate are invoked.
 
 If this delegate is not retained, it will be nullified once the modal view is dismissed, therefore the the didDismiss
 callback will not be fired.
 
 By making this a strong reference, the controller is retained as long as this controller is on the heap, and nullified
 once it is deallocated from memory, which then releases the delegate. Therefore this is not leaking any memory.
 */
@property (nonatomic, strong) id<AccountInfoViewControllerDelegate> delegate;

/**
 Only use this initialiser to init this view controller. Passing through nil for the account will display an empty controller
 which can be used for a new account setup.
 */
- (id)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType;

@end
