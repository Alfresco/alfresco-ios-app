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
#import "CMISAclService.h"
#import "CMISDiscoveryService.h"
#import "CMISMultiFilingService.h"
#import "CMISObjectService.h"
#import "CMISPolicyService.h"
#import "CMISRelationshipService.h"
#import "CMISRepositoryService.h"
#import "CMISNavigationService.h"
#import "CMISVersioningService.h"

@protocol CMISBinding <NSObject>

// The ACL service object for the binding
@property (nonatomic, strong, readonly) id<CMISAclService> aclService;

// The discovery service object for the binding
@property (nonatomic, strong, readonly) id<CMISDiscoveryService> discoveryService;

// The multi filing service object for the binding
@property (nonatomic, strong, readonly) id<CMISMultiFilingService> multiFilingService;

// The object service object for the binding
@property (nonatomic, strong, readonly) id<CMISObjectService> objectService;

// The policy service object for the binding
@property (nonatomic, strong, readonly) id<CMISPolicyService> policyService;

// The relationship service object for the binding
@property (nonatomic, strong, readonly) id<CMISRelationshipService> relationshipService;

// The repository service object for the binding
@property (nonatomic, strong, readonly) id<CMISRepositoryService> repositoryService;

// The navigation service object for the binding
@property (nonatomic, strong, readonly) id<CMISNavigationService> navigationService;

// The versioning service object for the binding
@property (nonatomic, strong, readonly) id<CMISVersioningService> versioningService;

/**
 closes the session
 */
- (void)close;

@optional

/**
 clears the cache from the session
 */
- (void)clearAllCaches;

/**
 clears the repository cache from the session
 @param repositoryId
 */
- (void)clearCacheForRepositoryId:(NSString*)repositoryId;

@end
