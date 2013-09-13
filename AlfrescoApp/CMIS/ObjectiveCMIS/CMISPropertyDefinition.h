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


// TODO: type specific properties, see cmis spec line 527
@interface CMISPropertyDefinition : NSObject


@property (nonatomic, strong) NSString *id;
@property (nonatomic, strong) NSString *localName;
@property (nonatomic, strong) NSString *localNamespace;
@property (nonatomic, strong) NSString *displayName;
@property (nonatomic, strong) NSString *queryName;
@property (nonatomic, strong) NSString *description;
@property (nonatomic, assign) CMISPropertyType propertyType;
@property (nonatomic, assign) CMISCardinality cardinality;
@property (nonatomic, assign) CMISUpdatability updatability;

@property (nonatomic, assign, getter = isInherited) BOOL inherited;
@property (nonatomic, assign, getter = isRequired) BOOL required;
@property (nonatomic, assign, getter = isQueryable) BOOL queryable;
@property (nonatomic, assign, getter = isOrderable) BOOL orderable;
@property (nonatomic, assign, getter = isOpenChoice) BOOL openChoice;

@property (nonatomic, strong) NSArray *defaultValues;
@property (nonatomic, strong) NSArray *choices;

@end