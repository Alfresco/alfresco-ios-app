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
#import "CMISAuthenticationProvider.h"

@interface CMISStandardAuthenticationProvider : NSObject <CMISAuthenticationProvider>

@property (nonatomic, strong) NSURLCredential *credential;

/** Initialize with username and password that will be added as authorization header
 * @param username
 * @param password
 */
- (id)initWithUsername:(NSString *)username password:(NSString *)password;

/** Initialize with a credential object that will be provided when a corresponding challenge is received from the server.
 * Both client certificate and username / password credentials are supported
 * @param credential
 */
- (id)initWithCredential:(NSURLCredential *)credential;

@end