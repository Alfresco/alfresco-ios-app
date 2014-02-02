//
//  AddNewAccountViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "CloudSignUpViewController.h"
#import "TTTAttributedLabel.h"

@class AccountTypeSelectionViewController;

@protocol AccountTypeSelectionViewControllerDelegate <NSObject>

@optional
- (void)accountTypeSelectionViewControllerWillDismiss:(AccountTypeSelectionViewController *)accountTypeSelectionViewController accountAdded:(BOOL)accountAdded;
- (void)accountTypeSelectionViewControllerDidDismiss:(AccountTypeSelectionViewController *)accountTypeSelectionViewController accountAdded:(BOOL)accountAdded;

@end

@interface AccountTypeSelectionViewController : ParentListViewController <TTTAttributedLabelDelegate, CloudSignUpViewControllerDelegate>

@property (nonatomic, weak) id<AccountTypeSelectionViewControllerDelegate> delegate;

- (instancetype)initWithDelegate:(id<AccountTypeSelectionViewControllerDelegate>)delegate;

@end
