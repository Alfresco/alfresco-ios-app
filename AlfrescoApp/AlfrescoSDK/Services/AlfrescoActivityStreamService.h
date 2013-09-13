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
#import "AlfrescoSite.h"
#import "AlfrescoListingContext.h"
#import "AlfrescoActivityEntry.h"
#import "AlfrescoRequest.h"

/** The AlfrescoActivityStreamService provides various ways to retrieve an activity stream.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoActivityStreamService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Activities Retrieval methods
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves all activities for the logged-in user.
 
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveActivityStreamWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves all activities for the logged-in user with a listing context.
 
 @param listingContext The listing context with a paging definition that's used to retrieve the activity stream.
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveActivityStreamWithListingContext:(AlfrescoListingContext *)listingContext
                             completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Retrieves all activities for the given user.
 
 @param personIdentifier The user name to be used to retrieve the user's activity stream.
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */ 
- (AlfrescoRequest *)retrieveActivityStreamForPerson:(NSString *)personIdentifier 
                      completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves all activities for the given user with a listing context.
 
 @param personIdentifier The user name to be used to retrieve the user's activity stream.
 @param listingContext The listing context with a paging definition that's used to retrieve the activity stream.
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveActivityStreamForPerson:(NSString *)personIdentifier 
                         listingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Retrieves all activities for the given site.
 
 @param site The site to be used to retrieve the site's activity stream.
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */ 
- (AlfrescoRequest *)retrieveActivityStreamForSite:(AlfrescoSite *)site 
                      completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves all activities for the given site with a listing context.
 
 @param site The site to be used to retrieve the site's activity stream.
 @param listingContext The listing context with a paging definition that's used to retrieve the activity stream.
 @param completionBlock The block that's called with the activity stream in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveActivityStreamForSite:(AlfrescoSite *)site
                       listingContext:(AlfrescoListingContext *)listingContext
                      completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;



@end
