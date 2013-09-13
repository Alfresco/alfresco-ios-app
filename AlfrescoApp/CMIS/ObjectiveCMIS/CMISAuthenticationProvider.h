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

@protocol CMISAuthenticationProvider <NSObject>

/**
* Returns a set of HTTP headers (key-value pairs) that should be added to a
* HTTP call. This will be called by the AtomPub and the Web Services
* binding. You might want to check the binding in use before you set the
* headers.
*
* @return the HTTP headers or nil if no additional headers should be set
*/
@property(nonatomic, strong, readonly) NSDictionary *httpHeadersToApply;

/**
 * updates the provider with NSHTTPURLResponse
 */
- (void)updateWithHttpURLResponse:(NSHTTPURLResponse*)httpUrlResponse;

/**
 * checks if provider can authenticate against provided protection space
 */
- (BOOL)canAuthenticateAgainstProtectionSpace:(NSURLProtectionSpace *)protectionSpace;

/**
 * callback when authentication challenge was cancelled
 */
- (void)didCancelAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

/**
 * callback when authentication challenge was received
 */
- (void)didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge;

@end
