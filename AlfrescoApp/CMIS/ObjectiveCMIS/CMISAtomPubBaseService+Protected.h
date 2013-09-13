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
#import "CMISAtomPubBaseService.h"
#import "CMISObjectByIdUriBuilder.h"

@class CMISObjectData;

@interface CMISAtomPubBaseService (Protected)

/** retrieve object from cache
 * completionBlock returns the object (as id) or nil if unsuccessul
 */
- (void)retrieveFromCache:(NSString *)cacheKey
              cmisRequest:(CMISRequest *)cmisRequest
          completionBlock:(void (^)(id object, NSError *error))completionBlock;

/**
 fetches the repo info
 */
- (void)fetchRepositoryInfoWithCMISRequest:(CMISRequest *)cmisRequest
                           completionBlock:(void (^)(NSError *error))completionBlock;

/**
 retrieves the CMIS workspace
 */
- (void)retrieveCMISWorkspacesWithCMISRequest:(CMISRequest *)cmisRequest
                              completionBlock:(void (^)(NSArray *workspaces, NSError *error))completionBlock;


/** Convenience method with all the defaults for the retrieval parameters */
- (void)retrieveObjectInternal:(NSString *)objectId
                   cmisRequest:(CMISRequest *)cmisRequest
               completionBlock:(void (^)(CMISObjectData *objectData, NSError *error))completionBlock;

/** Full-blown object retrieval version 
 * completionBlock returns CMISObjectData instance or nil if unsuccessul
 */
- (void)retrieveObjectInternal:(NSString *)objectId
                 returnVersion:(CMISReturnVersion)cmisReturnVersion
                        filter:(NSString *)filter
                 relationships:(CMISIncludeRelationship)relationships
              includePolicyIds:(BOOL)includePolicyIds
               renditionFilder:(NSString *)renditionFilter
                    includeACL:(BOOL)includeACL
       includeAllowableActions:(BOOL)includeAllowableActions
                   cmisRequest:(CMISRequest *)cmisRequest
               completionBlock:(void (^)(CMISObjectData *objectData, NSError *error))completionBlock;

/** retrieve object for a given path name
 * completionBlock returns CMISObjectData instance or nil if unsuccessul
 */
- (void)retrieveObjectByPathInternal:(NSString *)path
                              filter:(NSString *)filter
                       relationships:(CMISIncludeRelationship)relationships
                    includePolicyIds:(BOOL)includePolicyIds
                     renditionFilder:(NSString *)renditionFilter
                          includeACL:(BOOL)includeACL
             includeAllowableActions:(BOOL)includeAllowableActions
                         cmisRequest:(CMISRequest *)cmisRequest
                     completionBlock:(void (^)(CMISObjectData *objectData, NSError *error))completionBlock;


///load the link for a given object Id
///completionBlock returns the link as NSString or nil if unsuccessful
- (void)loadLinkForObjectId:(NSString *)objectId
                   relation:(NSString *)rel
                cmisRequest:(CMISRequest *)cmisRequest
            completionBlock:(void (^)(NSString *link, NSError *error))completionBlock;

///load the link for a given object Id
///completionBlock returns the link as NSString or nil if unsuccessful
- (void)loadLinkForObjectId:(NSString *)objectId
                   relation:(NSString *)rel
                       type:(NSString *)type
                cmisRequest:(CMISRequest *)cmisRequest
            completionBlock:(void (^)(NSString *link, NSError *error))completionBlock;

@end
