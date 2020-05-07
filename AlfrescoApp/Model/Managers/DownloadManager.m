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
 
#import "DownloadManager.h"
#import "UniversalDevice.h"

static NSUInteger const kStreamCopyBufferSize = 16 * 1024;

@interface DownloadManager ()
@property (nonatomic, strong) id<AlfrescoSession> alfrescoSession;
@property (nonatomic, strong) AlfrescoFileManager *fileManager;
@end

@implementation DownloadManager

#pragma mark - Public Interface

+ (DownloadManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    __strong static id sharedObject = nil;
    dispatch_once(&predicate, ^{
        sharedObject = [[self alloc] init];
    });
    return sharedObject;
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath session:(id<AlfrescoSession>)alfrescoSession
                      completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    if (!document)
    {
        AlfrescoLogError(@"Download operation attempted with nil AlfrescoDocument object");
        return nil;
    }
    
    AlfrescoRequest *request = nil;
    // Check source content exists
    if (!contentPath || ![self.fileManager fileExistsAtPath:contentPath])
    {
        // No local source, so the content will need to be downloaded from the Repository
        self.alfrescoSession = alfrescoSession;
        request = [self downloadDocument:document];
    }
    else
    {
        [self saveDocument:document contentPath:contentPath completionBlock:completionBlock];
    }
    
    return request;
}

- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    [self saveDocument:document contentPath:contentPath suppressAlerts:NO completionBlock:completionBlock];
}

- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath suppressAlerts:(BOOL)suppressAlerts completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    [self saveDocument:document documentName:nil contentPath:contentPath suppressAlerts:suppressAlerts completionBlock:completionBlock];
}

- (void)saveDocument:(AlfrescoDocument *)document documentName:(NSString *)documentName contentPath:(NSString *)contentPath completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    [self saveDocument:document documentName:documentName contentPath:contentPath suppressAlerts:NO completionBlock:completionBlock];
}

- (void)saveDocument:(AlfrescoDocument *)document documentName:(NSString *)documentName contentPath:(NSString *)contentPath suppressAlerts:(BOOL)suppressAlerts completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    // Check source content exists
    if (contentPath == nil || ![self.fileManager fileExistsAtPath:contentPath])
    {
        AlfrescoLogError(@"Save operation attempted with no valid source document");
    }
    else
    {
        NSString *name = documentName ? documentName : contentPath.lastPathComponent;
        if (![self isDownloadedDocument:name])
        {
            // No existing file, so we're ok to copy from contentPath source to downloads folder
            NSString *filePath;
            NSError *error = nil;
            
            filePath = [self copyToDownloadsFolder:document documentName:documentName contentPath:contentPath overwriteExisting:YES error:&error];
            
            if (!suppressAlerts)
            {
                if (filePath != nil)
                {
                    displayInformationMessage(NSLocalizedString(@"download.success.message", @"Download succeeded"));
                }
                else
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), error.localizedDescription]);
                }
            }
            
            if (completionBlock != NULL)
            {
                completionBlock(filePath);
            }
        }
        else
        {
            void (^copyDocumentBlock)(BOOL) = ^(BOOL overwrite){
                NSError *blockError = nil;
                NSString *blockFilePath = [self copyToDownloadsFolder:document documentName:documentName contentPath:contentPath overwriteExisting:overwrite error:&blockError];;

                if (!suppressAlerts && blockFilePath != nil)
                {
                    if ([blockFilePath.lastPathComponent isEqualToString:contentPath.lastPathComponent])
                    {
                        // Filename has not changed
                        displayInformationMessage(NSLocalizedString(@"download.success.message", @"Download succeeded"));
                    }
                    else
                    {
                        // Filename has been suffixed
                        displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"download.success-as.message", @"Download succeeded"), blockFilePath.lastPathComponent]);
                    }
                }
                else
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), blockError.localizedDescription]);
                }
                
                if (completionBlock != NULL)
                {
                    completionBlock(blockFilePath);
                }
            };
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:NSLocalizedString(@"download.overwrite.prompt.message", @"overwrite alert message")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  copyDocumentBlock(YES);
                                                              }];
            [alertController addAction:yesAction];
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 copyDocumentBlock(NO);
                                                             }];
            [alertController addAction:noAction];
            [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
        }
    }
}

- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath showOverrideAlert:(BOOL)showOverrideAlert completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    if(showOverrideAlert)
    {
        [self saveDocument:document contentPath:contentPath completionBlock:completionBlock];
    }
    else
    {
        if (contentPath == nil || ![self.fileManager fileExistsAtPath:contentPath])
        {
            AlfrescoLogError(@"Save operation attempted with no valid source document");
        }
        else
        {
            NSError *blockError = nil;
            NSString *blockFilePath = [self copyToDownloadsFolder:document documentName:nil contentPath:contentPath overwriteExisting:NO error:&blockError];
            if (completionBlock != NULL)
            {
                completionBlock(blockFilePath);
            }
        }
    }
}

/**
 * TODO: There must be a way this be consolidated with the saveDocument:contentPath:completionBlock method above...
 */
- (void)moveFileIntoSecureContainer:(NSString *)absolutePath completionBlock:(DownloadManagerFileSavedBlock)completionBlock
{
    // Check source content exists
    if (absolutePath == nil || ![[AlfrescoFileManager sharedManager] fileExistsAtPath:absolutePath])
    {
        AlfrescoLogError(@"Move operation attempted with no valid source document");
    }
    else
    {
        if (![self isDownloadedDocument:absolutePath.lastPathComponent])
        {
            // No existing file of the same name, so we're ok to use the original
            NSString *filePath;
            NSError *error = nil;
            
            filePath = [self moveFileToDownloadsFolderFromAbsolutePath:absolutePath overwriteExisting:YES error:&error];
            if (filePath != nil)
            {
                // Always display the filename
                displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"download.success-as.message", @"Download succeeded"), filePath.lastPathComponent]);
            }
            else
            {
                displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), error.localizedDescription]);
            }
            
            if (completionBlock != NULL)
            {
                completionBlock(filePath);
            }
        }
        else
        {
            void (^moveDocumentBlock)(BOOL) = ^(BOOL overwrite){
                NSError *blockError = nil;
                NSString *blockFilePath = [self moveFileToDownloadsFolderFromAbsolutePath:absolutePath overwriteExisting:overwrite error:&blockError];
                
                if (blockFilePath != nil)
                {
                    // Always display the filename
                    displayInformationMessage([NSString stringWithFormat:NSLocalizedString(@"download.success-as.message", @"Download succeeded"), blockFilePath.lastPathComponent]);
                }
                else
                {
                    displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), blockError.localizedDescription]);
                }
                
                if (completionBlock != NULL)
                {
                    completionBlock(blockFilePath);
                }
            };
            
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil
                                                                                     message:NSLocalizedString(@"download.overwrite.prompt.message", @"overwrite alert message")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *yesAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Yes", @"Yes")
                                                                style:UIAlertActionStyleDefault
                                                              handler:^(UIAlertAction * _Nonnull action) {
                                                                  moveDocumentBlock(YES);
                                                              }];
            [alertController addAction:yesAction];
            UIAlertAction *noAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"No", @"No")
                                                               style:UIAlertActionStyleDefault
                                                             handler:^(UIAlertAction * _Nonnull action) {
                                                                 moveDocumentBlock(NO);
                                                             }];
            [alertController addAction:noAction];
            [[UniversalDevice topPresentedViewController] presentViewController:alertController animated:YES completion:nil];
        }
    }
}

- (BOOL)isDownloadedDocument:(NSString *)filePath
{
    NSString *downloadPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:filePath.lastPathComponent];
    return [self.fileManager fileExistsAtPath:downloadPath];
}

- (AlfrescoDocument *)infoForDocument:(NSString *)documentName
{
    NSString *downloadInfoPath = [[[AlfrescoFileManager sharedManager] downloadsInfoContentPath] stringByAppendingPathComponent:[documentName lastPathComponent]];
    NSData *unarchivedDoc = [self.fileManager dataWithContentsOfURL:[NSURL fileURLWithPath:downloadInfoPath]];
    AlfrescoDocument *document = nil;
    
    if (unarchivedDoc)
    {
        document = [NSKeyedUnarchiver unarchiveObjectWithData:unarchivedDoc];
    }
    
    return document;
}

