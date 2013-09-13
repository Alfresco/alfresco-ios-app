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

#import "AlfrescoSession.h"
#import "AlfrescoFolder.h"
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoConstants.h"
#import "AlfrescoCloudNetwork.h"
#import "AlfrescoOAuthData.h"
#import "AlfrescoRequest.h"
/** The AlfrescoCloudSession manages the session on Alfresco Cloud.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoCloudSession : NSObject <AlfrescoSession>
@property (nonatomic, strong, readonly) AlfrescoCloudNetwork *network;

/**
 There is a custom setter method of oauthData, which is used for refreshing access tokens. This resets the authentication and CMIS session.
 For initialising a AlfrescoCloudSession, one of the connectWithOAuthData methods must be used.
 @param oauthData
 */
@property (nonatomic, strong) AlfrescoOAuthData *oauthData;



/**
 This initialiser uses OAuth authentication processes. It will only be successful if the AlfrescoOAuthData contain a valid access and refresh token.
 Therefore, this method should only be used after the initial OAuth setup is complete.
 The method well set the home network/tenant ID as default
 @param oauthData
 @param completionBlock
 */
+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;


/**
 This initialiser uses OAuth authentication processes. It will only be successful if the AlfrescoOAuthData contain a valid access and refresh token.
 Therefore, this method should only be used after the initial OAuth setup is complete.
 The method well set the home network/tenant ID as default
 @param oauthData
 @param parameters - optional, may be nil
 @param completionBlock
 */
+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                               parameters:(NSDictionary *)parameters
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

/**
 This initialiser uses OAuth authentication processes. It will only be successful if the AlfrescoOAuthData contain a valid access and refresh token.
 Therefore, this method should only be used after the initial OAuth setup is complete.
 The method well set to the specified network/tenant ID.
 @param oauthData
 @param networkIdentifer - also known as tenent ID
 @param completionBlock
 */
+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                         networkIdentifer:(NSString *)networkIdentifer
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;

/**
 This initialiser uses OAuth authentication processes. It will only be successful if the AlfrescoOAuthData contain a valid access and refresh token.
 Therefore, this method should only be used after the initial OAuth setup is complete.
 The method well set to the specified network/tenant ID.
 @param oauthData
 @param networkIdentifer - also known as tenent ID
 @param parameters - optional, may be nil
 @param completionBlock
 */
+ (AlfrescoRequest *)connectWithOAuthData:(AlfrescoOAuthData *)oauthData
                         networkIdentifer:(NSString *)networkIdentifer
                               parameters:(NSDictionary *)parameters
                          completionBlock:(AlfrescoSessionCompletionBlock)completionBlock;


/**
 This method obtains a list of available Cloud networks (or domains/tenants) for the registered user.
 @param completionBlock (AlfrescoArrayCompletionBlock). If successful, the block returns an NSArray object with a list of available networks - or nil if error occurs.
 */
- (AlfrescoRequest *)retrieveNetworksWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock;


@end
