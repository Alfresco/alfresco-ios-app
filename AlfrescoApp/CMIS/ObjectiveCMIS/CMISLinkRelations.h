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

@interface CMISLinkRelations : NSObject

@property (nonatomic, strong, readonly) NSSet *linkRelationSet;

- (id)initWithLinkRelationSet:(NSSet *)linkRelationSet;

/**
 Returns the link href for the link relation. If more than one object exists for the link relation, 
 then nil is returned.  If no relation is found, nil is returned.
 */
- (NSString *)linkHrefForRel:(NSString *)rel;

/**
 Returns the link href for the link relation & link type. If more than one object exists for the link relation, 
 then nil is returned.  If no relation is found, nil is returned.
 */
- (NSString *)linkHrefForRel:(NSString *)rel type:(NSString *)type;

@end
