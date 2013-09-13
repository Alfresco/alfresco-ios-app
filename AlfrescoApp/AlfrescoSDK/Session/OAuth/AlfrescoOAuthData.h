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
/** The AlfrescoOAuthData stores details required for authentication using OAuth services.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoOAuthData : NSObject <NSCoding>
@property (nonatomic, strong, readonly) NSString * accessToken;
@property (nonatomic, strong, readonly) NSString * refreshToken;
@property (nonatomic, strong, readonly) NSNumber * expiresIn;
@property (nonatomic, strong, readonly) NSString * tokenType;
@property (nonatomic, strong, readonly) NSString * scope;
@property (nonatomic, strong, readonly) NSString * apiKey;
@property (nonatomic, strong, readonly) NSString * secretKey;
@property (nonatomic, strong, readonly) NSString * redirectURI;


/**---------------------------------------------------------------------------------------
 * @name Initialisers for OAuth data
 *  ---------------------------------------------------------------------------------------
 */

/**
 This initialiser is typically used for the first step of authentication, i.e. obtaining the authorization code.
 The Alfresco default redirect URI is taken as a value
 @param apiKey
 @param secretKey
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey;

/**
 This initialiser is typically used for the first step of authentication, i.e. obtaining the authorization code.
 @param apiKey
 @param secretKey
 @param redirectURI
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI;

/**
 This initialised is typically used for subsequent authentication steps, e.g. obtaining the access token or refresh token.
 The Alfresco default redirect URI is taken as a value
 @param apiKey
 @param secretKey
 @param jsonDictionary
 */

- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
      jsonDictionary:(NSDictionary *)jsonDictionary;
/**
 @param apiKey
 @param secretKey
 @param redirectURI
 @param jsonDictionary
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI
      jsonDictionary:(NSDictionary *)jsonDictionary;
@end
