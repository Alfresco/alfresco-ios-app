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

/**
 * This class represents a single node in the extension tree.
 */
@interface CMISExtensionElement : NSObject

/** @return The name of the extension node.
 */
@property (nonatomic, strong, readonly) NSString *name;
@property (nonatomic, strong, readonly) NSString *namespaceUri;
@property (nonatomic, strong, readonly) NSString *value;
@property (nonatomic, strong, readonly) NSDictionary *attributes;
@property (nonatomic, strong, readonly) NSArray *children;


/// Node Initializer
- (id)initNodeWithName:(NSString *)name namespaceUri:(NSString *)namespaceUri attributes:(NSDictionary *)attributesDict children:(NSArray *)children;

/// Leaf Initializer
- (id)initLeafWithName:(NSString *)name namespaceUri:(NSString *)namespaceUri attributes:(NSDictionary *)attributesDict value:(NSString *)value;

// TODO GHL Should children be nil or empty array?
// TODO GHL Should attributes be nil or empty dictionary?

@end
