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
#import "AFPErrorBuilder.h"

@interface FileProvider ()
@property (nonatomic, strong) PersistentQueueStore *queueStore;
@property (nonatomic, strong) AFPAccountManager *accountManager;
@property (nonatomic, strong) AFPEnumeratorBuilder *enumeratorBuilder;
@property (nonatomic, strong) AFPFileService *fileService;
@property (nonatomic, strong) NSFileCoordinator *fileCoordinator;

@end

@implementation FileProvider

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.fileCoordinator = [NSFileCoordinator new];
        self.fileCoordinator.purposeIdentifier = NSFileProviderManager.defaultManager.providerIdentifier;
        
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
    NSError *authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
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
    NSError * authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if(authenticationError)
    {
        completionHandler(authenticationError);
    }
    else
    {        
        NSFileManager *fileManager = [NSFileManager defaultManager];
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
                                if ([kAlfrescoErrorDomainName isEqualToString:error.domain])
                                {
                                    if (kAlfrescoErrorCodeUnauthorisedAccess == error.code)
                                    {
                                        NSError *fpError = [NSError errorWithDomain:NSFileProviderErrorDomain
                                                                               code:NSFileProviderErrorServerUnreachable
                                                                           userInfo:nil];
                                        completionHandler(fpError);
                                    }
                                } else
                                {
                                    completionHandler(error);
                                }
                                
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

    NSError * authenticationError = [AFPErrorBuilder authenticationErrorForPIN];
    if (authenticationError) {
        return;
    }
    
    NSFileProviderItemIdentifier itemIdentifier = [self persistentIdentifierForItemAtURL:url];
    [self handleItemChangeActionForDocumentWithIdentifier:itemIdentifier
                                                    atURL:url];
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
    __block NSError *error;
    if (![fileURL startAccessingSecurityScopedResource])
    {
        error = [NSError errorWithDomain:NSFileProviderErrorDomain
                                    code:NSFileProviderErrorNoSuchItem
                                userInfo:nil];
        
        completionHandler (nil, error);
        return;
    }
    
    NSDictionary *resourceValues = [fileURL resourceValuesForKeys:@[NSURLNameKey,
                                                                    NSURLCreationDateKey,
                                                                    NSURLContentModificationDateKey,
                                                                    NSURLTypeIdentifierKey,
                                                                    NSURLTotalFileSizeKey]
                                                            error:&error];
    
    if (error)
    {
        completionHandler(nil, error);
        return;
    }
    
    AFPItem *item = [[AFPItem alloc] initWithImportedDocumentAtURL:fileURL
                                                    resourceValues:resourceValues
                                              parentItemIdentifier:parentItemIdentifier];
    
    AlfrescoFileProviderItemIdentifierType typeIdentifier = [AFPItemIdentifier itemIdentifierTypeForIdentifier:parentItemIdentifier];
    if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeLocalFiles)
    {
        [self.fileService saveToLocalFilesDocumentAtURL:fileURL];
        [fileURL stopAccessingSecurityScopedResource];
    }
    else if(typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSyncFolder || typeIdentifier == AlfrescoFileProviderItemIdentifierTypeFolder || typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSite || typeIdentifier == AlfrescoFileProviderItemIdentifierTypeMyFiles || typeIdentifier == AlfrescoFileProviderItemIdentifierTypeSharedFiles)
    {
        NSURL *storageURL = [item fileURL];
        
        __weak typeof(self) weakSelf = self;
        [self.fileCoordinator coordinateReadingItemAtURL:fileURL
                                                 options:NSFileCoordinatorReadingWithoutChanges
                                                   error:&error byAccessor:^(NSURL * _Nonnull url){
             __strong typeof(self) strongSelf = weakSelf;
             
             NSFileManager *fileManager = [NSFileManager defaultManager];
             if (![fileManager fileExistsAtPath:url.path])
             {
                 error = [NSError errorWithDomain:NSCocoaErrorDomain
                                             code:NSFileNoSuchFileError
                                         userInfo:nil];
                 
                 completionHandler(nil, error);
                 return ;
             }
             
             NSError *moveError, *removeError;
             
             [fileManager createDirectoryAtURL:[storageURL URLByDeletingLastPathComponent]
                   withIntermediateDirectories:YES
                                    attributes:nil
                                         error:nil];
             
             [fileManager removeItemAtPath:storageURL.path
                                     error:&removeError];
             
             if (removeError)
             {
                 AlfrescoLogWarning(@"Warning - Removing file: %@", removeError.localizedDescription);
             }
             
             [fileManager moveItemAtPath:url.path
                                  toPath:storageURL.path
                                   error:&moveError];
             if (moveError)
             {
                 AlfrescoLogError(@"Encountered an error while importing file: %@", moveError.localizedDescription);
                 completionHandler(nil, moveError);
                 return;
             }
             else
             {
                 [[NSFileProviderManager defaultManager] signalEnumeratorForContainerItemIdentifier:parentItemIdentifier
                                                                                  completionHandler:^(NSError * _Nullable error){
                      completionHandler(item, nil);
                  }];
                 
                 AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] saveItem:item
                                                                              needsUpload:YES
                                                                                  fileURL:storageURL];
                 NSString *metadataIdentifier = itemMetadata.identifier;
                 
                 [strongSelf.fileService uploadDocumentItem:itemMetadata
                                            completionBlock:^(NSError *error) {
                      if (error.code == kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists)
                      {
                          AFPItemMetadata *itemMetadataToRename = [[AFPDataManager sharedManager] metadataItemForIdentifier:metadataIdentifier];
                          NSString *metadataFilename = itemMetadataToRename.name;
                          NSString *documentName =  [weakSelf.fileService fileNameAppendedWithDate:metadataFilename];
                          [[AFPDataManager sharedManager] updateMetadataForIdentifier:metadataIdentifier
                                                            withFileName:documentName];
                          
                          [weakSelf.fileService uploadDocumentItem:itemMetadataToRename
                                                   completionBlock:nil];
                      } else {
                          if (completionHandler)
                          {
                              completionHandler(nil, error);
                          }
                      }
                  }];
             }
         }];
        
        [fileURL stopAccessingSecurityScopedResource];
    }
}

