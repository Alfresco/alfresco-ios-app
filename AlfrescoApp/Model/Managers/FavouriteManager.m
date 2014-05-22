//
//  FavouriteManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 31/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FavouriteManager.h"
#import "SyncManager.h"

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
            SyncManager *syncManager = [SyncManager sharedManager];
            [syncManager addNodeToSync:node withCompletionBlock:^(BOOL completed) {
                if (completionBlock != NULL)
                {
                    completionBlock(isFavorited, error);
                }
            }];
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
            SyncManager *syncManager = [SyncManager sharedManager];
            [syncManager removeNodeFromSync:node withCompletionBlock:^(BOOL succeeded) {
                if (completionBlock != NULL)
                {
                    completionBlock(succeeded, error);
                }
            }];
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

@end
