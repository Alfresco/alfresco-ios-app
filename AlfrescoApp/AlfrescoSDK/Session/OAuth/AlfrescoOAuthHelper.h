/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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
#import "AlfrescoOAuthLoginViewController.h"
#import "AlfrescoOAuthLoginDelegate.h"
/** The AlfrescoOAuthHelper handles OAuth authentication processes.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoOAuthHelper : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

/**
 this is an internal initialiser used for testing purposes only. Do not use for production services
 @param parameters
 */
- (id)initWithParameters:(NSDictionary *)parameters;

- (id)initWithParameters:(NSDictionary *)parameters delegate:(id<AlfrescoOAuthLoginDelegate>)oauthDelegate;

/**
 @param authorizationCode the authorization code retrieved from the Cloud server at first login
 @param oauthData - the AlfrescoOAuthData. This object must have the api key, secret key and redirect URI set
 @param completionBlock
 */
- (void)retrieveOAuthDataForAuthorizationCode:(NSString *)authorizationCode
                                    oauthData:(AlfrescoOAuthData *)oauthData
                              completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;


/**
 @param oauthData - the AlfrescoOAuthData, used for refreshing the access token. For that the AlfrescoOAuthData set needs to contain the api key, secret key, refresh token, and current access token 
 @param completionBlock
 */
- (void)refreshAccessToken:(AlfrescoOAuthData *)oauthData
           completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;



@end

