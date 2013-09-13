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

#import "CMISHttpRequest.h"

@interface CMISHttpDownloadRequest : CMISHttpRequest 

// the outputStream should be unopened but if it is already open it will not be reset but used as is;
// it is closed on completion; if no outputStream is provided, download goes to httpResponse.data
@property (nonatomic, strong) NSOutputStream *outputStream;

// optional; if not set, expected content length from HTTP header is used
@property (nonatomic, assign) unsigned long long bytesExpected;

@property (nonatomic, readonly) unsigned long long bytesDownloaded;

/** starts a URL request for download. Data are written to the provided output stream
 * completionBlock returns a CMISHttpResponse object or nil if unsuccessful
 */
+ (id)startRequest:(NSMutableURLRequest*)urlRequest
                              httpMethod:(CMISHttpRequestMethod)httpRequestMethod
                            outputStream:(NSOutputStream*)outputStream
                           bytesExpected:(unsigned long long)bytesExpected
                  authenticationProvider:(id<CMISAuthenticationProvider>) authenticationProvider
                         completionBlock:(void (^)(CMISHttpResponse *httpResponse, NSError *error))completionBlock
                           progressBlock:(void (^)(unsigned long long bytesDownloaded, unsigned long long bytesTotal))progressBlock;

@end
