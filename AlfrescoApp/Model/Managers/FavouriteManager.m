/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
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
 ******************************************************************************/
 
#import "FavouriteManager.h"

@interface FavouriteManager ()

@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *documentFolderService;

@end

@implementation FavouriteManager

#pragma mark - Initialiser

+ (FavouriteManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static FavouriteManager *sharedFavouriteManager;
    dispatch_once(&onceToken, ^{
        sharedFavouriteManager = [[self alloc] init];
    });
    return sharedFavouriteManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionRefreshedNotification
                                                   object:nil];
    }
    return self;
}

// Should never reach this. Only added for completeness
- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    [self createServicesWithSession:session];
}

- (void)createServicesWithSession:(id<AlfrescoSession>)session
{
    self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
}

#pragma mark - Public Functions

- (AlfrescoRequest *)addFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if (!self.session)
    {
        self.session = session;
        [self createServicesWithSession:session];
    }
    
    return [self.documentFolderService addFavorite:node completionBlock:^(BOOL succeeded, BOOL isFavorited, NSError *error) {
        if (succeeded)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFavouritesDidAddNodeNotification object:node];
            if (completionBlock != NULL)
            {
                completionBlock(isFavorited, error);
            }
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(NO, error);
            }
        }
    }];
}

- (AlfrescoRequest *)removeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL succeeded, NSError *error))completionBlock
{
    if (!self.session)
    {
        self.session = session;
        [self createServicesWithSession:session];
    }
    
    return [self.documentFolderService removeFavorite:node completionBlock:^(BOOL succeeded, BOOL isFavorited, NSError *error) {
        if (succeeded)
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kFavouritesDidRemoveNodeNotification object:node];
            if (completionBlock != NULL)
            {
                completionBlock(succeeded, error);
            }
        }
        else
        {
            if (completionBlock != NULL)
            {
                completionBlock(succeeded, error);
            }
        }
    }];
}

- (AlfrescoRequest *)isNodeFavorite:(AlfrescoNode *)node session:(id<AlfrescoSession>)session completionBlock:(void (^)(BOOL isFavorite, NSError *error))completionBlock
{
    if (!self.session)
    {
        self.session = session;
        [self createServicesWithSession:session];
    }
    
    return [self.documentFolderService isFavorite:node completionBlock:^(BOOL succeeded, BOOL isFavorited, NSError *error) {
        completionBlock(isFavorited, error);
    }];
}

- (void)topLevelFavoriteNodesWithSession:(id<AlfrescoSession>)session filter:(NSString *)filter listingContext:(AlfrescoListingContext *)listingContext completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    void (^retrieveCompletionBlock)(AlfrescoPagingResult *, NSError *) = ^void(AlfrescoPagingResult *pagingResult, NSError *error) {
        if(completionBlock)
        {
            completionBlock(pagingResult, error);
        }
    };
    
    if (!self.session)
    {
        self.session = session;
        [self createServicesWithSession:session];
    }
    
    [self.documentFolderService clear];
    
    if ([filter isEqualToString:kAlfrescoConfigViewParameterFavoritesFiltersFiles])
    {
        [self.documentFolderService retrieveFavoriteDocumentsWithListingContext:listingContext completionBlock:retrieveCompletionBlock];
    }
    else if ([filter isEqualToString:kAlfrescoConfigViewParameterFavoritesFiltersFolders])
    {
        [self.documentFolderService retrieveFavoriteFoldersWithListingContext:listingContext completionBlock:retrieveCompletionBlock];
    }
    else if ([filter isEqualToString:kAlfrescoConfigViewParameterFavoritesFiltersAll])
    {
        [self.documentFolderService retrieveFavoriteNodesWithListingContext:listingContext completionBlock:retrieveCompletionBlock];
    }
}

@end
