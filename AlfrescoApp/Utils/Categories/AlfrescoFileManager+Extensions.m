//
//  AlfrescoFileManager+Extensions.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 12/12/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AlfrescoFileManager+Extensions.h"

// preview documents
static NSString * const kPreviewDocumentsFolder = @"DocumentPreviews";

// thumbnails
static NSString * const kThumbnailsFolder = @"Thumbnails";
static NSString * const kThumbnailsMappingFolder = @"ThumbnailMappings";
static NSString * const kThumbnailDocLibFolder = @"DocLibsThumbnails";
static NSString * const kThumbnailImagePreviewFolder = @"ImgPreviewThumbnails";

// sync
static NSString * const kSyncFolder = @"Sync";

// downloads
static NSString * const kDownloadsFolder = @"Downloads";
static NSString * const kDownloadsInfoFolder = @"info";
static NSString * const kDownloadsContentFolder = @"content";

@implementation AlfrescoFileManager (Extensions)

- (NSString *)documentPreviewDocumentFolderPath
{
    NSString *documentPreviewDocumentFolderPathString = [[self temporaryDirectory] stringByAppendingString:kPreviewDocumentsFolder];
    [self createFolderAtPathIfItDoesNotExist:documentPreviewDocumentFolderPathString];
    
    return documentPreviewDocumentFolderPathString;
}

- (NSString *)syncFolderPath
{
    NSString *syncFolderPathString = [[self documentsDirectory] stringByAppendingPathComponent:kSyncFolder];
    [self createFolderAtPathIfItDoesNotExist:syncFolderPathString];
    
    return syncFolderPathString;
}

- (NSString *)downloadsFolderPath
{
    NSString *downloadsFolderPathString = [[self documentsDirectory] stringByAppendingPathComponent:kDownloadsFolder];
    [self createFolderAtPathIfItDoesNotExist:downloadsFolderPathString];
    
    return downloadsFolderPathString;
}

- (NSString *)downloadsInfoContentPath
{
    NSString *downloadsInfoFolderPathString = [[self downloadsFolderPath] stringByAppendingPathComponent:kDownloadsInfoFolder];
    [self createFolderAtPathIfItDoesNotExist:downloadsInfoFolderPathString];
    
    return downloadsInfoFolderPathString;
}

- (NSString *)downloadsContentFolderPath
{
    NSString *downloadsContentFolderPathString = [[self downloadsFolderPath] stringByAppendingPathComponent:kDownloadsContentFolder];
    [self createFolderAtPathIfItDoesNotExist:downloadsContentFolderPathString];
    
    return downloadsContentFolderPathString;
}

#pragma mark - Private Functions

- (void)createFolderAtPathIfItDoesNotExist:(NSString *)folderPath
{
    if (![self fileExistsAtPath:folderPath])
    {
        NSError *creationError = nil;
        [self createDirectoryAtPath:folderPath withIntermediateDirectories:YES attributes:nil error:&creationError];
        
        if (creationError)
        {
            AlfrescoLogDebug(@"Unable to create folder at path: %@. Error: %@", folderPath, creationError.localizedDescription);
        }
    }
}

@end
