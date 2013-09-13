/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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
#import "AlfrescoSession.h"

typedef enum
{
    AlfrescoFavoriteDocument = 0,
    AlfrescoFavoriteFolder,
    AlfrescoFavoriteNode,
    
} AlfrescoFavoriteType;

@interface AlfrescoFavoritesCache : NSObject

@property (nonatomic, assign, readonly) BOOL hasMoreFavoriteDocuments;
@property (nonatomic, assign, readonly) BOOL hasMoreFavoriteFolders;
@property (nonatomic, assign, readonly) BOOL hasMoreFavoriteNodes;
@property (nonatomic, assign, readonly) NSInteger totalDocuments;
@property (nonatomic, assign, readonly) NSInteger totalFolders;
@property (nonatomic, assign, readonly) NSInteger totalNodes;
/**
 initialiser
 */
+ (id)favoritesCacheForSession:(id<AlfrescoSession>)session;

/**
 clears all entries in the cache
 */
- (void)clear;

/**
 returns favourites
 */
- (NSArray *)allFavorites;
- (NSArray *)favoriteDocuments;
- (NSArray *)favoriteFolders;

- (void)addFavorite:(AlfrescoNode *)node;
- (void)addFavorites:(NSArray *)nodes type:(AlfrescoFavoriteType)type hasMoreFavorites:(BOOL)hasMoreFavorites totalFavorites:(NSInteger)totalFavorites;

- (void)removeFavorite:(AlfrescoNode *)node;
- (void)removeFavorites:(NSArray *)nodes;

/**
 Returns the first entry found for the identifier.
 */
- (AlfrescoNode *)objectWithIdentifier:(NSString *)identifier;

@end
