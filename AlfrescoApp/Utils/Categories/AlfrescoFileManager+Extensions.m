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
 
#import "AlfrescoFileManager+Extensions.h"
#import "SharedConstants.h"

/**
 * Public constants
 */

// Sync Folder name
NSString * const kSyncFolder = @"Sync";

/**
 * Private constants
 */

// preview documents
static NSString * const kPreviewDocumentsFolder = @"DocumentPreviews";

// thumbnails
static NSString * const kThumbnailsFolder = @"Thumbnails";
static NSString * const kThumbnailsMappingFolder = @"ThumbnailMappings";
static NSString * const kThumbnailDocLibFolder = @"DocLibsThumbnails";
static NSString * const kThumbnailImagePreviewFolder = @"ImgPreviewThumbnails";

// downloads
static NSString * const kDownloadsFolder = @"Downloads";
static NSString * const kDownloadsInfoFolder = @"info";
static NSString * const kDownloadsContentFolder = @"content";
static NSString * const kFileProviderFolder = @"FileProvider";

// configuration
static NSString * const kConfigurationFolder = @"Configuration";

@implementation AlfrescoFileManager (Extensions)

- (NSString *)documentPreviewDocumentFolderPath
{
    NSString *documentPreviewDocumentFolderPathString = [[self temporaryDirectory] stringByAppendingString:kPreviewDocumentsFolder];
    [self createFolderAtPathIfItDoesNotExist:documentPreviewDocumentFolderPathString];
    
    return documentPreviewDocumentFolderPathString;
}

- (NSString *)syncFolderPath
{
    NSString *syncFolderPathString = nil;
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    BOOL syncedContentMigrationOccurred = [defaults boolForKey:kHasSyncedContentMigrationOccurred];
    
    if (syncedContentMigrationOccurred)
    {
        syncFolderPathString = [[[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier].path stringByAppendingPathComponent:kSyncFolder];
    }
    else
    {
        syncFolderPathString = [[self documentsDirectory] stringByAppendingPathComponent:kSyncFolder];
    }
    
    [self createFolderAtPathIfItDoesNotExist:syncFolderPathString];
    
    return syncFolderPathString;
}

- (NSString *)downloadsFolderPath
{
    NSURL *downloadsFolderPathURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    NSString *sharedContainerDownloadsPath = [downloadsFolderPathURL.path stringByAppendingPathComponent:kDownloadsFolder];
    
    return sharedContainerDownloadsPath;
}
     
- (NSString *)legacyDownloadsFolderPath
{
    NSString *downloadsFolderPathString = [[self documentsDirectory] stringByAppendingPathComponent:kDownloadsFolder];
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

- (NSString *)defaultConfigurationFolderPath
{
    NSString *configurationPathString = [[self documentsDirectory] stringByAppendingPathComponent:kConfigurationFolder];
    [self createFolderAtPathIfItDoesNotExist:configurationPathString];
    
    return configurationPathString;
}

- (void)clearTemporaryDirectory
{
    NSError *tmpError = nil;
    NSArray *temporayDirectoryContent = [self contentsOfDirectoryAtPath:self.temporaryDirectory error:&tmpError];
    
    if (tmpError)
    {
        AlfrescoLogError(@"Unable to retrieve content of %@", self.temporaryDirectory);
    }
    
    for (NSString *itemName in temporayDirectoryContent)
    {
        NSError *removalError = nil;
        NSString *absolutePath = [self.temporaryDirectory stringByAppendingPathComponent:itemName];
        [self removeItemAtPath:absolutePath error:&removalError];
        
        if (removalError)
        {
            AlfrescoLogError(@"Unable to remove iteam at path: %@", absolutePath);
        }
    }
}

- (NSString *)fileProviderFolderPath
{
    NSURL *sharedAppGroupFolderURL = [[NSFileManager defaultManager] containerURLForSecurityApplicationGroupIdentifier:kSharedAppGroupIdentifier];
    NSString *fileProviderFolderPath = [sharedAppGroupFolderURL.path stringByAppendingPathComponent:kFileProviderFolder];
    [self createFolderAtPathIfItDoesNotExist:fileProviderFolderPath];
    return fileProviderFolderPath;
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
