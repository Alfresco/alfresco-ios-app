//
//  CloudSignUpViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 06/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "TTTAttributedLabel.h"
@class UserAccount;

@interface CloudSignUpViewController : ParentListViewController <UITextFieldDelegate, TTTAttributedLabelDelegate>

/*
 * Initializer with account for which information is displayed or pass nil for account if signing up for new cloud account
 */
- (id)initWithAccount:(UserAccount *)account;

@end
