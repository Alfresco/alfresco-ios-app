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
#import "AlfrescoNode.h"
#import "AlfrescoConstants.h"
#import "AlfrescoRequest.h"

/** The AlfrescoRatingService is used for rating (like/unlike) nodes on the repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoRatingService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 For OnPremise sessions, the initialiser checks, whether the repository has Ratings capabilities. They are 
 available only for Alfresco OnPremise server versions 4 or higher. For Repository versions below version 4,
 the initialiser will return NIL.
 
 Cloud services always have Rating Services enabled.
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Retrieval and rating check methods 
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves the number of likes for the given node.
 
 @param node The node for which the like count needs to be retrieved.
 @param completionBlock The block that's called with the like count in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveLikeCountForNode:(AlfrescoNode *)node
                 completionBlock:(AlfrescoNumberCompletionBlock)completionBlock;


/** Has the user liked the given node?
 
 @param node The node for which the like rating should be validated.
 @param completionBlock The block that's called in case the operation succeeds.
 */
- (AlfrescoRequest *)isNodeLiked:(AlfrescoNode *)node
    completionBlock:(AlfrescoLikedCompletionBlock)completionBlock;

/**---------------------------------------------------------------------------------------
 * @name Rating methods
 *  ---------------------------------------------------------------------------------------
 */

/** Adds a like rating to the given node.
 
 @param node The node for which the like rating should be added.
 @param completionBlock The block that's called in case the operation succeeds.
 */
- (AlfrescoRequest *)likeNode:(AlfrescoNode *)node 
 completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;


/** Removes the like rating from the given node.
 
 @param node The node for which the like rating should be removed.
 @param completionBlock The block that's called in case the operation succeeds.
 */
- (AlfrescoRequest *)unlikeNode:(AlfrescoNode *)node
   completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock;



@end
