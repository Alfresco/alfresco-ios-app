//
//  WorkflowHelper.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

typedef NS_ENUM(NSInteger, WorkflowType)
{
    WorkflowTypeAdHoc,
    WorkflowTypeReview
};

@interface WorkflowHelper : NSObject

+ (NSString *)processDefinitionKeyForWorkflowType:(WorkflowType)workflowType numberOfAssignees:(NSUInteger)numberOfAssignees session:(id<AlfrescoSession>)session;
+ (BOOL)isJBPMTask:(AlfrescoWorkflowTask *)task;

@end
