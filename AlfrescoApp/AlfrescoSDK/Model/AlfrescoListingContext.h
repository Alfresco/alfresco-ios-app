/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile SDK.
 * 
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *  
 *  http://www.apache.org/licenses/LICENSE-2.0
 * 
 *  Unless required by applicable law or agreed to in writing, software
 *  distributed under the License is distributed on an "AS IS" BASIS,
 *  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *  See the License for the specific language governing permissions and
 *  limitations under the License.
 *****************************************************************************
 */

#import <Foundation/Foundation.h>

/** The AlfrescoListingContext can be used to specify paging values.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoListingContext : NSObject <NSCoding>


/// Returns the sorting field for the list.
@property (nonatomic, strong, readonly) NSString *sortProperty;


/// Returns the sorting direction.
@property (nonatomic, assign, readonly) BOOL sortAscending;


/// Returns the maximum items within the list.
@property (nonatomic, assign, readonly) int maxItems;


/// Returns current skip count.
@property (nonatomic, assign, readonly) int skipCount;

/**
 for this initialiser a skipCount 0, i.e. from the very first element on the server, will be returned.
 MaxItems may be -1 (which in general is interpreted by the server as All) or any positive number.
 */
- (id)initWithMaxItems:(int)maxItems;

/**
 In the context of this SDK, maxItems is the maximum number to be used in one listing. The skipCount is a multiple of
 maxItems. Hence skipCount 0 will return all items from 0 to maxItems - 1. skipCount 1 will return all items between
 maxItems and (maxItems * 2) - 1 - etc.
 @param maxItems - the maximum number of items to be used
 @param skipCount
 */
- (id)initWithMaxItems:(int)maxItems skipCount:(int)skipCount;

/**
 In the context of this SDK, maxItems is the maximum number to be used in one listing. The skipCount is a multiple of
 maxItems. Hence skipCount 0 will return all items from 0 to maxItems - 1. skipCount 1 will return all items between
 maxItems and (maxItems * 2) - 1 - etc.
 @param maxItems - the maximum number of items to be used
 @param skipCount
 @param sortProperty - a string indicating which value should be used for sorting. A nil string (or invalid string) will result in  default sorting
 @param sortAscending
 */
- (id)initWithMaxItems:(int)maxItems skipCount:(int)skipCount sortProperty:(NSString *)sortProperty sortAscending:(BOOL)sortAscending;

/**
 @param sortProperty - a string indicating which value should be used for sorting. A nil string (or invalid string) will result in  default sorting
 @param sortAscending
 */
- (id)initWithSortProperty:(NSString *)sortProperty sortAscending:(BOOL)sortAscending;

@end
