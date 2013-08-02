//
//  ThumbnailDownloader.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "ThumbnailDownloader.h"
#import "AlfrescoDocumentFolderService.h"
#import "Utility.h"
#import "AlfrescoFileManager.h"

@interface ThumbnailDownloader ()

@property (nonatomic, strong, readwrite) AlfrescoDocumentFolderService *thumbnailService;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) __block NSMutableDictionary *requestedThumbnailCompletionBlocks;

@end

@implementation ThumbnailDownloader

+ (id)sharedManager
{
    static dispatch_once_t onceToken;
    static ThumbnailDownloader *sharedThumbnailDownloader = nil;
    dispatch_once(&onceToken, ^{
        sharedThumbnailDownloader = [[self alloc] init];
    });
    return sharedThumbnailDownloader;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        self.requestedThumbnailCompletionBlocks = [NSMutableDictionary dictionary];
        self.thumbnailService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(sessionReceived:)
                                                     name:kAlfrescoSessionReceivedNotification
                                                   object:nil];
    }
    return self;
}

- (void)retrieveImageForDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session completionBlock:(ThumbnailCompletionBlock)completionBlock
{
    if (!self.session)
    {
        self.thumbnailService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        self.session = session;
    }
       
    NSString *fileName = [uniqueFileNameForNode(document) stringByAppendingString:@".png"];
    NSString *filePathForFileInContainer = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:fileName];
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:filePathForFileInContainer append:NO];
    
    __weak ThumbnailDownloader *weakSelf = self;
    
    if (![self thumbnailHasBeenRequestedForDocument:document])
    {
        [self.thumbnailService retrieveRenditionOfNode:document renditionName:@"doclib" outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
            if (succeeded)
            {
                NSArray *completionBlocks = [weakSelf.requestedThumbnailCompletionBlocks objectForKey:fileName];
                
                [completionBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
                    ThumbnailCompletionBlock block = (ThumbnailCompletionBlock)obj;
                    block(fileName, error);
                }];
                
                [weakSelf removeAllCompletionBlocksForKey:fileName];
            }
        }];
    }
    
    [self addCompletionBlock:completionBlock forKey:fileName];
}

- (BOOL)thumbnailHasBeenRequestedForDocument:(AlfrescoDocument *)document
{
    BOOL hasRequestHasBeenMade = NO;
    NSString *fileName = [uniqueFileNameForNode(document) stringByAppendingString:@".png"];
    
    if ([[self.requestedThumbnailCompletionBlocks allKeys] containsObject:fileName])
    {
        hasRequestHasBeenMade = YES;
    }
    return hasRequestHasBeenMade;
}

#pragma mark - Private Functions

- (void)sessionReceived:(NSNotification *)notification
{
    id <AlfrescoSession> session = notification.object;
    self.session = session;
    
    // update the document folder service
    self.thumbnailService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.session];
}

- (void)addCompletionBlock:(void (^)(NSString *savedFileName, NSError *error))completionBlock forKey:(NSString *)key
{
    NSMutableArray *completionBlocksForRequest = [self.requestedThumbnailCompletionBlocks objectForKey:key];
    ThumbnailCompletionBlock retainedBlock = [completionBlock copy];
    
    if (!completionBlocksForRequest)
    {
        completionBlocksForRequest = [NSMutableArray array];
        [completionBlocksForRequest addObject:retainedBlock];
        [self.requestedThumbnailCompletionBlocks setObject:completionBlocksForRequest forKey:key];
    }
    else
    {
        [completionBlocksForRequest addObject:retainedBlock];
    }
}

- (void)removeAllCompletionBlocksForKey:(NSString *)key
{
    [self.requestedThumbnailCompletionBlocks removeObjectForKey:key];
}

@end
