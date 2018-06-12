/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import "FileProvider.h"
#import <UIKit/UIKit.h>
#import "PersistentQueueStore.h"
#import "FileMetadata.h"
#import "SharedConstants.h"
#import "AlfrescoFileManager+Extensions.h"
#import "NSFileManager+Extension.h"
#import "Utilities.h"

#import "AFPItem.h"
#import "AFPItemIdentifier.h"

#import "AFPEnumeratorBuilder.h"

#import "AFPDataManager.h"
#import "AFPAccountManager.h"

@interface FileProvider ()
@property (nonatomic, strong) PersistentQueueStore *queueStore;
@property (nonatomic, strong) AFPAccountManager *accountManager;
@property (nonatomic, strong) AFPEnumeratorBuilder *enumeratorBuilder;
@end

@implementation FileProvider

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self.fileCoordinator coordinateWritingItemAtURL:[self documentStorageURL] options:0 error:nil byAccessor:^(NSURL *newURL) {
            // ensure the documentStorageURL actually exists
            NSError *error = nil;
            [[NSFileManager defaultManager] createDirectoryAtURL:newURL withIntermediateDirectories:YES attributes:nil error:&error];
        }];
        
        self.accountManager = [AFPAccountManager sharedManager];
        self.enumeratorBuilder = [AFPEnumeratorBuilder new];
    }
    return self;
}

#pragma mark - Custom Getters and Setters

- (NSFileCoordinator *)fileCoordinator
{
    NSFileCoordinator *fileCoordinator = [[NSFileCoordinator alloc] init];
    [fileCoordinator setPurposeIdentifier:[self providerIdentifier]];
    return fileCoordinator;
}

- (PersistentQueueStore *)queueStore
{
    if (!_queueStore)
    {
        _queueStore = [[PersistentQueueStore alloc] initWithGroupContainerIdentifier:kSharedAppGroupIdentifier];
    }
    return _queueStore;
}

#pragma mark - Private Methods

- (FileMetadata *)fileMetadataForURL:(NSURL *)fileURL
{
    FileMetadata *returnMetadata = nil;
    
    /*
     * We need the unique document identifier appended onto the URL.
     * Since we can't get access to the document, in order to generate this, we simply take the 
     * last two path components from the url provided in order to generate the search url.
     */
    NSArray *pathComponents = fileURL.pathComponents;
    NSArray *folderAndFilePathComponents = [pathComponents subarrayWithRange:NSMakeRange(pathComponents.count - 2, 2)];
    NSString *lastTwoPathString = [NSString pathWithComponents:folderAndFilePathComponents];
    
    NSString *lastPartDocumentStorageURL = self.documentStorageURL.lastPathComponent;
    if([lastTwoPathString containsString:lastPartDocumentStorageURL])
    {
        lastTwoPathString = folderAndFilePathComponents.lastObject;
    }
    
    NSURL *searchURL = [self.documentStorageURL URLByAppendingPathComponent:lastTwoPathString];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"fileURL == %@", searchURL];
    NSArray *urlSearchResultArray = [self.queueStore.queue filteredArrayUsingPredicate:searchPredicate];
    
    returnMetadata = urlSearchResultArray.lastObject;
    
    return returnMetadata;
}

- (void)uploadDocument:(AlfrescoDocument *)document sourceURL:(NSURL *)fileURL session:(id<AlfrescoSession>)session completionBlock:(void (^)(AlfrescoDocument *document, NSError *updateError))completionBlock
{
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:fileURL];
    
    AlfrescoVersionService *versionService = [[AlfrescoVersionService alloc] initWithSession:session];
    [versionService checkoutDocument:document completionBlock:^(AlfrescoDocument *checkoutDocument, NSError *checkoutError) {
        if (checkoutError)
        {
            if(checkoutError.code != kAlfrescoErrorCodeVersion)
            {
                completionBlock(checkoutDocument, checkoutError);
            }
        }
        else
        {
            [versionService checkinDocument:document asMajorVersion:NO contentFile:contentFile properties:nil comment:nil completionBlock:^(AlfrescoDocument *checkinDocument, NSError *checkinError) {
                completionBlock(checkinDocument, checkinError);
            } progressBlock:nil];
        }
    }];
}

