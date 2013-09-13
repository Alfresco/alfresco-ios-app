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
#import "CMISRepositoryInfo.h"

@class CMISTypeDefinition;
@class CMISRequest;

@protocol CMISRepositoryService <NSObject>

/**
 * Returns an array of CMISRepositoryInfo objects representing the repositories available at the endpoint.
 * completionBlock returns array of repositories or nil if unsuccessful
 */
- (CMISRequest*)retrieveRepositoriesWithCompletionBlock:(void (^)(NSArray *repositories, NSError *error))completionBlock;

/**
 * Returns the repository info for the repository with the given id
 * completionBlock returns repository or nil if unsuccessful
 */
- (CMISRequest*)retrieveRepositoryInfoForId:(NSString *)repositoryId
                    completionBlock:(void (^)(CMISRepositoryInfo *repositoryInfo, NSError *error))completionBlock;

/**
 * Returns the type definitions
 * completionBlock returns type definition or nil if unsuccessful
 */
- (CMISRequest*)retrieveTypeDefinition:(NSString *)typeId
               completionBlock:(void (^)(CMISTypeDefinition *typeDefinition, NSError *error))completionBlock;

@end
