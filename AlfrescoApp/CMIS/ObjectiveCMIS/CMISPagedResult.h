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
 * Wrapper class for the results of fetching a new page using the block below.
 */
@interface CMISFetchNextPageBlockResult : NSObject

@property (nonatomic, strong) NSArray *resultArray;
@property BOOL hasMoreItems;
@property NSInteger numItems;

@end

typedef void (^CMISFetchNextPageBlockCompletionBlock)(CMISFetchNextPageBlockResult *result, NSError *error);
typedef void (^CMISFetchNextPageBlock)(int skipCount, int maxItems, CMISFetchNextPageBlockCompletionBlock completionBlock);

@class CMISObject;

/**
 * The result of executing an operation which has potentially more results than returned in once.
 */
@interface CMISPagedResult : NSObject

@property (nonatomic, strong, readonly) NSArray *resultArray;
@property (readonly) BOOL hasMoreItems;
@property (readonly) NSInteger numItems;

/**
 * completionBlock returns paged results or nil if unsuccessful
 */
+ (void)pagedResultUsingFetchBlock:(CMISFetchNextPageBlock)fetchNextPageBlock
                   limitToMaxItems:(NSInteger)maxItems
                startFromSkipCount:(NSInteger)skipCount
                   completionBlock:(void (^)(CMISPagedResult *result, NSError *error))completionBlock;

/**
 * fetches the next page
 * completionBlock returns paged result or nil if unsuccessful
 */
- (void)fetchNextPageWithCompletionBlock:(void (^)(CMISPagedResult *result, NSError *error))completionBlock;

/**
 * enumerates through the items in a page
 * completionBlock returns NSError nil if successful
 */
- (void)enumerateItemsUsingBlock:(void (^)(CMISObject *object, BOOL *stop))enumerationBlock
                 completionBlock:(void (^)(NSError *error))completionBlock;

@end