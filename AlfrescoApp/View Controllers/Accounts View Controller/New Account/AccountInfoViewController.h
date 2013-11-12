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

@interface AccountInfoViewController : ParentListViewController <UITextFieldDelegate>

- (id)initWithAccount:(UserAccount *)account;

@end
