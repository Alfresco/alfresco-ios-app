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

#import <Foundation/Foundation.h>
#import "AlfrescoRequest.h"
#import "AlfrescoConstants.h"

@class AlfrescoWorkflowProcessDefinition;

@interface AlfrescoWorkflowProcessService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a public or old API implementation
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Retrieval methods for the Alfresco Workflow Process Service
 *  ---------------------------------------------------------------------------------------
 */
- (AlfrescoRequest *)retrieveAllProcessesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns a paged result of processes in accordance to the listing context provided.
- (AlfrescoRequest *)retrieveProcessesWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

// Returns an array of processes that are within a given state
- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns a paged result of the of processes that are within a given state in accordance to the listing context provided
- (AlfrescoRequest *)retrieveProcessesInState:(NSString *)state listingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

// Returns a process for a given process identifier
- (AlfrescoRequest *)retrieveProcessWithIdentifier:(NSString *)processID completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

// Retrieves variables on a given process
- (AlfrescoRequest *)retrieveVariablesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

// Returns an array of all tasks that the user is able to see. Tasks are returned if the user created of is part of a given task.
- (AlfrescoRequest *)retrieveAllTasksForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns an array of tasks that the user is able to see and are in the status provided. Tasks are returned if the user created of is part of a given task.
- (AlfrescoRequest *)retrieveTasksForProcess:(AlfrescoWorkflowProcess *)process inState:(NSString *)status completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns an array of AlfrescoNode objects of attachment to the provided process.
- (AlfrescoRequest *)retrieveAttachmentsForTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

//// Returns an array of Activites for the given process
//- (AlfrescoRequest *)retrieveActivitiesForProcess:(AlfrescoWorkflowProcess *)process completionBlock:(???)completionBlock;

// Returns an image of the process. An image is only returned if the user has started the process or is involved in any of the tasks
- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock;

// Returns an image of the process. An image is only returned if the user has started the process or is involved in any of the tasks.
- (AlfrescoRequest *)retrieveProcessImage:(AlfrescoWorkflowProcess *)process outputStream:(NSOutputStream *)outputStream completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Add methods for the Alfresco Workflow Process Service
 *  ---------------------------------------------------------------------------------------
 */

// creates and starts a process
- (AlfrescoRequest *)startProcessForProcessDefinition:(AlfrescoWorkflowProcessDefinition *)processDefinition assignees:(NSArray *)assignees variables:(NSDictionary *)variables attachments:(NSArray *)attachmentNodes completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

// adds an AlfrescoNode to a givven process
- (AlfrescoRequest *)addAttachment:(AlfrescoNode *)node toProcess:(AlfrescoWorkflowTask *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Update methods for the Alfresco Workflow Process Service
 *  ---------------------------------------------------------------------------------------
 */

// Updates the variables provided on the given process. Variables that are not currently present will be added to the process
- (AlfrescoRequest *)updateVariables:(NSDictionary *)variables forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Removal methods for the Alfresco Workflow Process Service
 *  ---------------------------------------------------------------------------------------
 */

// Deletes a process
- (AlfrescoRequest *)deleteProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

// Removes the list of variables provided on the given process
- (AlfrescoRequest *)removeVariables:(NSArray *)variablesKeys forProcess:(AlfrescoWorkflowProcess *)process completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

// Removes the item from the process
- (AlfrescoRequest *)removeAttachment:(AlfrescoNode *)node fromTask:(AlfrescoWorkflowTask *)task completionBlock:(AlfrescoProcessCompletionBlock)completionBlock;

@end
