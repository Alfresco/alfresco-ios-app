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

#import "AFPFileService.h"
#import "AFPItemIdentifier.h"
#import "AFPAccountManager.h"
#import "AlfrescoFileManager+Extensions.h"
#import "NSFileManager+Extension.h"
#import "CustomFolderService.h"

@interface AFPFileService()

@property (strong, nonatomic) AlfrescoSiteService *siteService;
@property (strong, nonatomic) CustomFolderService *customFolderService;
@property (strong, nonatomic) AlfrescoDocumentFolderService *documentFolderService;

@end

@implementation AFPFileService

- (void)retrieveFolderNodeForItemIdentifier:(NSFileProviderItemIdentifier)itemIdentifier usingSession:(id<AlfrescoSession>)session completionBlock:(AlfrescoNodeCompletionBlock)completionBlock
{
    AlfrescoFileProviderItemIdentifierType identifierType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
    switch (identifierType) {
        case AlfrescoFileProviderItemIdentifierTypeFolder:
        {
            self.documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            NSString *parentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
            [self.documentFolderService retrieveNodeWithIdentifier:parentIdentifier completionBlock:completionBlock];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeMyFiles:
        {
            self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
            [self.customFolderService retrieveMyFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                completionBlock(folder, error);
            }];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeSharedFiles:
        {
            self.customFolderService = [[CustomFolderService alloc] initWithSession:session];
            [self.customFolderService retrieveSharedFilesFolderWithCompletionBlock:^(AlfrescoFolder *folder, NSError *error) {
                completionBlock(folder, error);
            }];
        }
            break;
        case AlfrescoFileProviderItemIdentifierTypeSite:
        {
            self.siteService = [[AlfrescoSiteService alloc] initWithSession:session];
            NSString *parentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemIdentifier];
            [self.siteService retrieveDocumentLibraryFolderForSite:parentIdentifier completionBlock:^(AlfrescoFolder *folder, NSError *error) {
                completionBlock(folder, error);
            }];
        }
            break;
            
        default:
            break;
    }
    
}

- (void)uploadDocumentItem:(AFPItemMetadata *)item
           completionBlock:(void (^)(NSError *error))completionBlock
{
    NSString *itemIdentifier = item.identifier;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @autoreleasepool{
            __block BOOL networkOperationCallbackComplete = NO;
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
            
            __weak typeof(self) weakSelf = self;
            [[AFPAccountManager sharedManager] getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                __strong typeof(self) strongSelf = weakSelf;
                if(session)
                {
                    AFPItemMetadata *itemMetadata = (AFPItemMetadata *)[[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
                    NSString *filePath = itemMetadata.filePath;
                    NSString *fileName = itemMetadata.name;
                    if(itemMetadata.parentIdentifier.length)
                    {
                        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                        [strongSelf retrieveFolderNodeForItemIdentifier:itemMetadata.parentIdentifier usingSession:session completionBlock:^(AlfrescoNode *node, NSError *error) {
                            if(node)
                            {
                                AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:filePath]];
                                [docService createDocumentWithName:fileName inParentFolder:(AlfrescoFolder *)node contentFile:contentFile properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
                                    if (error)
                                    {
                                        if (completionBlock)
                                        {
                                            completionBlock(error);
                                        }
                                    }
                                    else if(document)
                                    {
                                        AlfrescoFileProviderItemIdentifierType itemType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
                                        if(itemType == AlfrescoFileProviderItemIdentifierTypeSyncDocument)
                                        {
                                            [weakSelf handleUploadOfSyncDocument:document
                                                                        fromFile:contentFile
                                                                        toFolder:(AlfrescoFolder *)node
                                                                      forAccount:accountIdentifier
                                                      withItemMetadataIdentifier:itemIdentifier];
                                        }
                                        else if (itemType == AlfrescoFileProviderItemIdentifierTypeSyncNewDocument)
                                        {
                                            [weakSelf handleUploadOfNewSyncDocument:document
                                                                       withMetadata:itemMetadata
                                                                         forAccount:accountIdentifier];
                                        }
                                        else if (itemType == AlfrescoFileProviderItemIdentifierTypeNewDocument)
                                        {
                                            [[AFPDataManager sharedManager] updateMetadataForIdentifier:itemIdentifier
                                                                          withSyncDocument:document];
                                        }
                                    }
                                    else
                                    {
                                        AlfrescoLogError(@"Encountered an error while uploading item:%@. Reason:%@", itemMetadata.name, error.localizedDescription);
                                    }
                                    networkOperationCallbackComplete = YES;
                                } progressBlock:nil];
                            }
                            else if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                            {
                                // copy to local files as parent node was not found on server
                                [strongSelf saveToLocalFilesDocumentAtURL:[NSURL fileURLWithPath:itemMetadata.filePath]];
                                networkOperationCallbackComplete = YES;
                            }
                        }];
                    }
                    else
                    {
                        networkOperationCallbackComplete = YES;
                    }
                }
                else
                {
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

    });
}

