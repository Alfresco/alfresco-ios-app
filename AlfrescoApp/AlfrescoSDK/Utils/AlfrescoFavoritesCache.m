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

#import "AlfrescoFavoritesCache.h"
#import "AlfrescoInternalConstants.h"

@interface AlfrescoFavoritesCache ()
@property (nonatomic, strong) NSMutableArray * favoritesCache;
@property (nonatomic, assign, readwrite) BOOL hasMoreFavoriteDocuments;
@property (nonatomic, assign, readwrite) BOOL hasMoreFavoriteFolders;
@property (nonatomic, assign, readwrite) BOOL hasMoreFavoriteNodes;
@property (nonatomic, assign, readwrite) NSInteger totalDocuments;
@property (nonatomic, assign, readwrite) NSInteger totatlFolders;
@property (nonatomic, assign, readwrite) NSInteger totalNodes;
@end

@implementation AlfrescoFavoritesCache

- (id)init
{
    self = [super init];
    if (nil != self)
    {
        _favoritesCache = [NSMutableArray arrayWithCapacity:0];
        _hasMoreFavoriteDocuments = YES;
        _hasMoreFavoriteFolders = YES;
        _hasMoreFavoriteNodes = YES;
    }
    return self;
}

+ (id)favoritesCacheForSession:(id<AlfrescoSession>)session
{
    static dispatch_once_t singleDispatchToken;
    static AlfrescoFavoritesCache *cache = nil;
    dispatch_once(&singleDispatchToken, ^{
        cache = [[self alloc] init];
        if (cache)
        {
            NSString *key = [NSString stringWithFormat:@"%@%@",kAlfrescoSessionInternalCache, [AlfrescoFavoritesCache class]];
            [session setObject:cache forParameter:key];
        }
    });
    return cache;
}

- (void)clear
{
    [self.favoritesCache removeAllObjects];
    _hasMoreFavoriteDocuments = YES;
    _hasMoreFavoriteFolders = YES;
    _hasMoreFavoriteNodes = YES;
    _totalDocuments = 0;
    _totalFolders = 0;
    _totalNodes = 0;
}

- (NSArray *)allFavorites
{
    return self.favoritesCache;
}

- (NSArray *)favoriteDocuments
{
    NSPredicate *favoritePredicate = [NSPredicate predicateWithFormat:@"isDocument == YES"];
    return [self.favoritesCache filteredArrayUsingPredicate:favoritePredicate];
}

- (NSArray *)favoriteFolders
{
    NSPredicate *favoritePredicate = [NSPredicate predicateWithFormat:@"isFolder == YES"];
    return [self.favoritesCache filteredArrayUsingPredicate:favoritePredicate];
}

- (void)addFavorite:(AlfrescoNode *)node
{
    if (nil == node)
    {
        return;
    }
    NSArray *identifiers = [self.favoritesCache valueForKey:@"identifier"];
    NSUInteger foundIndex = [identifiers indexOfObject:node.identifier];
    
    if (NSNotFound == foundIndex)
    {
        [self.favoritesCache addObject:node];
    }
    else
    {
        [self.favoritesCache replaceObjectAtIndex:foundIndex withObject:node];
    }
}

- (void)addFavorites:(NSArray *)nodes type:(AlfrescoFavoriteType)type hasMoreFavorites:(BOOL)hasMoreFavorites totalFavorites:(NSInteger)totalFavorites
{
    if (nil == nodes)
    {
        return;
    }
    switch (type)
    {
        case AlfrescoFavoriteDocument:
            self.hasMoreFavoriteDocuments = hasMoreFavorites;
            self.totalDocuments = totalFavorites;
            break;
        case AlfrescoFavoriteFolder:
            self.hasMoreFavoriteFolders = hasMoreFavorites;
            self.totatlFolders = totalFavorites;
            break;
        case AlfrescoFavoriteNode:
            self.hasMoreFavoriteNodes = hasMoreFavorites;
            self.totalNodes = totalFavorites;
            break;
    }
    
    [nodes enumerateObjectsUsingBlock:^(AlfrescoNode *node, NSUInteger index, BOOL *stop){
        [self addFavorite:node];
    }];
}

- (void)removeFavorite:(AlfrescoNode *)node
{
    [self.favoritesCache removeObject:node];
}

- (void)removeFavorites:(NSArray *)nodes
{
    [nodes enumerateObjectsUsingBlock:^(AlfrescoNode *node, NSUInteger index, BOOL *stop){
        [self removeFavorite:node];
    }];
}

- (AlfrescoNode *)objectWithIdentifier:(NSString *)identifier
{
    if (!identifier)return nil;
    NSPredicate *idPredicate = [NSPredicate predicateWithFormat:@"identifier == %@",identifier];
    NSArray *results = [self.favoritesCache filteredArrayUsingPredicate:idPredicate];
    return (0 == results.count) ? nil : results[0];
}

@end
