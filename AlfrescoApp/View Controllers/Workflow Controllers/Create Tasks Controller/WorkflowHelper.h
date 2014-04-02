//
//  WorkflowHelper.h
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, WorkflowType)
{
    WorkflowTypeTodo,
    WorkflowTypeReview,
    workflowTypeReviewAndApprove
};

@interface WorkflowHelper : NSObject

+ (NSString *)processDefinitionKeyForWorkflowType:(WorkflowType)workflowType session:(id<AlfrescoSession>)session;

@end