- (NSURL *)localFilesURLForFilename:(NSString *)filename
{
    NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
    NSString *fullDestinationPath = [downloadContentPath stringByAppendingPathComponent:filename];
    NSURL *destinationURL = [NSURL fileURLWithPath:fullDestinationPath];
    return destinationURL;
}

- (void)saveToLocalFilesDocumentAtURL:(NSURL *)url
{
    NSError *error = nil;
    NSDictionary *resourceValues = [url resourceValuesForKeys:@[NSURLNameKey, NSURLCreationDateKey, NSURLContentModificationDateKey, NSURLTypeIdentifierKey, NSURLTotalFileSizeKey] error:&error];
    NSURL * destinationURL = [self localFilesURLForFilename:resourceValues[NSURLNameKey]];
    [self saveDocumentAtURL:url toURL:destinationURL overwritingExistingFile:NO];
}

- (NSError *)saveDocumentAtURL:(NSURL *)readingURL toURL:(NSURL *)writingURL overwritingExistingFile:(BOOL)shouldOverwrite
{
    NSError *copyError = nil;
    NSFileManager *fileManager = [NSFileManager defaultManager];
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
    return copyError;
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

#pragma mark - Handlers

- (void)handleUploadOfSyncDocument:(AlfrescoDocument *)document
                          fromFile:(AlfrescoContentFile *)contentFile
                          toFolder:(AlfrescoFolder *)folder
                        forAccount:(NSString *)accountIdentifier
        withItemMetadataIdentifier:(NSString *)metadataIdentifier
{
    [[RealmSyncCore sharedSyncCore] didUploadNode:document
                                         fromPath:contentFile.fileUrl.path
                                         toFolder:(AlfrescoFolder *)folder
                             forAccountIdentifier:accountIdentifier];
    
    [[AlfrescoFileManager sharedManager] removeItemAtURL:[contentFile.fileUrl URLByDeletingLastPathComponent]
                                                   error:nil];
    
    [[AFPDataManager sharedManager] removeItemMetadataForIdentifier:metadataIdentifier];
}

- (void)handleUploadOfNewSyncDocument:(AlfrescoDocument *)document
                         withMetadata:(AFPItemMetadata *)itemMetadata
                           forAccount:(NSString *)accountIdentifier
{
    [[AFPDataManager sharedManager] updateMetadataForIdentifier:itemMetadata.identifier
                                  withSyncDocument:document];
    
    NSString *parentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemMetadata.parentIdentifier];
    RLMRealm *realm = [[RealmSyncCore sharedSyncCore] realmWithIdentifier:accountIdentifier];
    RealmSyncNodeInfo *parentNode = [[AFPDataManager sharedManager] syncItemForId:parentIdentifier
                                                             forAccountIdentifier:accountIdentifier];
    RealmSyncNodeInfo *childNode = [[RealmSyncCore sharedSyncCore] syncNodeInfoForObject:document
                                                                    ifNotExistsCreateNew:YES
                                                                                 inRealm:realm];
    
    NSString *syncNameForNode = [[RealmSyncCore sharedSyncCore] syncNameForNode:document
                                                                        inRealm:realm];
    NSString *destinationPath = [[[RealmSyncCore sharedSyncCore] syncContentDirectoryPathForAccountWithId:accountIdentifier] stringByAppendingPathComponent:syncNameForNode];
    
    
    [realm transactionWithBlock:^{
        childNode.parentNode = parentNode;
        childNode.syncContentPath = syncNameForNode;
    } error:nil];
    
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *syncFileCopyError;
    
    [fileManager createDirectoryAtURL:[NSURL fileURLWithPath:[destinationPath stringByDeletingLastPathComponent]]
          withIntermediateDirectories:YES
                           attributes:nil
                                error:nil];
    
    [fileManager copyItemAtPath:itemMetadata.filePath
                         toPath:destinationPath
                          error:&syncFileCopyError];
    
    if (syncFileCopyError)
    {
        AlfrescoLogError(@"Encountered an error while copying new sync document to sync location. Reason: %@", syncFileCopyError.localizedDescription);
    }
}

@end
