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

@class CMISPropertyDefinition;


@interface CMISTypeDefinition : NSObject

@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *localName;
@property (nonatomic, strong) NSString *localNameSpace;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *queryName;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) CMISBaseType baseTypeId;

@property (nonatomic, assign, getter = isCreatable) BOOL creatable;
@property (nonatomic, assign, getter = isFileable) BOOL fileable;
@property (nonatomic, assign, getter = isQueryable) BOOL queryable;
@property (nonatomic, assign, getter = isFullTextIndexed) BOOL fullTextIndexed;
@property (nonatomic, assign, getter = isIncludedInSupertypeQuery) BOOL includedInSupertypeQuery;
@property (nonatomic, assign, getter = isControllablePolicy) BOOL controllablePolicy;
@property (nonatomic, assign, getter = isControllableAcl) BOOL controllableAcl;

/// Mapping of property id <-> CMISPropertyDefinition
@property (nonatomic, strong, readonly) NSDictionary *propertyDefinitions;

/// add property definition
- (void)addPropertyDefinition:(CMISPropertyDefinition *)propertyDefinition;


/// retrieve property definition for given property Id
- (CMISPropertyDefinition *)propertyDefinitionForId:(NSString *)propertyId;

@end