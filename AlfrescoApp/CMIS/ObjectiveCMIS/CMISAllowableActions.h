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
#import "CMISExtensionData.h"


@interface CMISAllowableActions : CMISExtensionData

// Allowable actions as a NSSet of NSString objects, nil if unknown
@property (nonatomic, strong, readonly) NSSet *allowableActionsSet;

// Designated Initializer
- (id)init;

/// Use this init method when initializing with a raw NSDictionary parsed from an AtomPub Response
/**
 */
- (id)initWithAllowableActionsDictionary:(NSDictionary *)allowableActionsDict;

/**
 initialises with allowable actions dictionary and optional extension array
 */
- (id)initWithAllowableActionsDictionary:(NSDictionary *)allowableActionsDict extensionElementArray:(NSArray *)extensionElementArray;

/// Returns an NSSet of NSNumber of objects.  The NSNumber objects map to the CMISActionType enum
- (NSSet *)allowableActionTypesSet;

/// Set the allowable actions with a raw NSDictionary parsed from an AtomPub Response
- (void)setAllowableActionsWithDictionary:(NSDictionary *)allowableActionsDict;
@end