- (nullable NSFileProviderItem)itemForIdentifier:(NSFileProviderItemIdentifier)identifier error:(NSError * _Nullable *)error
{
    AFPItem *item = nil;
    
    if(![identifier isEqualToString:NSFileProviderRootContainerItemIdentifier])
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        
        switch (identifierType) {
            case AlfrescoFileProviderItemIdentifierTypeAccount:
            {
                NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
                UserAccount *account = [AFPAccountManager userAccountForAccountIdentifier:accountIdentifier];
                item = [[AFPItem alloc] initWithUserAccount:account];
                
            }
            break;
            case AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument:
            {
                NSString *filename = [AFPItemIdentifier filenameFromItemIdentifier:identifier];
                NSURL *fileURL = [self.fileService localFilesURLForFilename:filename];
                item = [[AFPItem alloc] initWithLocalFilesPath:fileURL.path];
            }
            break;
            case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
            case AlfrescoFileProviderItemIdentifierTypeMyFiles:
            case AlfrescoFileProviderItemIdentifierTypeFavorites:
            case AlfrescoFileProviderItemIdentifierTypeSynced:
            case AlfrescoFileProviderItemIdentifierTypeSites:
            case AlfrescoFileProviderItemIdentifierTypeFavoriteSites:
            case AlfrescoFileProviderItemIdentifierTypeMySites:
            case AlfrescoFileProviderItemIdentifierTypeFolder:
            case AlfrescoFileProviderItemIdentifierTypeSite:
            case AlfrescoFileProviderItemIdentifierTypeDocument:
            case AlfrescoFileProviderItemIdentifierTypeSyncNewDocument:
            case AlfrescoFileProviderItemIdentifierTypeNewDocument:
            {
                AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] metadataItemForIdentifier:identifier];
                item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
            }
            break;
            case AlfrescoFileProviderItemIdentifierTypeSyncFolder:
            case AlfrescoFileProviderItemIdentifierTypeSyncDocument:
            {
                RealmSyncNodeInfo *realmItem = [[AFPDataManager sharedManager] syncItemForId:identifier];
                NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:identifier];
                item = [[AFPItem alloc] initWithSyncedNode:realmItem parentItemIdentifier:[[AFPDataManager sharedManager] parentItemIdentifierOfSyncedNode:realmItem fromAccountIdentifier:accountIdentifier]];
            }
                break;
            case AlfrescoFileProviderItemIdentifierTypeLocalFiles:
            {
                item = [[AFPItem alloc] initWithItemMetadata:[[AFPDataManager sharedManager] localFilesItem]];
            }
            break;
            default:
                break;
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
    
    AFPItem *item = [self itemForIdentifier:identifier
                                      error:NULL];
    if([item.itemIdentifier isEqualToString:identifier])
    {
        AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:identifier];
        if (identifierType == AlfrescoFileProviderItemIdentifierTypeDocument ||
            identifierType == AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument ||
            identifierType == AlfrescoFileProviderItemIdentifierTypeSyncDocument ||
            identifierType == AlfrescoFileProviderItemIdentifierTypeSyncNewDocument ||
            identifierType == AlfrescoFileProviderItemIdentifierTypeNewDocument)
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


