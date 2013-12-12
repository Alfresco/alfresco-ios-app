//
//  TextFileViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol UploadFormViewControllerDelegate;

@interface TextFileViewController : UIViewController

- (instancetype)initWithUploadFileDestinationFolder:(AlfrescoFolder *)uploadFolder session:(id<AlfrescoSession>)session delegate:(id<UploadFormViewControllerDelegate>)delegate;

@end
