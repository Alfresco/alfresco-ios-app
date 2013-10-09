//
//  DocumentPreviewViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DocumentPreviewViewController : UIViewController

- (instancetype)initWithAlfrescoDocument:(AlfrescoDocument *)document permissions:(AlfrescoPermissions *)permissions session:(id<AlfrescoSession>)session;

@end