#pragma mark - EDIT operation handlers

- (void)handleItemChangeActionForDocumentWithIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                  atURL:(NSURL *)url
{
    AlfrescoFileProviderItemIdentifierType itemIdentifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
    
    switch (itemIdentifierType) {
        case AlfrescoFileProviderItemIdentifierTypeLocalFilesDocument:
        {
            [self handleItemChangeActionForLocalFileDocumentWithItemIdentifier:itemIdentifier
                                                                         atURL:url];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeSyncDocument:
        {
            [self handleItemChangeActionForSyncDocumentWithItemIdentifier:itemIdentifier
                                                                    atURL:url];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeSyncNewDocument:
        {
            [self handleItemChangeActionForNewSyncDocumentWithItemIdentifier:itemIdentifier
                                                                       atURL:url];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeDocument:
        {
            [self handleItemChangeActionForDocumentTypeWithItemIdentifier:itemIdentifier
                                                                    atURL:url];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeNewDocument:
        {
            [self handleItemChangeActionForNewDocumentTypeWithItemIdentifier:itemIdentifier
                                                                       atURL:url];
        }
            break;
            
        default: break;
    }
}

- (void)handleItemChangeActionForLocalFileDocumentWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                               atURL:(NSURL *)url
{
    NSURL *destinationURL = [self.fileService localFilesURLForFilename:[AFPItemIdentifier filenameFromItemIdentifier:itemIdentifier]];
    
    __weak typeof(self) weakSelf = self;
    [self.fileCoordinator coordinateReadingItemAtURL:url
                                             options:NSFileCoordinatorReadingForUploading
                                    writingItemAtURL:destinationURL
                                             options:NSFileCoordinatorWritingForReplacing
                                               error:nil
                                          byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL){
        __strong typeof(self) strongSelf = weakSelf;
        [strongSelf.fileService saveDocumentAtURL:newReadingURL
                                            toURL:newWritingURL
                          overwritingExistingFile:YES];
    }];
}

- (void)handleItemChangeActionForSyncDocumentWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                          atURL:(NSURL *)url {
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
    NSString *docSyncIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
    RealmSyncNodeInfo *syncNode = [[AFPDataManager sharedManager] syncItemForId:docSyncIdentifier
                                                           forAccountIdentifier:accountIdentifier];
    AlfrescoDocument *alfrescoDoc = (AlfrescoDocument *)syncNode.alfrescoNode;
    NSURL *destinationURL = [NSURL fileURLWithPath:[[[RealmSyncCore sharedSyncCore] syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:syncNode.syncContentPath]];
    
    [self performUploadActionsForAccountIdentifier:accountIdentifier alfrescoDoc:alfrescoDoc destinationURL:destinationURL itemIdentifier:itemIdentifier url:url];
}

- (void)handleItemChangeActionForNewSyncDocumentWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                             atURL:(NSURL *)url
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
    AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
    
    if (itemMetadata.alfrescoNode)
    {
        RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
        
        RealmSyncNodeInfo *syncNode =
        [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:itemMetadata.alfrescoNode
                                         ifNotExistsCreateNew:NO
                                                      inRealm:realm];
        
        AlfrescoDocument *alfrescoDoc = (AlfrescoDocument *)syncNode.alfrescoNode;
        NSURL *destinationURL = [NSURL fileURLWithPath:[[[RealmSyncCore sharedSyncCore] syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:syncNode.syncContentPath]];
        
        [self performUploadActionsForAccountIdentifier:accountIdentifier alfrescoDoc:alfrescoDoc destinationURL:destinationURL itemIdentifier:itemIdentifier url:url];
    }
}

- (void)handleItemChangeActionForNewDocumentTypeWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                             atURL:(NSURL *)url
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
    AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
    
    if (itemMetadata.alfrescoNode)
    {
        AlfrescoDocument *alfrescoDoc = (AlfrescoDocument *)itemMetadata.alfrescoNode;
        NSURL *destinationURL = [NSURL fileURLWithPath:itemMetadata.filePath];
        
        [self performUploadActionsForAccountIdentifier:accountIdentifier alfrescoDoc:alfrescoDoc destinationURL:destinationURL itemIdentifier:itemIdentifier url:url];
    }
}

- (void)handleItemChangeActionForDocumentTypeWithItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                                                          atURL:(NSURL *)url
{
    NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
    AFPItemMetadata *itemMetadata = [[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
    AlfrescoDocument *alfrescoDoc = (AlfrescoDocument *)itemMetadata.alfrescoNode;
    AFPItem *item = [[AFPItem alloc] initWithItemMetadata:itemMetadata];
    NSURL *destinationURL = [item fileURL];
    
    [self performUploadActionsForAccountIdentifier:accountIdentifier alfrescoDoc:alfrescoDoc destinationURL:destinationURL itemIdentifier:itemIdentifier url:url];
}

- (void)performUploadActionsForAccountIdentifier:(NSString *)accountIdentifier alfrescoDoc:(AlfrescoDocument *)alfrescoDoc destinationURL:(NSURL *)destinationURL itemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier url:(NSURL *)url
{
    __weak typeof(self) weakSelf = self;
    [self prepareFileUploadForEditedItemAtURL:url
                               destinationURL:destinationURL
                          withCompletionBlock:^(NSURL *readingURL, NSError *error) {
         __strong typeof(self) strongSelf = weakSelf;
         
         [strongSelf uploadEditedItem:alfrescoDoc
                   withItemIdentifier:itemIdentifier
                                atURL:readingURL
                 forAccountIdentifier:accountIdentifier
                  withCompletionBlock:^(NSError *error) {
                      if(!error)
                      {
                          AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
                          if(identifierType == AlfrescoFileProviderItemIdentifierTypeNewDocument || identifierType == AlfrescoFileProviderItemIdentifierTypeSyncNewDocument)
                          {
                              [[AFPDataManager sharedManager] removeItemMetadataForIdentifier:itemIdentifier];
                          }
                      }
                  }];
     }];
}

- (void)prepareFileUploadForEditedItemAtURL:(NSURL *)url
                             destinationURL:(NSURL *)destinationURL
                        withCompletionBlock:(void (^)(NSURL *readingURL, NSError *error))completionBlock
{
    __block NSError *error = nil;
    __weak typeof(self) weakSelf = self;
    [self.fileCoordinator coordinateReadingItemAtURL:url
                                             options:NSFileCoordinatorReadingForUploading
                                               error:&error
                                          byAccessor:^(NSURL *newReadingURL)
     {
         __strong typeof(self) strongSelf = weakSelf;
         if (error) {
             completionBlock(nil, error);
             return ;
         }
         
         [strongSelf.fileCoordinator coordinateWritingItemAtURL:destinationURL
                                                        options:NSFileCoordinatorWritingForReplacing
                                                          error:&error
                                                     byAccessor:^(NSURL * _Nonnull newURL)
          {
              if (error) {
                  completionBlock(nil, error);
                  return;
              } else {
                  [weakSelf.fileService saveDocumentAtURL:newReadingURL
                                                    toURL:newURL
                                  overwritingExistingFile:YES];
                  
                  completionBlock(newReadingURL, nil);
              }
          }];
     }];
}

- (void)uploadEditedItem:(AlfrescoDocument *)alfrescoDocument
      withItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier
                   atURL:(NSURL *)url
    forAccountIdentifier:(NSString *)accountIdentifier
     withCompletionBlock:(void (^)(NSError *error))completionBlock

{
    __block AlfrescoDocument *oldAlfrescoDocument = alfrescoDocument;
    __block BOOL networkOperationCallbackComplete = NO;
    __weak typeof(self) weakSelf = self;
    
    // Session exists, use that, else do a login and then upload.
    [self.accountManager getSessionForAccountIdentifier:accountIdentifier
                                      networkIdentifier:nil
                                    withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError)
     {
         if(session)
         {
             [weakSelf uploadDocument:oldAlfrescoDocument
                            sourceURL:url
                              session:session
                      completionBlock:^(AlfrescoDocument *newAlfrescoDocument, NSError *updateError) {
                          if (updateError)
                          {
                              AlfrescoLogError(@"Error Updating Document: %@. Error: %@", oldAlfrescoDocument.name, updateError.localizedDescription);
                          }
                          else
                          {
                              [[AFPDataManager sharedManager] updateSyncDocument:oldAlfrescoDocument
                                                                withAlfrescoNode:newAlfrescoDocument
                                                                        fromPath:nil
                                                           fromAccountIdentifier:accountIdentifier];
                          }
                          if(completionBlock)
                          {
                              completionBlock(updateError);
                          }
                          
                          networkOperationCallbackComplete = YES;
                      }];
         }
         else
         {
             if(completionBlock)
             {
                 completionBlock(loginError);
             }
             
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

@end
