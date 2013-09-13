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

#import <Foundation/Foundation.h>
#import "AlfrescoRequest.h"
#import "AlfrescoConstants.h"
#import "AlfrescoWorkflowTask.h"

@interface AlfrescoWorkflowTaskService : NSObject

/** Initialises with a public or old API implementation
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Retrieval methods for the Alfresco Workflow Task Service
 *  ---------------------------------------------------------------------------------------
 */

- (AlfrescoRequest *)retrieveAllTasksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns a paged result of the tasks the authenticated user is allowed to see
- (AlfrescoRequest *)retrieveTasksWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

// Retrieves the task for the given task identifier. Returns the updated Task.
- (AlfrescoRequest *)retrieveTaskWithIdentifier:(NSString *)taskIdentifier completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

// Returns the form model for the given task
//- (AlfrescoRequest *)retrieveFormModelForTask:(AlfrescoWorkflowTask *)task completionBlock:(Return Type?)completionBlock;

// Returns an array of AlfrescoDocument objects of attachment to the provided task. Nil, if there are no attachments
- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Retrieves variables on a given task
- (AlfrescoRequest *)retrieveVariablesForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Task assignment methods for the Alfresco Workflow Task Service
 *  ---------------------------------------------------------------------------------------
 */

// Completes the provided task
- (AlfrescoRequest *)completeTask:(AlfrescoWorkflowTask *)task properties:(NSDictionary *)properties completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

// Claims the task for the authenticated user. Returns the updated Task.
- (AlfrescoRequest *)claimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

// Unclaims a task and sets the assignee to "Unassigned". Returns the updated Task.
- (AlfrescoRequest *)unclaimTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

// Assigns the given task to the assignee provided. Returns the updated AlfrescoWorkflowTask object
- (AlfrescoRequest *)assignTask:(AlfrescoWorkflowTask *)task toAssignee:(AlfrescoPerson *)assignee completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

// Resolves the task, and assigns the task back to the owner
- (AlfrescoRequest *)resolveTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Add methods for the Alfresco Workflow Task Service
 *  ---------------------------------------------------------------------------------------
 */

// Adds a single AlfrescoNode to a given task
- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

// Adds an array of AlfrescoNodes to a task
- (AlfrescoRequest *)addAttachments:(NSArray *)nodeArray toTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Update methods for the Alfresco Workflow Task Service
 *  ---------------------------------------------------------------------------------------
 */

// Updates the variables provided on the given task. Variables that are not currently present will be added to the task
- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Removal methods for the Alfresco Workflow Task Service
 *  ---------------------------------------------------------------------------------------
 */

// Removes the item from the task
- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

// Removes the list of variables provided on the given task
- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoTaskCompletionBlock)completionBlock;

@end
