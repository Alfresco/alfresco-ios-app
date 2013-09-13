/*
  Licensed to the Apache Software Foundation (ASF) under one
  or more contributor license agreements.  See the NOTICE file
  distributed with this work for additional information
  regarding copyright ownership.  The ASF licenses this file
  to you under the Apache License, Version 2.0 (the
  "License"); you may not use this file except in compliance
  with the License.  You may obtain a copy of the License at

    http://www.apache.org/licenses/LICENSE-2.0

  Unless required by applicable law or agreed to in writing,
  software distributed under the License is distributed on an
  "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
  KIND, either express or implied.  See the License for the
  specific language governing permissions and limitations
  under the License.
 */

#import <Foundation/Foundation.h>
#import "CMISBindingSession.h"
#import "CMISNetworkProvider.h"
#import "CMISRequest.h"
@class CMISAuthenticationProvider;

@interface CMISHttpRequest : NSObject <NSURLConnectionDelegate, NSURLConnectionDataDelegate, CMISCancellableRequest>

@property (nonatomic, assign) CMISHttpRequestMethod requestMethod;
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSData *requestBody;
@property (nonatomic, strong) NSMutableData *responseBody;
@property (nonatomic, strong) NSDictionary *additionalHeaders;
@property (nonatomic, strong) NSHTTPURLResponse *response;
@property (nonatomic, strong) id<CMISAuthenticationProvider> authenticationProvider;
@property (nonatomic, copy) void (^completionBlock)(CMISHttpResponse *httpResponse, NSError *error);

/**
 * starts a URL request for given HTTP method 
 * @param requestBody (optional)
 * @param additionalHeaders (optional)
 * @param authenticationProvider (required)
 * completionBlock returns a CMISHTTPResponse object or nil if unsuccessful
 */
+ (id)startRequest:(NSMutableURLRequest *)urlRequest
                      httpMethod:(CMISHttpRequestMethod)httpRequestMethod
                     requestBody:(NSData*)requestBody
                         headers:(NSDictionary*)additionalHeaders
          authenticationProvider:(id<CMISAuthenticationProvider>)authenticationProvider
                 completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;

/**
 * initialises with a specified HTTP method
 */
- (id)initWithHttpMethod:(CMISHttpRequestMethod)httpRequestMethod
         completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock;

/// starts the URL request
- (BOOL)startRequest:(NSMutableURLRequest*)urlRequest;

@end
