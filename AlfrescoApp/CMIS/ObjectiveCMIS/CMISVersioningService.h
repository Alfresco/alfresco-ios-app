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
#import "CMISEnums.h"

@class CMISCollection;
@class CMISObject;
@class CMISObjectData;
@class CMISRequest;

@protocol CMISVersioningService <NSObject>

/**
 * Get a the latest Document object in the Version Series.
 * @param objectId
 * @param major
 * @param filter
 * @param includeRelationships
 * @param includePolicyIds
 * @param renditionFilter
 * @param includeACL
 * @param includeAllowableActions
 * @param completionBlock returns object data if found or nil otherwise
 */
- (CMISRequest*)retrieveObjectOfLatestVersion:(NSString *)objectId
                                major:(BOOL)major
                               filter:(NSString *)filter
                        relationships:(CMISIncludeRelationship)relationships
                     includePolicyIds:(BOOL)includePolicyIds
                      renditionFilter:(NSString *)renditionFilter
                           includeACL:(BOOL)includeACL
              includeAllowableActions:(BOOL)includeAllowableActions
                      completionBlock:(void (^)(CMISObjectData *objectData, NSError *error))completionBlock;

/**
 * Returns the list of all Document Object in the given version series, sorted by creationDate descending (ie youngest first)
 * @param objectId
 * @param filter
 * @param includeAllowableActions
 * @param completionBlock returns array of all versioned objects or nil otherwise
 */
- (CMISRequest*)retrieveAllVersions:(NSString *)objectId
                             filter:(NSString *)filter
            includeAllowableActions:(BOOL)includeAllowableActions
                    completionBlock:(void (^)(NSArray *objects, NSError *error))completionBlock;



@end
