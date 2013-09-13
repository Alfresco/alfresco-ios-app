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
#import "AlfrescoKeywordSearchOptions.h"
#import "AlfrescoSearchLanguage.h"
#import "AlfrescoRequest.h"

/** The AlfrescoSearchService provides various ways to search an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoSearchService : NSObject

/**---------------------------------------------------------------------------------------
 * @name Initialialisation
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session
 
 @param session the AlfrescoSession to initialise the site service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/**---------------------------------------------------------------------------------------
 * @name Searches methods.
 *  ---------------------------------------------------------------------------------------
 */

/** Performs a search based on the search statement and given query language. Query language can be either
 CMIS SQL. For this a valid CMIS SQL statement needs to be passed to the method.
 The alternative is to use a space delimeted keyword string
 
 @param statement the search statement.
 @param language the query language to be used.
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)searchWithStatement:(NSString *)statement
                                language:(AlfrescoSearchLanguage)language
                         completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Performs a space delimited keyword search with or without exact matches, optionally including the results of a full text search.
 
 @param statement the search statement.
 @param language the query language to be used.
 @param listingContext the ListingContext options used for paging
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)searchWithStatement:(NSString *)statement
                                language:(AlfrescoSearchLanguage)language
                          listingContext:(AlfrescoListingContext *)listingContext
                         completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

/** 
 Performs a space delimited keyword search with or without exact matches, optionally including the results of a full text search.
 The method uses 
 
 @param keywords the search strings.
 @param options the AlfrescoKeywordSearchOptions objects with the search settings.
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)searchWithKeywords:(NSString *)keywords
                                options:(AlfrescoKeywordSearchOptions *)options
                        completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;

/** Performs a space delimited keyword search with or without exact matches, optionally including the results of a full text search.
 
 @param keywords the search strings.
 @param options the AlfrescoKeywordSearchOptions objects with the search settings.
 @param listingContext the ListingContext options used for paging
 @param completionBlock The block that's called with the retrieved nodes in case the operation succeeds.
 */
- (AlfrescoRequest *)searchWithKeywords:(NSString *)keywords
                                options:(AlfrescoKeywordSearchOptions *)options
                         listingContext:(AlfrescoListingContext *)listingContext
                        completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock;

@end

