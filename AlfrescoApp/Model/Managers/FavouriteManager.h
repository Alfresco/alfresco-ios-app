//
//  FavouriteManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 31/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@interface FavouriteManager : NSObject

+ (FavouriteManager *)sharedManager;
- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock;
- (AlfrescoRequest *)isNodeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL isFavorite, NSError *error))completionBlock;

@end
