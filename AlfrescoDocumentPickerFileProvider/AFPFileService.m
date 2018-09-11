/*******************************************************************************
 * Copyright (C) 2005-2018 Alfresco Software Limited.
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

@implementation AFPFileService

- (void)uploadDocumentItem:(AFPItemMetadata *)item
{
    NSString *itemIdentifier = item.identifier;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        
        @autoreleasepool{
            __block BOOL networkOperationCallbackComplete = NO;
            NSString *accountIdentifier = [AFPItemIdentifier getAccountIdentifierFromEnumeratedIdentifier:itemIdentifier];
            
            [[AFPAccountManager sharedManager] getSessionForAccountIdentifier:accountIdentifier networkIdentifier:nil withCompletionBlock:^(id<AlfrescoSession> session, NSError *loginError) {
                if(session)
                {
                    AFPItemMetadata *itemMetadata = (AFPItemMetadata *)[[AFPDataManager sharedManager] metadataItemForIdentifier:itemIdentifier];
                    if(itemMetadata.parentIdentifier.length)
                    {
                        NSString *parentIdentifier = [AFPItemIdentifier alfrescoIdentifierFromItemIdentifier:itemMetadata.parentIdentifier];
                        AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                        [docService retrieveNodeWithIdentifier:parentIdentifier completionBlock:^(AlfrescoNode *node, NSError *error) {
                            if(node)
                            {
                                AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:[NSURL fileURLWithPath:itemMetadata.filePath]];
                                [docService createDocumentWithName:itemMetadata.name inParentFolder:(AlfrescoFolder *)node contentFile:contentFile properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
                                    if(document)
                                    {
                                        AlfrescoFileProviderItemIdentifierType itemType = [AFPItemIdentifier itemIdentifierTypeForIdentifier:itemIdentifier];
                                        if(itemType == AlfrescoFileProviderItemIdentifierTypeSyncDocument)
                                        {
                                            [[RealmSyncCore sharedSyncCore] didUploadNode:document fromPath:contentFile.fileUrl.path toFolder:(AlfrescoFolder *)node forAccountIdentifier:accountIdentifier];
                                            [[AlfrescoFileManager sharedManager] removeItemAtURL:[contentFile.fileUrl URLByDeletingLastPathComponent] error:nil];
                                            [[AFPDataManager sharedManager] removeItemMetadataForIdentifier:item.identifier];
                                        } else if (itemType == AlfrescoFileProviderItemIdentifierTypeSyncNewDocument) {
                                            [[AFPDataManager sharedManager] updateMetadata:itemMetadata
                                                                          withSyncDocument:document];
                                        }
                                    }
                                    else
                                    {
                                        NSLog(@"==== this is error %@", error);
                                    }
                                    networkOperationCallbackComplete = YES;
                                } progressBlock:nil];
                            }
                            else if (error.code == kAlfrescoErrorCodeRequestedNodeNotFound)
                            {
                                // copy to local files as parent node was not found on server
                                [self saveToLocalFilesDocumentAtURL:[NSURL fileURLWithPath:itemMetadata.filePath]];
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

@end