- (void)renameLocalDocument:(NSString *)documentLocalName toName:(NSString *)newName
{
    NSString *localDocumentExistingContentPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:documentLocalName];
    NSString *localDocumentNewContentPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:newName];
    
    NSError *error = nil;
    [self.fileManager moveItemAtPath:localDocumentExistingContentPath toPath:localDocumentNewContentPath error:&error];
    
    if (!error)
    {
        NSString *localDocumentExistingNodePath = [[self.fileManager downloadsInfoContentPath] stringByAppendingPathComponent:documentLocalName];
        NSString *localDocumentNewNodePath = [[self.fileManager downloadsInfoContentPath] stringByAppendingPathComponent:newName];
        [self.fileManager moveItemAtPath:localDocumentExistingNodePath toPath:localDocumentNewNodePath error:&error];
    }
}

- (NSArray *)downloadedDocumentPaths
{
    __block NSMutableArray *documents = [NSMutableArray array];
    NSError *enumeratorError = nil;
    
    [self.fileManager enumerateThroughDirectory:[self.fileManager downloadsContentFolderPath] includingSubDirectories:NO withBlock:^(NSString *fullFilePath) {
        BOOL isDirectory;
        [self.fileManager fileExistsAtPath:fullFilePath isDirectory:&isDirectory];
        
        if (!isDirectory)
        {
            [documents addObject:fullFilePath];
        }
    } error:&enumeratorError];
    
    NSSortDescriptor *sortOrder = [NSSortDescriptor sortDescriptorWithKey:nil ascending:YES comparator:^NSComparisonResult(id firstDocument, id secondDocument) {
        return [firstDocument caseInsensitiveCompare:secondDocument];
    }];
    
    return [documents sortedArrayUsingDescriptors:[NSArray arrayWithObject:sortOrder]];
}

- (NSString *)updateDownloadedDocument:(AlfrescoDocument *)document withContentsOfFileAtPath:(NSString *)filePath
{
    NSError *updateError = nil;
    NSString *savedFilePath = [self copyToDownloadsFolder:document documentName:nil contentPath:filePath overwriteExisting:YES error:&updateError];
    
    if (updateError)
    {
        AlfrescoLogError(@"Error updating downloads. Error: %@", updateError.localizedDescription);
    }
    
    return savedFilePath;
}

#pragma mark - Remove methods

- (void)removeAllDownloads
{
    NSError *removalError = nil;
    [self.fileManager removeItemAtPath:[self.fileManager downloadsFolderPath] error:&removalError];
    
    if (removalError)
    {
        AlfrescoLogError(@"Unable to delete item at path: %@", [self.fileManager downloadsFolderPath]);
    }
    else
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDeletedLocalDocumentsFolderNotification object:nil];
        [self informLocalFilesEnumerator];
    }
}

- (void)removeFromDownloads:(NSString *)filePath
{
    NSString *fileName = [filePath lastPathComponent];
    NSError *error = nil;
    NSString *downloadPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:fileName];
    
    [self.fileManager removeItemAtPath:downloadPath error:&error];
    
    if (!error)
    {
        [self removeDocumentInfo:fileName];
        [self informLocalFilesEnumerator];
    }
    else
    {
        displayErrorMessage(NSLocalizedString(@"download.delete.failure.message", @"Download delete failure"));
    }
}

