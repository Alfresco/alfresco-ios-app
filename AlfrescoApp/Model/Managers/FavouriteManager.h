//
//  FavouriteManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 31/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface FavouriteManager : NSObject

+ (instancetype)sharedManager;
- (void)addFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
- (void)removeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
- (void)isNodeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL isFavorite, NSError *error))completionBlock;

@end
