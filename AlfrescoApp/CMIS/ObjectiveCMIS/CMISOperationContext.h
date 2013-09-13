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


@interface CMISOperationContext : NSObject

@property (nonatomic, strong) NSString *filterString;
@property (nonatomic, assign) BOOL includeAllowableActions;
@property (nonatomic, assign) BOOL includeACLs;
@property (nonatomic, assign) CMISIncludeRelationship relationships;
@property (nonatomic, assign) BOOL includePolicies;
@property (nonatomic, strong) NSString *renditionFilterString;
@property (nonatomic, strong) NSString *orderBy;
@property (nonatomic, assign) BOOL includePathSegments;
@property (nonatomic, assign) NSInteger maxItemsPerPage;
@property (nonatomic, assign) NSInteger skipCount;

/**
 * creates a default operationContext instance. The defaults are
 - 100 items per page
 - start at first 100 items
 */
+ (CMISOperationContext *)defaultOperationContext;

@end