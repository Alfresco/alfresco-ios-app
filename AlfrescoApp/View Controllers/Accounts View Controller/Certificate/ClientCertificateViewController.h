//
//  CertificateLocationViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 09/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ParentListViewController.h"
#import "DownloadsViewController.h"

@class UserAccount;

@interface ClientCertificateViewController : ParentListViewController <DownloadsPickerDelegate>

- (id)initWithAccount:(UserAccount *)account;

@end
