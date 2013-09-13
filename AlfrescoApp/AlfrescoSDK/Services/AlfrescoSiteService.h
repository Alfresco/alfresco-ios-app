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
#import "AlfrescoRequest.h"

/** The AlfrescoSiteService provides various ways to retrieve sites from an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */


@interface AlfrescoSiteService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;


/**---------------------------------------------------------------------------------------
 * @name Retrieval methods for the Alfresco Site Service
 *  ---------------------------------------------------------------------------------------
 */

/** Retrieves all the sites in the repository.
 
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/** Retrieves sites in the repository with listing context.
 
 @param listingContext The listing context with a paging definition that's used to retrieve the nodes.
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveAllSitesWithListingContext:(AlfrescoListingContext *)listingContext
                           completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Retrieves all the sites for the current user of the session.
 
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves the sites for the current session user with listing context.
 
 @param listingContext The listing context with a paging definition that's used to retrieve the nodes.
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveSitesWithListingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;


/** Retrieves all the favorite sites for the current session user.
 
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Retrieves the favorite sites for the current session user with listing context.
 
 @param listingContext The listing context with a paging definition that's used to retrieve the nodes.
 @param completionBlock The block that's called with the retrieved sites in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveFavoriteSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Retrieves a site with the given short name, if the site doesn’t exist nil is returned.
 
 
 @param siteShortName The short name of the site that needs to be retrieved.
 @param completionBlock The block that's called with the retrieved site in case the operation succeeds.
 @warning the method can return both a nil error object and a nil site object. This is the case when a valid
 request has been made to the server to retrieve the site, but the site has not been found. 
 */
- (AlfrescoRequest *)retrieveSiteWithShortName:(NSString *)siteShortName
                  completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;

/** Retrieves the folder that represents the root of the Document Library for the site with the given short name.
 
 @param siteShortName The short name of the site for which the document library needs to be retrieved.
 @param completionBlock The block that's called with the retrieved document library folder in case the operation succeeds.
 */
- (AlfrescoRequest *)retrieveDocumentLibraryFolderForSite:(NSString *)siteShortName
                             completionBlock:(AlfrescoFolderCompletionBlock)completionBlock;


/**
 marks a site as favorite and adds it to the favorite list
 @param site the site to be added to favorites
 @param completionBlock - returns the updated AlfrescoSite object (isFavorite set to YES) or nil if unsuccessful
 */
- (AlfrescoRequest *)addFavoriteSite:(AlfrescoSite *)site
                     completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;

/**
 unmarks a site as favorite and removes it from the favorite list
 @param site the site to be added to favorites
 @param completionBlock - returns the updated AlfrescoSite object (isFavorite set to NO) or nil if unsuccessful
 */
- (AlfrescoRequest *)removeFavoriteSite:(AlfrescoSite *)site
                        completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;

/**
 creates a request to join a site. Please, note, this method works for both joining public and joining moderated sites.
 For public sites, the same AlfrescoSite object will be returned in the completion block.
 For moderated sites, an updated AlfrescoSite object will be returned - with pending flag set to YES.
 @param site - the site to join
 @param completionBlock - returns the updated AlfrescoSite object or nil if unsuccessful
 */
- (AlfrescoRequest *)joinSite:(AlfrescoSite *)site
              completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;

/**
 retrieves a list of sites for which a join request is pending
 @param completionBlock - returns an array of AlfrescoSite objects or nil if unsuccessful
 */
- (AlfrescoRequest *)retrievePendingSitesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


/**
 retrieves a list of pending join request sites with a specified listing context
 */
- (AlfrescoRequest *)retrievePendingSitesWithListingContext:(AlfrescoListingContext *)listingContext
                                            completionblock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/**
 cancels a join request for a specified site
 @param site - the pending site for which the join request is to be cancelled
 @param completionBlock - returns the updated AlfrescoSite object or nil if unsuccessful
 */
- (AlfrescoRequest *)cancelPendingJoinRequestForSite:(AlfrescoSite *)site
                                     completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;
/**
 leave a site
 @param site 
 @param completionBlock - returns the updated AlfrescoSite object or nil if unsuccessful
 */
- (AlfrescoRequest *)leaveSite:(AlfrescoSite *)site
               completionBlock:(AlfrescoSiteCompletionBlock)completionBlock;

/** Returns a list of all members for a site.
 @param site - site from which members are retrieved
 @param completionBlock - contains Array of person objects who are member of site if successful, or nil if not.
 */
- (AlfrescoRequest *)retrieveAllMembers:(AlfrescoSite *)site completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Returns a paged list of all members for a site.
 @param site - site from which members are retrieved
 @param listingContext - The listing context with a paging definition that's used to retrieve members.
 @param completionBlock - contains Array of person objects that are members of the site if successful, or nil if not.
 */
- (AlfrescoRequest *)retrieveAllMembers:(AlfrescoSite *)site
                     WithListingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Returns a paged list of all members for a site that respect the filter.
 @param site - site from which members are retrieved
 @param filter - filter that needs to be applied to search query.
 @param listingContext - The listing context with a paging definition that's used to retrieve members.
 @param completionBlock - contains Array of person objects that are members of the site if successful, or nil if not.
 */
- (AlfrescoRequest *)searchMembers:(AlfrescoSite *)site
                            filter:(NSString *)filter
                WithListingContext:(AlfrescoListingContext *)listingContext
                   completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** Returns true if the person is member of the site, returns false otherwise
 @param person - person for whome membership status is retrieved
 @param site - site from which membership status for the person is retrieved
 @param completionBlock - returns yes or no depending of person membership status in the site
 */
- (AlfrescoRequest *)isPerson:(AlfrescoPerson *)person memberOfSite:(AlfrescoSite *)site completionBlock:(AlfrescoMemberCompletionBlock)completionBlock;

/**
 clears the sites cache
 */
- (void)clear;

@end