- (void)saveDocumentAtURL:(NSURL *)readingURL toURL:(NSURL *)writingURL overwritingExistingFile:(BOOL)shouldOverwrite
{
    NSError *copyError = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    if(!shouldOverwrite && [fileManager fileExistsAtPath:[writingURL path]])
    {
        NSString *filename = [self fileNameAppendedWithDate:writingURL.lastPathComponent];
        writingURL = [[writingURL URLByDeletingLastPathComponent] URLByAppendingPathComponent:filename];
    }
    [fileManager copyItemAtURL:readingURL toURL:writingURL overwritingExistingFile:shouldOverwrite error:&copyError];
    
    if (copyError)
    {
        AlfrescoLogError(@"Unable to copy file at path: %@, to location: %@. Error: %@", readingURL, writingURL, copyError.localizedDescription);
    }
}

- (NSString *)fileNameAppendedWithDate:(NSString *)name
{
    NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd-HH-mm-ss"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    NSString *fileExtension = name.pathExtension;
    NSString *fileName = [NSString stringWithFormat:@"%@_%@", name.stringByDeletingPathExtension, dateString];
    
    if (fileExtension.length > 0)
    {
        fileName = [fileName stringByAppendingPathExtension:fileExtension];
    }
    
    return fileName;
}

#pragma mark - File Provider Methods

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler
{
    FileMetadata *fileMetadata = [self fileMetadataForURL:url];
    NSError *placeholderWriteError = nil;
    if (fileMetadata)
    {
        // iOS 10
        AlfrescoDocument *document = (AlfrescoDocument *)fileMetadata.repositoryNode;
        NSString *fileName = document.name;
        unsigned long long fileSize = document.contentLength;
        
        NSURL *placeholderURL = [NSFileProviderExtension placeholderURLForURL:[self.documentStorageURL URLByAppendingPathComponent:fileName]];
        
        [self.fileCoordinator coordinateWritingItemAtURL:placeholderURL options:0 error:&placeholderWriteError byAccessor:^(NSURL *newURL) {
            NSDictionary *metadata = @{NSURLNameKey : document.name, NSURLFileSizeKey : @(fileSize), NSURLContentModificationDateKey : document.modifiedAt};
            [NSFileProviderExtension writePlaceholderAtURL:placeholderURL withMetadata:metadata error:NULL];
        }];
    }
    else
    {
        // iOS 11
        NSArray <NSString *> *pathComponents = [url pathComponents];
        if(pathComponents.count > 2)
        {
            NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
            AFPItem *item = [self itemForIdentifier:itemIdentifier error:&placeholderWriteError];

            if(item)
            {
                NSURL *placeholderURL = [NSFileProviderManager placeholderURLForURL:url];
                NSFileManager *fileManager = [NSFileManager new];
                [fileManager createDirectoryAtURL:[placeholderURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
                NSError *error = nil;
                @try
                {
                    [NSFileProviderManager writePlaceholderAtURL:placeholderURL withMetadata:item error:&error];
                }
                @catch (NSException *e)
                {
                    AlfrescoLogError(@"Exception: %@", e);
                }
                placeholderWriteError = error;
            }
        }
    }
    
    if (completionHandler)
    {
        completionHandler(placeholderWriteError);
    }
}

- (void)startProvidingItemAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSString *pathToFile = url.path;
    
    if ([fileManager fileExistsAtPath:pathToFile])
    {
        completionHandler(nil);
    }
    else
    {
        FileMetadata *metadata = [self fileMetadataForURL:url];
        if(metadata)
        {
            // iOS 10
            if (metadata.saveLocation == FileMetadataSaveLocationRepository)
            {
                [self.accountManager getSessionForAccountIdentifier:metadata.accountIdentifier networkIdentifier:metadata.networkIdentifier withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                    if (session)
                    {
                        NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:url append:NO];
                        
                        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                        [docService retrieveContentOfDocument:(AlfrescoDocument *)metadata.repositoryNode outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                            if (error)
                            {
                                completionHandler(error);
                            }
                            else
                            {
                                completionHandler(nil);
                            }
                        } progressBlock:nil];
                    }
                    else
                    {
                        completionHandler(loginError);
                    }
                }];
            }
            else if (metadata.saveLocation == FileMetadataSaveLocationLocalFiles)
            {
                NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
                NSString *fullSourcePath = [downloadContentPath stringByAppendingPathComponent:url.lastPathComponent];
                NSURL *sourceURL = [NSURL fileURLWithPath:fullSourcePath];
                
                NSError *copyError = nil;
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                [fileManager copyItemAtURL:sourceURL toURL:url error:&copyError];
                
                if (copyError)
                {
                    AlfrescoLogError(@"Unable to copy item from: %@, to: %@. Error: %@", sourceURL, url, copyError.localizedDescription);
                }
                
                completionHandler(copyError);
            }
        }
        else
        {
            // iOS 11
            NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
            AlfrescoFileProviderItemIdentifierType itemIdentifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
            if (itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
            {
                NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
                NSString *fullSourcePath = [downloadContentPath stringByAppendingPathComponent:url.lastPathComponent];
                NSURL *sourceURL = [NSURL fileURLWithPath:fullSourcePath];
                
                NSError *copyError = nil;
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                [fileManager copyItemAtURL:sourceURL toURL:url error:&copyError];
                if (copyError)
                {
                    AlfrescoLogError(@"Unable to copy item from: %@, to: %@. Error: %@", sourceURL, url, copyError.localizedDescription);
                }
                
                completionHandler(copyError);
            }
            else
            {
                NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
                NSString *documentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
                
                [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                    if (session)
                    {
                        NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:url append:NO];
                        
                        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                        [docService retrieveNodeWithIdentifier:documentIdentifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                            if(node)
                            {
                                [docService retrieveContentOfDocument:(AlfrescoDocument *)node outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                                    if (error)
                                    {
                                        completionHandler(error);
                                    }
                                    else
                                    {
                                        [[AFPDataManager sharedManager] updateMetadataForIdentifier:itemIdentifier downloaded:YES];
                                        completionHandler(nil);
                                    }
                                } progressBlock:nil];
                            }
                            else
                            {
                                completionHandler(error);
                            }
                        }];
                    }
                    else
                    {
                        completionHandler(loginError);
                    }
                }];
            }
        }
    }
}