#pragma mark - Remove methods - private
- (BOOL)removeDocumentInfo:(NSString *)documentName
{
    NSString *downloadInfoPath = [[[AlfrescoFileManager sharedManager] downloadsInfoContentPath] stringByAppendingPathComponent:documentName.lastPathComponent];
    NSError *error = nil;
    
    [self.fileManager removeItemAtPath:downloadInfoPath error:&error];
    
    return error == nil;
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

// Returns the filePath the content was saved to, or nil if an error occurred
- (NSString *)copyToDownloadsFolder:(AlfrescoDocument *)document documentName:(NSString *)documentName contentPath:(NSString *)contentPath overwriteExisting:(BOOL)overwrite error:(NSError **)error
{
    BOOL copySucceeded = NO;
    
    NSString *name = documentName ? documentName : contentPath.lastPathComponent;
    NSString *safeName = fileNameAppendedWithDate(name);
    NSString *destinationFilename = (overwrite ? name : safeName);
    if (destinationFilename != nil)
    {
        if ([self copyDocumentFrom:contentPath destinationFilename:destinationFilename overwriteExisting:overwrite error:error])
        {
            // Note: we're assuming that there will be no problem saving the metadata if the content saves successfully
            [self saveDocumentInfo:document forDocument:destinationFilename error:nil];
            [Notifier postDocumentDownloadedNotificationWithUserInfo:nil];
            [self informLocalFilesEnumerator];
            copySucceeded = YES;
        }
    }

    return (copySucceeded ? [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:destinationFilename] : nil);
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document
{
    NSString *downloadDestinationPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:document.name];
    
    if ([self.fileManager fileExistsAtPath:downloadDestinationPath])
    {
        NSError *suffixError = nil;
        NSString *safeFilename = [self safeFilenameBySuffixing:downloadDestinationPath.lastPathComponent error:&suffixError];
        
        if (suffixError)
        {
            AlfrescoLogError(@"Unable to create safe filename suffix for downloads");
        }
        
        downloadDestinationPath = [[downloadDestinationPath stringByDeletingLastPathComponent] stringByAppendingPathComponent:safeFilename];
    }
    
    NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadDestinationPath append:NO];
    AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:self.alfrescoSession];
    
    return [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
        if (succeeded)
        {
            // Note: we're assuming that there will be no problem saving the metadata if the content saves successfully
            [self saveDocumentInfo:document forDocument:document.name error:nil];
            displayInformationMessage(NSLocalizedString(@"download.success.message", @"download succeeded"));
            [Notifier postDocumentDownloadedNotificationWithUserInfo:nil];
            [self informLocalFilesEnumerator];
        }
        else
        {
            // Display an error
            displayErrorMessage([NSString stringWithFormat:NSLocalizedString(@"error.filefolder.content.failedtodownload", @"Failed to download the file"), error.localizedDescription]);
            [Notifier notifyWithAlfrescoError:error];
        }
    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
        // TODO: Progress indicator update
    }];
}

- (BOOL)copyDocumentFrom:(NSString *)filePath destinationFilename:(NSString *)destinationFilename overwriteExisting:(BOOL)overwrite error:(NSError **)error
{
    NSString *downloadPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:destinationFilename];
    BOOL isDirectory = NO;
    
    if (overwrite && [self.fileManager fileExistsAtPath:downloadPath isDirectory:&isDirectory])
    {
        // remove the file to be overwritten first
        if (![self.fileManager removeItemAtPath:downloadPath error:error])
        {
            // copy will fail if remove failed
            return NO;
        }
    }
    
    // copy the file
    return [self.fileManager copyItemAtPath:filePath toPath:downloadPath error:error];
}

- (NSString *)moveFileToDownloadsFolderFromAbsolutePath:(NSString *)absolutePath overwriteExisting:(BOOL)overwrite error:(NSError **)error
{
    BOOL moveSucceeded = NO;
    NSString *destinationFilename = (overwrite ? absolutePath.lastPathComponent : [self safeFilenameBySuffixing:absolutePath.lastPathComponent error:error]);
    NSString *destinationFilePath = nil;
    if (destinationFilename != nil)
    {
        NSString *downloadPath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:destinationFilename];
        NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:downloadPath append:NO];
        
        if (outputStream)
        {
            [outputStream open];
            if ([outputStream hasSpaceAvailable])
            {
                NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:absolutePath];
                if (inputStream)
                {
                    // Assume success unless an error occurs during copying...
                    moveSucceeded = YES;
                    [inputStream open];
                    
                    while ([inputStream hasBytesAvailable])
                    {
                        uint8_t buffer[kStreamCopyBufferSize];
                        [inputStream read:buffer maxLength:kStreamCopyBufferSize];
                        if ([outputStream write:(const uint8_t*)(&buffer) maxLength:kStreamCopyBufferSize] == -1)
                        {
                            moveSucceeded = NO;
                            break;
                        }
                    }
                    [inputStream close];
                }
            }
            [outputStream close];
        }
      
        if (moveSucceeded)
        {
            // Note: if overwriting then make sure any existing saved documentInfo is removed
            if (overwrite)
            {
                [self saveDocumentInfo:nil forDocument:destinationFilename error:nil];
            }
            destinationFilePath = [[self.fileManager downloadsContentFolderPath] stringByAppendingPathComponent:destinationFilename];
            [Notifier postDocumentDownloadedNotificationWithUserInfo:@{kAlfrescoDocumentDownloadedIdentifierKey : destinationFilePath}];
            [self informLocalFilesEnumerator];
        }
    }
    
    return destinationFilePath;
}

