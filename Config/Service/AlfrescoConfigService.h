/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
#import "AlfrescoActionConfig.h"
#import "AlfrescoActionGroupConfig.h"
#import "AlfrescoConfigInfo.h"
#import "AlfrescoConfigScope.h"
#import "AlfrescoCreationConfig.h"
#import "AlfrescoFeatureConfig.h"
#import "AlfrescoFormConfig.h"
#import "AlfrescoProfileConfig.h"
#import "AlfrescoRepositoryConfig.h"
#import "AlfrescoSearchConfig.h"
#import "AlfrescoViewConfig.h"
#import "AlfrescoViewGroupConfig.h"
#import "AlfrescoWorkflowConfig.h"

/**
 The AlfrescoConfigService allows apps to behave and provide capabilities based upon a 
 configuration file persisted in the repository.
 */
@interface AlfrescoConfigService : NSObject

@property (nonatomic, strong, readonly) AlfrescoConfigScope *defaultConfigScope;

/**---------------------------------------------------------------------------------------
 * @name Initialisation methods
 *  ---------------------------------------------------------------------------------------
 */

/** Initialises with a standard Cloud or OnPremise session.
 
 @param session the AlfrescoSession to initialise the config service with.
 */
- (id)initWithSession:(id<AlfrescoSession>)session;

/** Initialises with a dictionary of parameters.
 
 @param parameters A dictionary containing the paramters to initialise with.
 */
- (id)initWithDictionary:(NSDictionary *)parameters;

/**---------------------------------------------------------------------------------------
 * @name Config retrieval methods.
 *  ---------------------------------------------------------------------------------------
 */

- (AlfrescoRequest *)retrieveConfigInfoWithCompletionBlock:(AlfrescoConfigInfoCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveDefaultProfileWithCompletionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveProfileWithIdentifier:(NSString *)identifier
                                   completionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveProfilesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveRepositoryConfigWithCompletionBlock:(AlfrescoRepositoryConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFeatureConfigWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFeatureConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                          completionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                                   scope:(AlfrescoConfigScope *)scope
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                                     scope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveCreationConfigWithCompletionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock;


- (AlfrescoRequest *)retrieveCreationConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock;


/**
 Clears any cached state the service has.
 */
- (void)clear;

@end
