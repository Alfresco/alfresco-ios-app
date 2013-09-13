/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

/** AlfrescoWorkflowTaskService
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowTaskService.h"
#import "AlfrescoWorkflowPlaceholderTaskService.h"

@implementation AlfrescoWorkflowTaskService

+ (id)alloc
{
    if (self == [AlfrescoWorkflowTaskService class])
    {
        return (id)[AlfrescoWorkflowPlaceholderTaskService alloc];
    }
    else
    {
        return [super alloc];
    }
}

- (id)initWithSession:(id<AlfrescoSession>)session
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveAllTasksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveTasksWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveTaskWithIdentifier:(NSString *)taskIdentifier completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

//- (AlfrescoRequest *)retrieveFormModelForTask:(AlfrescoWorkflowTask *)task completionBlock:(Return Type?)completionBlock;

- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveVariablesForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)completeTask:(AlfrescoWorkflowTask *)task properties:(NSDictionary *)properties completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)claimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)unclaimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)assignTask:(AlfrescoWorkflowTask *)task toAssignee:(AlfrescoPerson *)assignee completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)resolveTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)addAttachments:(NSArray *)nodeArray toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