- (BOOL)saveDocumentInfo:(AlfrescoDocument *)document forDocument:(NSString *)documentName error:(NSError **)error
{
    NSString *downloadInfoPath = [[[AlfrescoFileManager sharedManager] downloadsInfoContentPath] stringByAppendingPathComponent:documentName.lastPathComponent];
    
    if (document != nil)
    {
        NSData *archivedDoc = [NSKeyedArchiver archivedDataWithRootObject:document];
        [self.fileManager createFileAtPath:downloadInfoPath contents:archivedDoc error:error];
    }
    else
    {
        // Remove any old info file for the documentName - we don't want to return stale info
        [self.fileManager removeItemAtPath:downloadInfoPath error:error];
    }
    
    return (error == NULL || *error == nil);
}

// Returns just the filenames of downloaded documents
- (NSArray *)downloadedDocumentNames
{
    NSArray *downloadedDocumentPaths = self.downloadedDocumentPaths;
    NSMutableArray *documents = [NSMutableArray arrayWithCapacity:downloadedDocumentPaths.count];
    for (NSString *path in downloadedDocumentPaths)
    {
        [documents addObject:path.lastPathComponent];
    }
    return documents;
}

- (NSString *)safeFilenameBySuffixing:(NSString *)filename error:(NSError **)error
{
    NSString *fileExtension = filename.pathExtension;
    NSString *filenameWithoutExtension = filename.stringByDeletingPathExtension;
    BOOL hasExtension = fileExtension.length > 0;
    NSArray *existingFiles = [self downloadedDocumentNames];
    // We'll bail out after kFileSuffixMaxAttempts attempts
    NSUInteger suffix = 0;
    NSString *safeFilename = filename;
    
    if (hasExtension)
    {
        while ([existingFiles containsObject:safeFilename] && (++suffix < kFileSuffixMaxAttempts))
        {
            safeFilename = [NSString stringWithFormat:@"%@-%@.%@", filenameWithoutExtension, @(suffix), fileExtension];
        }
    }
    else
    {
        while ([existingFiles containsObject:safeFilename] && (++suffix < kFileSuffixMaxAttempts))
        {
            safeFilename = [NSString stringWithFormat:@"%@-%@", filenameWithoutExtension, @(suffix)];
        }
    }
    
    // Did we hit the max suffix number?
    if (suffix == kFileSuffixMaxAttempts)
    {
        AlfrescoLogError(@"ERROR: Couldn't save downloaded file as kFileSuffixMaxAttempts (%u) reached", kFileSuffixMaxAttempts);
        if (error != NULL)
        {
            *error = [NSError errorWithDomain:[[NSBundle mainBundle] bundleIdentifier]
                                         code:kErrorFileSuffixMaxAttempts
                                     userInfo:@{ NSLocalizedDescriptionKey: NSLocalizedString(@"error.description.kErrorFileSuffixMaxAttempts", @"Couldn't generate a unique filename") }];
        }
        return nil;
    }
    
    return safeFilename;
}

#pragma mark - File Provider support
- (void)informLocalFilesEnumerator
{
    [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:kFileProviderLocalFilesPrefix completionHandler:^(NSError * _Nullable error) {
        if (error != NULL)
        {
            AlfrescoLogError(@"ERROR: Couldn't signal enumerator for changes %@", error);
        }
    }];
}

@end
