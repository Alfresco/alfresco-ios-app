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

/** AlfrescoWorkflowProcessService
 
 Author: Tauseef Mughal (Alfresco)
 */

#import "AlfrescoWorkflowProcessService.h"
#import "AlfrescoWorkflowPlaceholderProcessService.h"

@implementation AlfrescoWorkflowProcessService

+ (id)alloc
{
    if (self == [AlfrescoWorkflowProcessService self])
    {
        return (id)[AlfrescoWorkflowPlaceholderProcessService alloc];
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

- (AlfrescoRequest *)retrieveAllProcessesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessesWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state listingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessWithIdentifier:(NSString *)processID completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveVariablesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveAllTasksForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveTasksForProcess:(AlfrescoWorkflowProcess *)process inState:(NSString *)status completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

//- (AlfrescoRequest *)retrieveActivitiesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(???)completionBlock;

- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process outputStream:(NSOutputStream *)outputStream completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)startProcessForProcessDefinition:(AlfrescoWorkflowProcessDefinition *)processDefinition assignees:(NSArray *)assignees variables:(NSDictionary *)variables attachments:(NSArray *)attachmentNodes completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)deleteProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoProcessCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
