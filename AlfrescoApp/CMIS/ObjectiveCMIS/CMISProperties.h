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
#import "CMISPropertyData.h"
#import "CMISExtensionData.h"

@interface CMISProperties : CMISExtensionData

// Dictionary of property id -> CMISPropertyData
@property (nonatomic, strong, readonly) NSDictionary *propertiesDictionary;

// List of CMISPropertyData objects
@property (nonatomic, strong, readonly) NSArray *propertyList;

// adds a property
- (void)addProperty:(CMISPropertyData *)propertyData;

/**
* Returns a property by id.
* <p>
* Since repositories are not obligated to add property ids to their query
* result properties, this method might not always work as expected with
* some repositories. Use {@link #getPropertyByQueryName(String)} instead.
*/
- (CMISPropertyData *)propertyForId:(NSString *)id;

/**
 * Returns a property by query name or alias.
 */
- (CMISPropertyData *)propertyForQueryName:(NSString *)queryName;

/**
 * Returns a property (single) value by id.
 */
- (id)propertyValueForId:(NSString *)propertyId;

/**
 * Returns a property (single) value by query name or alias.
 * @see #getPropertyByQueryName(String)
 */
- (id)propertyValueForQueryName:(NSString *)queryName;

/**
 * Returns a property multi-value by id.
 */
- (NSArray *)propertyMultiValueById:(NSString *)id;

/**
 * Returns a property multi-value by query name or alias.
 */
- (NSArray *)propertyMultiValueByQueryName:(NSString *)queryName;

@end
