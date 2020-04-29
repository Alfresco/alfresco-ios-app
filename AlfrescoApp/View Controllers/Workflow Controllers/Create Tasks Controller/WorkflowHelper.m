/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 ******************************************************************************/
 
#import "WorkflowHelper.h"

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
