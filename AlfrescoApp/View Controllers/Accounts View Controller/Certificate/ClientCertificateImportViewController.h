//
//  ClientCertificateImportViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 09/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"

@class UserAccount;

@interface ClientCertificateImportViewController : ParentListViewController <UITextFieldDelegate>

- (id)initWithAccount:(UserAccount *)account andCertificatePath:(NSString *)certificatePath;

@end
