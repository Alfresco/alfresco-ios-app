//
//  TaskDetailsViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 24/02/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TaskDetailsViewController : UIViewController

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session;
- (instancetype)initWithProcess:(AlfrescoWorkflowProcess *)process session:(id<AlfrescoSession>)session;

@end
