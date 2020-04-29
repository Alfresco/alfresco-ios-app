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
 
#import "ThumbnailManager.h"
#import "ThumbnailOperation.h"
#import "CoreDataCacheHelper.h"

static NSTimeInterval const kMinimumDelayBetweenRequestsOnCloud = 0.5;

typedef NS_ENUM(NSUInteger, RenditionType)
{
    RenditionTypeUnknown = 0,
    RenditionTypeDocLib,
    RenditionTypeImgPreview
};

@interface ThumbnailManager ()

@property (nonatomic, strong, readwrite) __block NSMutableDictionary *requestedThumbnailCompletionBlocks;
@property (nonatomic, strong) CoreDataCacheHelper *coreDataCacheHelper;
@property (nonatomic, strong) NSOperationQueue *operationQueue;

@end

@implementation ThumbnailManager

+ (ThumbnailManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static ThumbnailManager *sharedThumbnailDownloader = nil;
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
        self.coreDataCacheHelper = [[CoreDataCacheHelper alloc] init];
        self.operationQueue = [[NSOperationQueue alloc] init];
        self.operationQueue.maxConcurrentOperationCount = 1;
    }
    return self;
}

- (void)retrieveImageForDocument:(AlfrescoDocument *)document renditionType:(NSString *)rendition session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock
{
    NSString *identifier = document.identifier;
    UIImage *retrievedImage = [self thumbnailForDocument:document renditionType:rendition];
    
    if (retrievedImage)
    {
        completionBlock(retrievedImage, nil);
    }
    else
    {
        if (![[self.requestedThumbnailCompletionBlocks allKeys] containsObject:identifier])
        {
            AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            
            ThumbnailOperation *operation = [[ThumbnailOperation alloc] initWithDocumentFolderService:documentFolderService document:document renditionName:rendition completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
                if (contentFile)
                {
                    NSManagedObjectContext *childManagedObjectContext = [self.coreDataCacheHelper createChildManagedObjectContext];
                    
                    UIImage *thumbnailImage = nil;
                    RenditionType renditionType = [self renditionTypeFromRenditionString:rendition];
                    if (renditionType == RenditionTypeDocLib)
                    {
                        DocLibImageCache *docLibImageObject = [self.coreDataCacheHelper createDocLibObjectInManagedObjectContext:childManagedObjectContext];
                        docLibImageObject.identifier = identifier;
                        docLibImageObject.docLibImageData = [NSData dataWithContentsOfURL:contentFile.fileUrl];
                        docLibImageObject.dateAdded = [NSDate date];
                        docLibImageObject.dateModified = document.modifiedAt;
                        thumbnailImage = [docLibImageObject docLibImage];
                    }
                    else if (renditionType == RenditionTypeImgPreview)
                    {
                        DocumentPreviewImageCache *documentPreviewObject = [self.coreDataCacheHelper createDocumentPreviewObjectInManagedObjectContext:childManagedObjectContext];
                        documentPreviewObject.identifier = identifier;
                        documentPreviewObject.documentPreviewImageData = [NSData dataWithContentsOfURL:contentFile.fileUrl];
                        documentPreviewObject.dateAdded = [NSDate date];
                        documentPreviewObject.dateModified = document.modifiedAt;
                        thumbnailImage = [documentPreviewObject documentPreviewImage];
                    }
                    
                    // remove the temp file
                    NSError *removalError = nil;
                    [[AlfrescoFileManager sharedManager] removeItemAtPath:contentFile.fileUrl.path error:&removalError];
                    
                    if (removalError)
                    {
                        AlfrescoLogError(@"Error removing file at path %@", contentFile.fileUrl.path);
                    }
                    
                    [self runAllCompletionBlocksForIdentifier:identifier thumbnailImage:thumbnailImage error:error];
                    
                    [self.coreDataCacheHelper saveContextForManagedObjectContext:childManagedObjectContext];
                }
                else
                {
                    [self runAllCompletionBlocksForIdentifier:identifier thumbnailImage:nil error:error];
                }
            }];
            
            if ([session isKindOfClass:[AlfrescoCloudSession class]])
            {
                operation.minimumDelayBetweenRequests = kMinimumDelayBetweenRequestsOnCloud;
            }
            else
            {
                operation.minimumDelayBetweenRequests = 0;
            }
            [self.operationQueue addOperation:operation];
        }
        [self addCompletionBlock:completionBlock forKey:identifier];
    }
}

#pragma mark - Private Functions

- (void)addCompletionBlock:(ImageCompletionBlock)completionBlock forKey:(NSString *)key
{
    NSMutableArray *completionBlocksForRequest = [self.requestedThumbnailCompletionBlocks objectForKey:key];
    ImageCompletionBlock retainedBlock = [completionBlock copy];
    
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

- (void)runAllCompletionBlocksForIdentifier:(NSString *)identifier thumbnailImage:(UIImage *)thumbnail error:(NSError *)error
{
    NSArray *completionBlocks = [self.requestedThumbnailCompletionBlocks objectForKey:identifier];
    [completionBlocks enumerateObjectsUsingBlock:^(id obj, NSUInteger idx, BOOL *stop) {
        ImageCompletionBlock block = (ImageCompletionBlock)obj;
        block(thumbnail, error);
    }];
    [self removeAllCompletionBlocksForKey:identifier];
}

- (void)removeAllCompletionBlocksForKey:(NSString *)key
{
    [self.requestedThumbnailCompletionBlocks removeObjectForKey:key];
}

- (UIImage *)thumbnailForDocument:(AlfrescoDocument *)document renditionType:(NSString *)rendition
{
    UIImage *returnedImage = nil;
    RenditionType renditionType = [self renditionTypeFromRenditionString:rendition];
    
    switch (renditionType)
    {
        case RenditionTypeDocLib:
        {
            DocLibImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveDocLibForDocument:document inManagedObjectContext:nil];
            returnedImage = [retrievedImageCacheObject docLibImage];
        }
        break;
            
        case RenditionTypeImgPreview:
        {
            DocumentPreviewImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveDocumentPreviewForDocument:document inManagedObjectContext:nil];
            returnedImage = [retrievedImageCacheObject documentPreviewImage];
        }
        break;
            
        default:
            break;
    }
    
    return returnedImage;
}

- (UIImage *)thumbnailForDocumentIdentifier:(NSString *)documentIdentifier renditionType:(NSString *)rendition
{
    UIImage *returnedImage = nil;
    RenditionType renditionType = [self renditionTypeFromRenditionString:rendition];
    
    switch (renditionType)
    {
        case RenditionTypeDocLib:
        {
            DocLibImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveDocLibForIdentifier:documentIdentifier inManagedObjectContext:nil];
            returnedImage = [retrievedImageCacheObject docLibImage];
        }
            break;
            
        case RenditionTypeImgPreview:
        {
            DocumentPreviewImageCache *retrievedImageCacheObject = [self.coreDataCacheHelper retrieveDocumentPreviewForIdentifier:documentIdentifier inManagedObjectContext:nil];
            returnedImage = [retrievedImageCacheObject documentPreviewImage];
        }
            break;
            
        default:
            break;
    }
    
    return returnedImage;
}

- (RenditionType)renditionTypeFromRenditionString:(NSString *)rendition
{
    RenditionType renditionType = RenditionTypeUnknown;
    
    if ([rendition isEqualToString:kRenditionImageDocLib])
    {
        renditionType = RenditionTypeDocLib;
    }
    else if ([rendition isEqualToString:kRenditionImageImagePreview])
    {
        renditionType = RenditionTypeImgPreview;
    }
    
    return renditionType;
}

@end