- (void)itemChangedAtURL:(NSURL *)url
{
    AlfrescoLogInfo(@"Item changed at URL %@", url);
    
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    NSDictionary *fileAttributes = [fileManager attributesOfItemAtPath:url.path error:nil];
    NSDate *urlModificationDate = fileAttributes[NSFileModificationDate];
    
    FileMetadata *metadata = [self fileMetadataForURL:url];
    if(metadata)
    {
        // the document exists in the AlfrescoRepository
        AlfrescoDocument *repoNode = (AlfrescoDocument *)metadata.repositoryNode;
        
        if (![repoNode.modifiedAt isEqualToDate:urlModificationDate] && metadata.status != FileMetadataStatusUploading)
        {
            if (metadata.saveLocation == FileMetadataSaveLocationRepository)
            {
                // Coordinate the reading of the file for uploading
                [self.fileCoordinator coordinateReadingItemAtURL:metadata.fileURL options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL *newReadingURL) {
                    // define an upload block
                    __block BOOL networkOperationCallbackComplete = NO;
                    void (^uploadBlock)(id<AlfrescoSession>session) = ^(id<AlfrescoSession>session) {
                        AlfrescoDocument *updateDocument = (AlfrescoDocument *)metadata.repositoryNode;
                        [self uploadDocument:updateDocument sourceURL:newReadingURL session:session completionBlock:^(AlfrescoDocument *document, NSError *updateError) {
                            if (updateError)
                            {
                                AlfrescoLogError(@"Error Updating Document: %@. Error: %@", updateDocument.name, updateError.localizedDescription);
                                NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
                                NSString *filename = url.lastPathComponent;
                                filename = [Utilities filenameWithoutVersionFromFilename:filename nodeIdentifier:repoNode.identifier];
                                NSString *fullDestinationPath = [downloadContentPath stringByAppendingPathComponent:filename];
                                NSURL *destinationURL = [NSURL fileURLWithPath:fullDestinationPath];
                                [self.fileCoordinator coordinateWritingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull newURL) {
                                    [self saveDocumentAtURL:newReadingURL toURL:newURL overwritingExistingFile:YES];
                                }];
                            }
                            else
                            {
                                AlfrescoLogInfo(@"Successfully updated document: %@, Modified At: %@, Created At: %@", document.name, document.modifiedAt, document.createdAt);
                                metadata.repositoryNode = document;
                            }
                            networkOperationCallbackComplete = YES;
                            metadata.status = FileMetadataStatusPendingUpload;
                            [self.queueStore saveQueue];
                        }];
                        
                        // Set the metadata to uploading - ensure the upload doesnt start again.
                        metadata.status = FileMetadataStatusUploading;
                        [self.queueStore saveQueue];
                    };
                    
                    // Session exists, use that, else do a login and then upload.
                    [self.accountManager getSessionForAccountIdentifier:metadata.accountIdentifier networkIdentifier:metadata.networkIdentifier withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                        if(loginError)
                        {
                            AlfrescoLogError(@"Error Logging In: %@", loginError.localizedDescription);
                            NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
                            NSString *filename = url.lastPathComponent;
                            filename = [Utilities filenameWithoutVersionFromFilename:filename nodeIdentifier:repoNode.identifier];
                            NSString *fullDestinationPath = [downloadContentPath stringByAppendingPathComponent:filename];
                            NSURL *destinationURL = [NSURL fileURLWithPath:fullDestinationPath];
                            [self.fileCoordinator coordinateWritingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull newURL) {
                                [self saveDocumentAtURL:newReadingURL toURL:newURL overwritingExistingFile:YES];
                            }];
                        }
                        else
                        {
                            uploadBlock(session);
                        }
                    }];
                    
                    /*
                    * Keep this object around long enough for the network operations to complete.
                    * Running as a background thread, seperate from the UI, so should not cause
                    * Any issues when blocking the thread.
                    */
                    do
                    {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    }
                    while (networkOperationCallbackComplete == NO);
                }];
                
            }
            else if (metadata.saveLocation == FileMetadataSaveLocationLocalFiles)
            {
                NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
                NSString *fullDestinationPath = [downloadContentPath stringByAppendingPathComponent:url.lastPathComponent];
                NSURL *destinationURL = [NSURL fileURLWithPath:fullDestinationPath];
                [self.fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingForUploading writingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                    [self saveDocumentAtURL:newReadingURL toURL:newWritingURL overwritingExistingFile:YES];
                }];
            }
        }
    }
}

