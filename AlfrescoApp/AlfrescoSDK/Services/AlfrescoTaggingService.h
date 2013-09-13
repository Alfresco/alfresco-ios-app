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
#import "AlfrescoSession.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoNode.h"
#import "AlfrescoRequest.h"

/** The AlfrescoTaggingService provides various ways to retrieve tags and can add tags to a node
 in a Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoTaggingService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
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

/** Retrieves all tags available in the repository.
 
 @param completionBlock The block that's called with the retrieved tags in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllTagsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves all tags available in the repository with a listing context.
 
 @param listingContext The listing context with a paging definition that's used to retrieve the tags.
 @param completionBlock The block that's called with the retrieved tags in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllTagsWithListingContext:(AlfrescoListingContext *)listingContext
                                       completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Retrieves all tags applied to a given node.
 
 @param node The node for which the tags should be retrieved.
 @param completionBlock The block that's called with the retrieved tags in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                         completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves all tags applied to a given node with a listing context.
 
 @param node The node for which the tags should be retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the tags.
 @param completionBlock The block that's called with the retrieved tags in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                          listingContext:(AlfrescoListingContext *)listingContext
                         completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Adds the given tags to the given node.
 *  ---------------------------------------------------------------------------------------
 */

/** Adds the given tags to the given node.
 
 @param tags The tags that should be added.
 @param node The node to which the tags should be added.
 @param completionBlock The block that's called with the retrieved tags in case the operation succeeds.
 */
- (AlfrescoRequest *)addTags:(NSArray *)tags
                      toNode:(AlfrescoNode *)node
             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

@end
