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
#import "AlfrescoSession.h"
#import "AlfrescoComment.h"
#import "AlfrescoRequest.h"

/** The AlfrescoCommentService manages comments on nodes in an Alfresco 
 repository. The service provides CRUD methods to work with comments.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoCommentService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Comment retrieval methods.
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves the comments for the given node.
 
 @param node The node for which the comments are retrieved.
 @param completionBlock The block that's called with the retrieved comments in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves the comments for the given node with a listing context.
 
 @param node The node for which the comments are retrieved.
 @param listingContext The listing context with a paging definition that's used to retrieve the comments.
 @param completionBlock The block that's called with the retrieved comments in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node
                              listingContext:(AlfrescoListingContext *)listingContext
                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Editing comment methods.
 *  ---------------------------------------------------------------------------------------
 */

/** Adds a comment to a node.
 
 @param node The node to which a comments will be added.
 @param content The comment content.
 @param title The comment title.
 @param completionBlock The block that's called with the new comment in case the operation succeeds.
 */
- (AlfrescoRequest *)addCommentToNode:(AlfrescoNode *)node
                              content:(NSString *)content
                                title:(NSString *)title
                      completionBlock:(AlfrescoCommentCompletionBlock)completionBlock;

/** Updates a comment.
 
 @param node The node of the comment to be updated.
 @param comment The Comment of the node to be updated
 @param content The new comment content.
 @param completionBlock The block that's called with the updated comment in case the operation succeeds.
 */
- (AlfrescoRequest *)updateCommentOnNode:(AlfrescoNode *)node
                                 comment:(AlfrescoComment *)comment
                                 content:(NSString *)content
                         completionBlock:(AlfrescoCommentCompletionBlock)completionBlock;

/** Deletes a comment.
 
 @param node the node of the comment to be deleted
 @param comment The comment that needs to be deleted.
 @param completionBlock The block that's called in case the operation succeeds.
 */
- (AlfrescoRequest *)deleteCommentFromNode:(AlfrescoNode *)node
                                   comment:(AlfrescoComment *)comment
                           completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;

@end
