//
//  WorkflowHelper.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 02/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "WorkflowHelper.h"

static NSString * const kAlfrescoWorkflowActivitiEngine = @"activiti$";
static NSString * const kAlfrescoWorkflowJBPMEngine = @"jbpm$";

static NSString * const kAlfrescoActivitiWorkflowTypeAdhoc = @"activitiAdhoc";
static NSString * const kAlfrescoActivitiWorkflowTypeParallelReview = @"activitiParallelReview";
static NSString * const kAlfrescoActivitiWorkflowTypeReview = @"activitiReview";

static NSString * const kAlfrescoJBPMWorkflowTypeAdhoc = @"wf:adhoc";
static NSString * const kAlfrescoJBPMWorkflowTypeParallelReview = @"wf:parallelreview";
static NSString * const kAlfrescoJBPMWorkflowTypeReview = @"wf:review";

@implementation WorkflowHelper

+ (NSString *)processDefinitionKeyForWorkflowType:(WorkflowType)workflowType numberOfAssignees:(NSUInteger)numberOfAssignees session:(id<AlfrescoSession>)session
{
    NSString *processDefinitionKey = @"";
    
    BOOL doesSupportActivitiEngine = session.repositoryInfo.capabilities.doesSupportActivitiWorkflowEngine;
    BOOL doesSupportJBPMEngine = session.repositoryInfo.capabilities.doesSupportJBPMWorkflowEngine;
    
    // Activiti workflow engine is prioritised over JBPM if both are available
    if (workflowType == WorkflowTypeAdHoc)
    {
        processDefinitionKey = doesSupportActivitiEngine ? kAlfrescoActivitiWorkflowTypeAdhoc : kAlfrescoJBPMWorkflowTypeAdhoc;
    }
    else
    {
        if (numberOfAssignees == 1)
        {
            processDefinitionKey = doesSupportActivitiEngine ? kAlfrescoActivitiWorkflowTypeReview : kAlfrescoJBPMWorkflowTypeReview;
        }
        else
        {
            processDefinitionKey = doesSupportActivitiEngine ? kAlfrescoActivitiWorkflowTypeParallelReview : kAlfrescoJBPMWorkflowTypeParallelReview;
        }
    }
    
    if (!session.repositoryInfo.capabilities.doesSupportPublicAPI)
    {
        if (doesSupportActivitiEngine)
        {
            processDefinitionKey = [kAlfrescoWorkflowActivitiEngine stringByAppendingString:processDefinitionKey];
        }
        else if (doesSupportJBPMEngine)
        {
            processDefinitionKey = [kAlfrescoWorkflowJBPMEngine stringByAppendingString:processDefinitionKey];
        }
    }
    
    return processDefinitionKey;
}

+ (BOOL)isJBPMTask:(AlfrescoWorkflowTask *)task
{
    if ([task.identifier rangeOfString:kAlfrescoWorkflowJBPMEngine].location != NSNotFound)
    {
        return YES;
    }
    
    return NO;
}

@end
