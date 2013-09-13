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
#import "AlfrescoFolder.h"
/** The AlfrescoKeywordSearchOptions are used in Alfresco Search Service.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Mike Hatfield (Alfresco)
 */

@interface AlfrescoKeywordSearchOptions : NSObject <NSCoding>
@property (nonatomic, assign, readonly) BOOL exactMatch;
@property (nonatomic, assign, readonly) BOOL includeContent;
@property (nonatomic, assign, readonly) BOOL includeDescendants;
@property (nonatomic, assign, readonly) BOOL includeAll;
@property (nonatomic, strong, readonly) AlfrescoFolder *folder;

/**
 @param exactMatch
 @param includeContent - searches also the content of files
 */
- (id)initWithExactMatch:(BOOL)exactMatch includeContent:(BOOL)includeContent;

/**
 @param exactMatch
 @param includeAll - searches content and metadata (implies includeContent)
 */
- (id)initWithExactMatch:(BOOL)exactMatch includeAll:(BOOL)includeAll;

/**
 @param folder - the node to be searched
 @param includeDescendants - search sub-folders as well
 */
- (id)initWithFolder:(AlfrescoFolder *)folder includeDescendants:(BOOL)includeDescendants;

/**
 @param exactMatch
 @param includeContent - searches also the content of files
 @param folder - the node to be searched
 @param includeDescendants - search sub-folders as well
 */
- (id)initWithExactMatch:(BOOL)exactMatch includeContent:(BOOL)includeContent folder:(AlfrescoFolder *)folder includeDescendants:(BOOL)includeDescendants;

/**
 @param exactMatch
 @param includeAll - searches content and metadata (implies includeContent)
 @param folder - the node to be searched
 @param includeDescendants - search sub-folders as well
 */
- (id)initWithExactMatch:(BOOL)exactMatch includeAll:(BOOL)includeAll folder:(AlfrescoFolder *)folder includeDescendants:(BOOL)includeDescendants;

@end
