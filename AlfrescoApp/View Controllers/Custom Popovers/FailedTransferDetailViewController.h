//
//  FailedTransferDetailViewController.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 08/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface FailedTransferDetailViewController : UIViewController

@property (nonatomic, strong) id userInfo;
@property (nonatomic, assign) SEL closeAction;
@property (nonatomic, assign) id closeTarget;

- (id)initWithTitle:(NSString *)title message:(NSString *)message;

@end
