//
//  WorkflowAttachmentsViewController.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 05/03/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "ParentListViewController.h"

@interface TasksAndAttachmentsViewController : ParentListViewController

@property (nonatomic, assign) UIEdgeInsets tableViewInsets;

- (instancetype)initWithTask:(AlfrescoWorkflowTask *)task session:(id<AlfrescoSession>)session;
- (instancetype)initWithProcess:(AlfrescoWorkflowProcess *)process session:(id<AlfrescoSession>)session;

@end
