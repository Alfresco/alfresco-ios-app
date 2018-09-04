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
#import "Utilities.h"
#import "KeychainUtils.h"

#import "AFPItem.h"
#import "AFPItemIdentifier.h"

#import "AFPEnumeratorBuilder.h"

#import "AFPFileService.h"
#import "AFPAccountManager.h"

@interface FileProvider ()
@property (nonatomic, strong) PersistentQueueStore *queueStore;
@property (nonatomic, strong) AFPAccountManager *accountManager;
@property (nonatomic, strong) AFPEnumeratorBuilder *enumeratorBuilder;
@property (nonatomic, strong) AFPFileService *fileService;
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
        self.fileService = [AFPFileService new];
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

#pragma mark - File Provider Methods

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler
{
    NSError *authenticationError = [AFPAccountManager authenticationErrorForPIN];
    if(!authenticationError)
    {
        NSArray <NSString *> *pathComponents = [url pathComponents];
        if(pathComponents.count > 2)
        {
            NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
            AFPItem *item = [self itemForIdentifier:itemIdentifier error:&authenticationError];
            
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
                authenticationError = error;
            }
        }
    }
    
    if (completionHandler)
    {
        completionHandler(authenticationError);
    }
}

- (void)startProvidingItemAtURL:(NSURL *)url completionHandler:(void (^)(NSError *))completionHandler
{
    NSError * authenticationError = [AFPAccountManager authenticationErrorForPIN];
    if(authenticationError)
    {
        completionHandler(authenticationError);
    }
    else
    {
        NSFileManager *fileManager = [[NSFileManager alloc] init];
        NSString *pathToFile = url.path;
        
        if ([fileManager fileExistsAtPath:pathToFile])
        {
            completionHandler(nil);
        }
        else
        {
            NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
            AlfrescoFileProviderItemIdentifierType itemIdentifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
            if (itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
            {
                NSURL *sourceURL = [self.fileService localFilesURLForFilename:url.lastPathComponent];
                NSError *copyError = [self.fileService saveDocumentAtURL:sourceURL toURL:url overwritingExistingFile:NO];
                completionHandler(copyError);
            }
            else
            {
                NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
                NSString *documentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
                [self.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                    if (session)
                    {
                        __block BOOL networkOperationCallbackComplete = NO;
                        NSOutputStream *outputStream = [NSOutputStream outputStreamWithURL:url append:NO];
                        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                        [docService retrieveNodeWithIdentifier:documentIdentifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                            if(node)
                            {
                                [docService retrieveContentOfDocument:(AlfrescoDocument *)node outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                                    networkOperationCallbackComplete = YES;
                                    
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
                                networkOperationCallbackComplete = YES;
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
    
    NSError * authenticationError = [AFPAccountManager authenticationErrorForPIN];
    if(!authenticationError)
    {
        NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
        AlfrescoFileProviderItemIdentifierType itemIdentifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
        if (itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
        {
            NSURL *destinationURL = [self.fileService localFilesURLForFilename:[AFPItemIdentifier filenameFromItemIdentifier:itemIdentifier]];
            __weak typeof(self) weakSelf = self;
            [self.fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingForUploading writingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.fileService saveDocumentAtURL:newReadingURL toURL:newWritingURL overwritingExistingFile:YES];
            }];
        }
        else if(itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeSyncDocument || itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeDocument)
        {
            AlfrescoDocument *alfrescoDoc;
            NSString *accountIdentifier;
            NSURL *destinationURL;
            if(itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeSyncDocument)
            {
                NSString *docSyncIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
                accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
                RealmSyncNodeInfo *syncNode = [[AFPDataManager sharedManager] syncItemForId:docSyncIdentifier forAccountIdentifier:accountIdentifier];
                alfrescoDoc = (AlfrescoDocument *)syncNode.alfrescoNode;
                destinationURL = [NSURL fileURLWithPath:[[[RealmSyncCore sharedSyncCore] syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:syncNode.syncContentPath]];
            }
            else if (itemIdentifierType == AlfrescoFileProviderItemIdentifierTypeDocument)
            {
                accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
                AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
                alfrescoDoc = (AlfrescoDocument *)itemMetadata.alfrescoNode;
                AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
                destinationURL = [item fileURL];
            }
            
            // Coordinate the reading of the file for uploading
            __weak typeof(self) weakSelf = self;
            [self.fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL *newReadingURL) {
                __strong typeof(self) strongSelf = weakSelf;
                [strongSelf.fileCoordinator coordinateWritingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL * _Nonnull newURL) {
                    [weakSelf.fileService saveDocumentAtURL:newReadingURL toURL:newURL overwritingExistingFile:YES];
                }];
                
                __block BOOL networkOperationCallbackComplete = NO;
                // Session exists, use that, else do a login and then upload.
                [strongSelf.accountManager getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                    if(session)
                    {
                        [weakSelf uploadDocument:alfrescoDoc sourceURL:newReadingURL session:session completionBlock:^(AlfrescoDocument *document, NSError *updateError) {
                            if (updateError)
                            {
                                AlfrescoLogError(@"Error Updating Document: %@. Error: %@", alfrescoDoc.name, updateError.localizedDescription);
                            }
                            else
                            {
                                [[AFPDataManager sharedManager] updateSyncDocument:alfrescoDoc withAlfrescoNode:document fromPath:nil fromAccountIdentifier:accountIdentifier];
                            }
                            networkOperationCallbackComplete = YES;
                        }];
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

- (void)importDocumentAtURL:(NSURL *)fileURL toParentItemIdentifier:(NSFileProviderItemIdentifier)parentItemIdentifier completionHandler:(void (^)(NSFileProviderItem _Nullable, NSError * _Nullable))completionHandler
{
    [fileURL startAccessingSecurityScopedResource];
    NSError *error = nil;
    NSDictionary *resourceValues = [fileURL resourceValuesForKeys:@[NSURLNameKey, NSURLCreationDateKey, NSURLContentModificationDateKey, NSURLTypeIdentifierKey, NSURLTotalFileSizeKey] error:&error];
    if(error)
    {
        completionHandler(nil, error);
    }
    else
    {
        AFPItem *item = [[AFPItem alloc] initWithImportedDocumentAtURL:fileURL resourceValues:resourceValues parentItemIdentifier:parentItemIdentifier];
        
        AlfrescoFileProviderItemIdentifierType typeIdentifier = [AFPItemIdentifier itemIdentifierTypeForIdentifier:parentItemIdentifier];
        if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeLocalFiles)
        {
            [self.fileService saveToLocalFilesDocumentAtURL:fileURL];
            [fileURL stopAccessingSecurityScopedResource];
        }
        else if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSyncFolder)
        {
            NSURL *storageURL = [item fileURL];
            NSFileManager *fileManager = [NSFileManager defaultManager];
            [fileManager createDirectoryAtURL:[storageURL URLByDeletingLastPathComponent] withIntermediateDirectories:YES attributes:nil error:nil];
            [self.fileService saveDocumentAtURL:fileURL toURL:storageURL overwritingExistingFile:YES];
            AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveItem:item needsUpload:YES fileURL:storageURL];
            [self.fileService uploadDocumentItem:itemMetadata];
        }
        [fileURL stopAccessingSecurityScopedResource];
        [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:parentItemIdentifier completionHandler:^(NSError * _Nullable error) {
            completionHandler(item, error);
        }];
    }
}

#pragma mark - iOS 11 support

- (nullable NSFileProviderItem)itemForIdentifier:(NSFileProviderItemIdentifier)identifier error:(NSError * _Nullable *)error
{
    AFPItem *item = nil;
    
    if(![identifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if(identifierType == AlfrescoFileProviderItemIdentifierTypeDocument)
        {
            AFPItemMetadata *realmItem = [[AFPDataManager sharedManager] metadataItemForIdentifier:identifier];
            item = [[AFPItem alloc] initWithItemMetadata:realmItem];
        }
        else if(identifierType == AlfrescoFileProviderItemIdentifierTypeSyncDocument)
        {
            RealmSyncNodeInfo *realmItem = [[AFPDataManager sharedManager] syncItemForId:identifier];
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
            item = [[AFPItem alloc] initWithSyncedNode:realmItem parentItemIdentifier:[[AFPDataManager sharedManager] parentItemIdentifierOfSyncedNode:realmItem fromAccountIdentifier:accountIdentifier]];
        }
        else if (identifierType == AlfrescoFileProviderItemIdentifierTypeSyncNewDocument)
        {
            AFPItemMetadata *realmItem = [[AFPDataManager sharedManager] metadataItemForIdentifier:identifier];
            item = [[AFPItem alloc] initWithItemMetadata:realmItem];
        }
        else if (identifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument)
        {
            NSString *filename = [AFPItemIdentifier filenameFromItemIdentifier:identifier];
            NSURL *fileURL = [self.fileService localFilesURLForFilename:filename];
            item = [[AFPItem alloc] initWithLocalFilesPath:fileURL.path];
        }
    }
    else
    {
        item = [[AFPItem alloc] initWithRootContainterItem];
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
        if (identifierType == AlfrescoFileProviderItemIdentifierTypeDocument || identifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument || identifierType == AlfrescoFileProviderItemIdentifierTypeSyncDocument)
        {
            fileURL = [item fileURL];
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
        itemIdentifier = [AFPItemIdentifier itemIdentifierForLocalFilename:[url.path lastPathComponent]];
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

- (nullable id<NSFileProviderEnumerator>)enumeratorForContainerItemIdentifier:(NSFileProviderItemIdentifier)containerItemIdentifier
                                                                        error:(NSError **)error
{
    id<NSFileProviderEnumerator> enumerator = nil;
    NSError *errorToReturn = nil;
    
    if ([containerItemIdentifier isEqualToString:NSFileProviderWorkingSetContainerItemIdentifier])
    {
        // TODO: instantiate an enumerator for the working set
    }
    else
    {
        enumerator = [self.enumeratorBuilder enumeratorForItemIdentifier:containerItemIdentifier];
        
        if (!enumerator) {
            errorToReturn = [NSError errorWithDomain:NSCocoaErrorDomain
                                                code:NSFeatureUnsupportedError
                                            userInfo:nil];
        }
    }
    
    *error = errorToReturn;
    return enumerator;
}

@end
