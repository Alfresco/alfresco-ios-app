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

#import <UIKit/UIKit.h>
#import "AlfrescoConstants.h"
#import "AlfrescoOAuthLoginDelegate.h"

/** The AlfrescoOAuthLoginViewController starts the OAuth authentication processes.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoOAuthLoginViewController : UIViewController <UIWebViewDelegate, NSURLConnectionDelegate, NSURLConnectionDataDelegate, UIAlertViewDelegate>
/// @param webView - holds the login HTML page
@property (nonatomic, strong) UIWebView * webView;
/// @param activityIndicator - indicates loading process
@property (nonatomic, strong) UIActivityIndicatorView * activityIndicator;
/// @param oauthDelegate - call back for when things go wrong
@property (nonatomic, weak) id<AlfrescoOAuthLoginDelegate> oauthDelegate;
/**
 @name Initialisers
 The AlfrescoOAuthLoginViewController has 4 different initialisers available. At the minimum an apiKey, secretKey and completionBlock must be provided.
 */

/**
 This initialiser is using the default Alfresco redirect URI
 @param apiKey
 @param secretKey
 @param completionBlock
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;

/**
 @param apiKey
 @param secretKey
 @param redirectURI
 @param completionBlock
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;

/**
 This initialiser is using the default Alfresco redirect URI
 @param apiKey
 @param secretKey
 @param completionBlock
 @param parameters (optional)
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
          parameters:(NSDictionary *)parameters
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;

/**
 @param apiKey
 @param secretKey
 @param redirectURI
 @param parameters - (optional)
 @param completionBlock
 */
- (id)initWithAPIKey:(NSString *)apiKey
           secretKey:(NSString *)secretKey
         redirectURI:(NSString *)redirectURI
          parameters:(NSDictionary *)parameters
     completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock;

@end
