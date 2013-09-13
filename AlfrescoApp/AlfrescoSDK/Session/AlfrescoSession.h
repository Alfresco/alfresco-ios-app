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
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoWorkflowInfo.h"

/** The AlfrescoSession category defines the properties made available for a session to an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco), Tauseef Mughal (Alfresco)
 */

// Protocol defining a session for an Alfresco based server.
@protocol AlfrescoSession <NSObject>

/**---------------------------------------------------------------------------------------
 * @name Properties.
 *  ---------------------------------------------------------------------------------------
 */
/// The currently authenticated user.
@property (nonatomic, strong, readonly) NSString *personIdentifier;


/// Information describing the repository the session is connected to.
@property (nonatomic, strong, readonly) AlfrescoRepositoryInfo *repositoryInfo;


/// The base URL of the repository.
@property (nonatomic, strong, readonly) NSURL *baseUrl;

/// The root folder of the repository.
@property (nonatomic, strong, readonly) AlfrescoFolder *rootFolder;

/// a default listing context for the session
@property (nonatomic, strong, readonly) AlfrescoListingContext *defaultListingContext;

/// The network provider, if this is not provided, a default implementation is set
@property (nonatomic, strong, readonly) id<AlfrescoNetworkProvider> networkProvider;

/// Information describing the workflow engine and api to use
@property (nonatomic, strong, readonly) AlfrescoWorkflowInfo *workflowInfo;


/**---------------------------------------------------------------------------------------
 * @name Methods for handling the Repository Settings
 *  ---------------------------------------------------------------------------------------
 */

/** Gives back all keys of the session data dictionary.
 
 @return All keys of the session data dictionary.
 */
- (NSArray *)allParameterKeys;

/** Gets a session data value for a specific key.
 
 @param key The key for the object to be retrieved.
 @return Session data value.
 */
- (id)objectForParameter:(id)key;


/** Adds an object to the session data.
 
 @param object The object to be added.
 @param key The key for the object to be added.
 */
- (void)setObject:(id)object forParameter:(id)key;

/** Adds an dictionary of objects to the session data.
 
 @param dictionary The dictionary of objects to be added.
 */
- (void)addParametersFromDictionary:(NSDictionary *)dictionary;

/** Removes a session data entry.
 
 @param key The key for the object to be removed.
 */
- (void)removeParameter:(id)key;

/**
 clears all caches associacted with this session
 */
- (void)clear;

@end