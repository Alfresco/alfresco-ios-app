//
//  SyncManager.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 16/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SyncManager.h"

static NSString *const kSyncInfoDirectory = @"sync/info";
static NSString *const kSyncContentDirectory = @"sync/content";

@interface SyncManager ()
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@end

@implementation SyncManager

#pragma mark - Public Interface

+ (SyncManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (NSArray *)syncDocumentsAndFoldersForSession:(id<AlfrescoSession>)alfrescoSession withCompletionBlock:(void (^)(NSArray *syncedNodes))completionBlock
{
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:alfrescoSession];
    
    [documentService retrieveFavoriteNodesWithCompletionBlock:^(NSArray *array, NSError *error) {
        
        completionBlock(array);
    }];
    
    // returns local synced files until request completes.
    return nil;
}

#pragma mark - Private Methods

- (NSString *)ysncInfoDirectory
{
    NSString *infoDirectory = [self.fileManager.homeDirectory stringByAppendingPathComponent:kSyncInfoDirectory];
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:infoDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:infoDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return infoDirectory;
}

- (NSString *)syncContentDirectory
{
    NSString *contentDirectory = [self.fileManager.homeDirectory stringByAppendingPathComponent:kSyncContentDirectory];
    BOOL isDirectory;
    BOOL dirExists = [self.fileManager fileExistsAtPath:contentDirectory isDirectory:&isDirectory];
    NSError *error = nil;
    
    if (!dirExists)
    {
        [self.fileManager createDirectoryAtPath:contentDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    }
    
    return contentDirectory;
}

#pragma mark - Private Interface

- (id)init
{
    self = [super init];
    if (self)
    {
        self.fileManager = [AlfrescoFileManager sharedManager];
    }
    return self;
}


@end
