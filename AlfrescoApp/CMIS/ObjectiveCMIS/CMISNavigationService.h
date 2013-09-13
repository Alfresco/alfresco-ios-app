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

@class CMISFolder;
@class CMISObjectList;
@class CMISRequest;

@protocol CMISNavigationService <NSObject>

/**
 * Retrieves the children for the given object identifier.
 * completionBlock returns object list or nil if unsuccessful
 */
- (CMISRequest*)retrieveChildren:(NSString *)objectId
                 orderBy:(NSString *)orderBy
                  filter:(NSString *)filter
           relationships:(CMISIncludeRelationship)relationships
         renditionFilter:(NSString *)renditionFilter
 includeAllowableActions:(BOOL)includeAllowableActions
      includePathSegment:(BOOL)includePathSegment
               skipCount:(NSNumber *)skipCount
                maxItems:(NSNumber *)maxItems
         completionBlock:(void (^)(CMISObjectList *objectList, NSError *error))completionBlock;

/**
 * Retrieves the parent of a given object.
 * Returns a list of CMISObjectData objects
 *
 * TODO: OpenCMIS returns an ObjectParentData object .... is this necessary?
 * completionBlock returns array of parents or nil if unsuccessful
 */
- (CMISRequest*)retrieveParentsForObject:(NSString *)objectId
                          filter:(NSString *)filter
                   relationships:(CMISIncludeRelationship)relationships
                 renditionFilter:(NSString *)renditionFilter
         includeAllowableActions:(BOOL)includeAllowableActions
      includeRelativePathSegment:(BOOL)includeRelativePathSegment
                 completionBlock:(void (^)(NSArray *parents, NSError *error))completionBlock;


@end
