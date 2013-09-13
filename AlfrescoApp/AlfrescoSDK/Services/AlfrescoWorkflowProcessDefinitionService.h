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

/** AlfrescoWorkflowProcessDefinitionService
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>
#import "AlfrescoConstants.h"
#import "AlfrescoRequest.h"

@interface AlfrescoWorkflowProcessDefinitionService : NSObject

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

// Returns a list of all process definitions
- (AlfrescoRequest *)retrieveAllProcessDefinitionsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

// Returns a paged result of the process defintions
- (AlfrescoRequest *)retrieveProcessDefinitionsWithListingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

// Returns a process definition for a given process identifier
- (AlfrescoRequest *)retrieveProcessDefinitionWithIdentifier:(NSString *)processIdentifier completionBlock:(AlfrescoProcessDefinitionCompletionBlock)completionBlock;

// Returns the form model for the given task ID
- (AlfrescoRequest *)retrieveFormModelForProcess:(NSString *)processDefinitionId completionBlock:(AlfrescoDictionaryCompletionBlock)completionBlock;

@end
