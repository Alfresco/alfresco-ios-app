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
#import "CMISObjectData.h"
#import "CMISBinding.h"
#import "CMISObjectId.h"

@class CMISSession;

@interface CMISObject : CMISObjectId

@property (nonatomic, strong, readonly) CMISSession *session;
@property (nonatomic, strong, readonly) id<CMISBinding> binding;

@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *createdBy;
@property (nonatomic, strong, readonly) NSDate *creationDate;
@property (nonatomic, strong, readonly) NSString *lastModifiedBy;
@property (nonatomic, strong, readonly) NSDate *lastModificationDate;
@property (nonatomic, strong, readonly) NSString *objectType;
@property (nonatomic, strong, readonly) NSString *changeToken;
//@property (nonatomic, strong, readonly) CMISBaseTypeId *baseTypeId;
//@property (nonatomic, strong, readonly) CMISObjectType *baseType;
//@property (nonatomic, strong, readonly) CMISObjectType *type;
@property (nonatomic, strong, readonly) CMISAllowableActions *allowableActions;
@property (nonatomic, strong, readonly) NSArray *renditions; // An array containing CMISRendition objects

@property (nonatomic, strong, readonly) CMISProperties *properties;

/**
 * initialise CMISObject with data and session
 */
- (id)initWithObjectData:(CMISObjectData *)objectData session:(CMISSession *)session;

/**
 * Updates the properties that are provided.
 * completionBlock returns the updated CMISObject instance or nil if unsuccessful
 */
- (void)updateProperties:(NSDictionary *)properties completionBlock:(void (^)(CMISObject *object, NSError *error))completionBlock;

/**
 * Returns the extensions for the given level as an array 
 */
- (NSArray *)extensionsForExtensionLevel:(CMISExtensionLevel)extensionLevel;

@end

