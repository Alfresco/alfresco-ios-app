/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
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

#import <Foundation/Foundation.h>
#import "AlfrescoConstants.h"
#import "AlfrescoDocument.h"
#import "AlfrescoRequest.h"
/** The AlfrescoVersionService provides ways to get all versions of a specific document.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoVersionService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Retrieval methods.
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves all versions of the given document.
 
 @param document The document for which all versions should be retrieved.
 @param completionBlock The block that's called with the retrieved versions in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllVersionsOfDocument:(AlfrescoDocument *)document
                      completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves all versions of the given document with a listing context.
 
 @param document The document for which all versions should be retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the versions.
 @param completionBlock The block that's called with the retrieved versions in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllVersionsOfDocument:(AlfrescoDocument *)document
                       listingContext:(AlfrescoListingContext *)listingContext
                      completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

@end
