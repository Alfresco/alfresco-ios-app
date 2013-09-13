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

/** All custom network providers need to implement the AlfrescoNetworkProvider.
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>
#import "AlfrescoConstants.h"
#import "AlfrescoRequest.h"

@protocol AlfrescoSession;

@protocol AlfrescoNetworkProvider <NSObject>

- (void)executeRequestWithURL:(NSURL *)url
                      session:(id<AlfrescoSession>)session
              alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
              completionBlock:(AlfrescoDataCompletionBlock)completionBlock;

- (void)executeRequestWithURL:(NSURL *)url
                      session:(id<AlfrescoSession>)session
              alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
                 outputStream:(NSOutputStream *)outputStream
              completionBlock:(AlfrescoDataCompletionBlock)completionBlock;

- (void)executeRequestWithURL:(NSURL *)url
                      session:(id<AlfrescoSession>)session
                       method:(NSString *)method
              alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
              completionBlock:(AlfrescoDataCompletionBlock)completionBlock;

- (void)executeRequestWithURL:(NSURL *)url
                      session:(id<AlfrescoSession>)session
                  requestBody:(NSData *)requestBody
                       method:(NSString *)method
              alfrescoRequest:(AlfrescoRequest *)alfrescoRequest
              completionBlock:(AlfrescoDataCompletionBlock)completionBlock;

@end
