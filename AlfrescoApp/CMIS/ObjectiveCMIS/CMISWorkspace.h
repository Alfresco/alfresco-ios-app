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

@class CMISRepositoryInfo;
@class CMISSessionParameters;
@class CMISLinkRelations;

@interface CMISWorkspace : NSObject

@property (nonatomic, strong) CMISSessionParameters *sessionParameters;
@property (nonatomic, strong) CMISRepositoryInfo *repositoryInfo;

/**
* An array containing the parsed CMISAtomCollections.
*/
@property (nonatomic, strong) NSMutableArray *collections;

/**
 * An array of CMISAtomLink objects for the workspace
 */
@property (nonatomic, strong) CMISLinkRelations *linkRelations;

@property (nonatomic, strong) NSString *objectByIdUriTemplate;
@property (nonatomic, strong) NSString *objectByPathUriTemplate;
@property (nonatomic, strong) NSString *typeByIdUriTemplate;
@property (nonatomic, strong) NSString *queryUriTemplate;

/**
 * Returns the href link for a collection defined with the given type.
  * Returns nil if none is found.
 */
- (NSString *)collectionHrefForCollectionType:(NSString *)collectionType;

@end