- (void)stopProvidingItemAtURL:(NSURL *)url
{
    FileMetadata *completedMetadata = [self fileMetadataForURL:url];
    [self.queueStore removeObjectFromQueue:completedMetadata];
    [self.queueStore saveQueue];
    
    [self.fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:NULL];
    }];
    [self providePlaceholderAtURL:url completionHandler:^(NSError *error) {}];
}

#pragma mark - iOS 11 support

- (nullable NSFileProviderItem)itemForIdentifier:(NSFileProviderItemIdentifier)identifier error:(NSError * _Nullable *)error
{
    AFPItem *item = nil;
    
    if(![identifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if(identifierType == AlfrescoFileProviderItemIdentifierTypeDocument || identifierType == AlfrescoFileProviderItemIdentifierTypeSyncNode)
        {
            id realmItem = [[AFPDataManager sharedManager] dbItemForIdentifier:identifier];
            if([realmItem isKindOfClass:[AFPItemMetadata class]])
            {
                item = [[AFPItem alloc] initWithItemMetadata:realmItem];
            }
            else if([realmItem isKindOfClass:[RealmSyncNodeInfo class]])
            {
                RealmSyncNodeInfo *realmSyncItem = (RealmSyncNodeInfo *)realmItem;
                if(!realmSyncItem.isFolder)
                {
                    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
                    item = [[AFPItem alloc] initWithSyncedNode:realmItem parentItemIdentifier:[[AFPDataManager sharedManager] parentItemIdentifierOfSyncedNode:realmItem fromAccountIdentifier:accountIdentifier]];
                }
            }
        }
        else if (identifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
        {
            AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
            NSString *filename = [AFPItemIdentifier filenameFromItemIdentifier:identifier];
            NSString *path = [[fileManager downloadsContentFolderPath] stringByAppendingPathComponent:filename];
            item = [[AFPItem alloc] initWithLocalFilesPath:path];
        }
    }
    return item;
}

- (nullable NSURL *)URLForItemWithPersistentIdentifier:(NSFileProviderItemIdentifier)identifier
{
    NSURL *fileURL = nil;
    
    AFPItem *item = [self itemForIdentifier:identifier error:NULL];
    if(item)
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if(identifierType == AlfrescoFileProviderItemIdentifierTypeSyncNode)
        {
            RealmSyncNodeInfo *nodeInfo = (RealmSyncNodeInfo *)[[AFPDataManager sharedManager] dbItemForIdentifier:identifier];
            NSFileProviderManager *manager = [NSFileProviderManager defaultManager];
            NSString *itemPath = [[manager.documentStorageURL.absoluteString stringByDeletingLastPathComponent] stringByAppendingPathComponent:kSyncFolder];
            itemPath = [itemPath stringByAppendingPathComponent:[AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier]];
            itemPath = [itemPath stringByAppendingPathComponent:nodeInfo.syncContentPath];
            fileURL = [NSURL URLWithString:itemPath];
        }
        else if (identifierType == AlfrescoFileProviderItemIdentifierTypeDocument || identifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
        {
            // in this implementation, all paths are structured as <base storage directory>/<item identifier>/<item file name>
            NSFileProviderManager *manager = [NSFileProviderManager defaultManager];
            NSURL *perItemDirectory = [manager.documentStorageURL URLByAppendingPathComponent:identifier isDirectory:YES];
            fileURL = [perItemDirectory URLByAppendingPathComponent:item.filename isDirectory:NO];
        }
    }
    
    return fileURL;
}

- (nullable NSFileProviderItemIdentifier)persistentIdentifierForItemAtURL:(NSURL *)url
{
    // resolve the given URL to a persistent identifier using a database
    NSFileProviderItemIdentifier itemIdentifier;
    NSString *folderString = [url.path stringByDeletingLastPathComponent];
    if([folderString isEqualToString:[[AlfrescoFileManager sharedManager] downloadsContentFolderPath]])
    {
        itemIdentifier = [AFPItemIdentifier itemIdentifierForLocalFilePath:url.path];
    }
    else
    {
        NSArray <NSString *> *pathComponents = [url pathComponents];
        if(pathComponents.count > 3)
        {
            if([pathComponents[pathComponents.count - 3] isEqualToString:kSyncFolder])
            {
                // Sync/<account identifier>/<sync content path>
                itemIdentifier = [[AFPDataManager sharedManager] itemIdentifierOfSyncedNodeWithURL:url];
            }
            else
            {
                // exploit the fact that the path structure has been defined as
                // <base storage directory>/<item identifier>/<item file name> above
                itemIdentifier = pathComponents[pathComponents.count - 2];
            }
        }
    }
    
    return itemIdentifier;
}

#pragma mark - Enumeration

- (nullable id<NSFileProviderEnumerator>)enumeratorForContainerItemIdentifier:(NSFileProviderItemIdentifier)containerItemIdentifier error:(NSError **)error
{
    id<NSFileProviderEnumerator> enumerator = nil;
    if ([containerItemIdentifier isEqualToString:NSFileProviderWorkingSetContainerItemIdentifier])
    {
        // TODO: instantiate an enumerator for the working set
    }
    else
    {
        enumerator = [self.enumeratorBuilder enumeratorForItemIdentifier:containerItemIdentifier];
    }
    
    return enumerator;
}

@end
