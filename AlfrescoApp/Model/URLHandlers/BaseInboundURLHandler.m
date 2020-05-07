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
 
#import "BaseInboundURLHandler.h"
#import "DownloadManager.h"
#import "AccountManager.h"
#import "RealmSyncManager.h"

@interface BaseInboundURLHandler () <NSFileManagerDelegate>
@end

@implementation BaseInboundURLHandler

#pragma mark - Abstract URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    [self doesNotRecognizeSelector:_cmd];
    return NO;
}

#pragma mark - Public Functions

- (BOOL)handleInboundFileURL:(NSURL *)url savebackMetadata:(SaveBackMetadata *)metadata session:(id<AlfrescoSession>)session
{
    if ([metadata isValid])
    {
        // Save the file to the original location
        NSString *originalFilePath = metadata.originalFileLocation;
        
        // Create a copy of the document with the correct extension to work with temporarily
        NSString *fileNameWithCorrectExtension = [url.path lastPathComponent];
        if (url.pathExtension && originalFilePath.pathExtension)
        {
            fileNameWithCorrectExtension = [[url.path stringByReplacingOccurrencesOfString:url.pathExtension withString:originalFilePath.pathExtension] lastPathComponent];
        }
        else
        {
            NSString *nilValue = (url.pathExtension == nil) ? @"URL Path Extension" : @"Original Path Extension";
            AlfrescoLogError(@"File name may be incorrect as the \"%@\" was nil", nilValue);
        }
        
        NSString *temporaryFilePath = [[[AlfrescoFileManager sharedManager] temporaryDirectory] stringByAppendingPathComponent:fileNameWithCorrectExtension];
        [self overwriteItemAtPath:temporaryFilePath withItemAtPath:url.path];
        
        RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
        AlfrescoDocument *syncedDocument = (AlfrescoDocument *)[AlfrescoNode alfrescoNodeForIdentifier:metadata.nodeRef inRealm:realm];
        
        if (syncedDocument)
        {
            NSString *syncDocumentIdentifier = syncedDocument.identifier;
            [self overwriteItemAtPath:originalFilePath withItemAtPath:temporaryFilePath];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSaveBackLocalComplete object:metadata.nodeRef userInfo:nil];
            
            [[RealmSyncManager sharedManager] retrySyncForDocument:syncedDocument completionBlock:^{
                RLMRealm *realm = [[RealmManager sharedManager] realmForCurrentThread];
                AlfrescoDocument *editedDocument = (AlfrescoDocument *)[AlfrescoNode alfrescoNodeForIdentifier:syncDocumentIdentifier inRealm:realm];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentEditedNotification object:editedDocument];
            }];
        }
        else if (metadata.documentLocation == InAppDocumentLocationFilesAndFolders)
        {
            // dispatch it asynchronously to ensure reachability callbacks can be updated on the main thread
            dispatch_async(dispatch_get_main_queue(), ^{
                AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                [documentService retrieveNodeWithIdentifier:metadata.nodeRef completionBlock:^(AlfrescoNode *node, NSError *identifierError) {
                    if (identifierError)
                    {
                        [[DownloadManager sharedManager] saveDocument:(AlfrescoDocument *)node contentPath:temporaryFilePath completionBlock:^(NSString *filePath) {
                            // Do some cleaning up
                            [self removeFileAtPath:temporaryFilePath];
                        }];
                        NSString *title = NSLocalizedString(@"saveback.failed.title", @"SaveBack Failed Title");
                        NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.failed.message", @"SaveBack Failed Message"), node.name];
                        
                        if (identifierError.code == kAlfrescoErrorCodeNoNetworkConnection)
                        {
                            title = NSLocalizedString(@"error.no.internet.access.title", @"No Internet Title");
                            message = NSLocalizedString(@"error.no.internet.access.message", @"No Internet Message");
                        }
                        
                        displayErrorMessageWithTitle(message, title);
                    }
                    else
                    {
                        NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:temporaryFilePath];
                        [inputStream open];
                        
                        AlfrescoContentStream *stream = [[AlfrescoContentStream alloc] initWithStream:inputStream mimeType:[Utility mimeTypeForFileExtension:temporaryFilePath.pathExtension]];
                        [documentService updateContentOfDocument:(AlfrescoDocument *)node contentStream:stream completionBlock:^(AlfrescoDocument *document, NSError *error) {
                            [inputStream close];
                            // If successful, display a message and let the observers know, else, save it to downloads to ensure no data is lost
                            if (!error)
                            {
                                [self overwriteItemAtPath:originalFilePath withItemAtPath:temporaryFilePath];
                                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSaveBackLocalComplete object:metadata.nodeRef userInfo:nil];
                                
                                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSaveBackRemoteComplete object:metadata.nodeRef userInfo:@{kAlfrescoDocumentUpdatedFromDocumentParameterKey : document}];
                                
                                NSString *title = NSLocalizedString(@"saveback.completed.title", @"SaveBack Completed Title");
                                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.completed.message", @"SaveBack Completed Message"), node.name];
                                displayInformationMessageWithTitle(message, title);
                            }
                            else
                            {
                                [[DownloadManager sharedManager] saveDocument:(AlfrescoDocument *)node contentPath:temporaryFilePath completionBlock:^(NSString *filePath) {
                                    // Do some cleaning up
                                    [self removeFileAtPath:temporaryFilePath];
                                }];
                                NSString *title = NSLocalizedString(@"saveback.failed.title", @"SaveBack Failed Title");
                                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.failed.message", @"SaveBack Failed Message"), node.name];
                                displayErrorMessageWithTitle(message, title);
                            }
                        } progressBlock:nil];
                    }
                }];
            });
        }
    }
    else
    {
        // MOBILE-2992: without the nodeRef in the metadata there's not a lot we can do so just show an error message
        // TODO: Use a more informative error message i.e. save back failed due to insufficient information being provided
        NSString *title = NSLocalizedString(@"saveback.failed.title", @"SaveBack Failed Title");
        displayErrorMessageWithTitle(title, title);
    }
    
    return YES;
}

#pragma mark - FileLocationSelectionViewControllerDelegate Functions

- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController uploadToFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session filePath:(NSString *)filePath
{
    if (folder && session && filePath)
    {
        AlfrescoDocumentFolderService *documentFolderService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
        
        NSInputStream *inputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
        [inputStream open];
        
        // mimetype
        NSString *mimeType = [Utility mimeTypeForFileExtension:filePath.pathExtension];
        
        // Get the file size
        // It appears that the content size is required by CMIS when creating the content, but not when updating existing content
        NSError *attributeError = nil;
        NSDictionary *fileAttributes = [[AlfrescoFileManager sharedManager] attributesOfItemAtPath:filePath error:&attributeError];
        
        if (attributeError)
        {
            AlfrescoLogError(@"Unable to get the attributes for the item at path: %@", filePath);
        }
        
        unsigned long long fileLength = [(NSNumber *)fileAttributes[kAlfrescoFileSize] unsignedLongLongValue];
        AlfrescoContentStream *contentStream = [[AlfrescoContentStream alloc] initWithStream:inputStream mimeType:mimeType length:fileLength];
        NSString *fileName = [filePath.lastPathComponent stringByRemovingPercentEncoding];
        if (!fileName)
        {
            // MOBILE-2995: generate a fileName if necessary
            fileName = [NSString stringWithFormat:@"%@.%@", [[NSUUID UUID] UUIDString], [Utility fileExtensionFromMimeType:mimeType]];
        }
        MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:selectionController.navigationController.view];
        progressHUD.mode = MBProgressHUDModeDeterminate;
        
        [selectionController.navigationController.view addSubview:progressHUD];
        [progressHUD showAnimated:YES];
        
        [documentFolderService createDocumentWithName:fileName inParentFolder:folder contentStream:contentStream properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
            // success block
            void (^successBlock)(AlfrescoDocument *createdDocument, NSInputStream *creationInputStream) = ^(AlfrescoDocument *createdDocument, NSInputStream *creationInputStream) {
                [progressHUD hideAnimated:YES];
                [creationInputStream close];
                
                [[RealmSyncManager sharedManager] didUploadNode:createdDocument fromPath:filePath toFolder:folder];
                [[AlfrescoFileManager sharedManager] removeItemAtPath:filePath error:nil];

                [selectionController dismissViewControllerAnimated:YES completion:^{
                    NSString *title = NSLocalizedString(@"saveback.upload.completed.title", @"Upload Completed");
                    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.upload.completed.message", @"Upload Completed"), createdDocument.name, folder.name];
                    displayInformationMessageWithTitle(message, title);
                }];
            };
            
            // failure block
            void (^failureBlock)(NSError *creationError, NSInputStream *creationInputStream) = ^(NSError *creationError, NSInputStream *creationInputStream) {
                [progressHUD hideAnimated:YES];
                [creationInputStream close];
                NSString *title = NSLocalizedString(@"saveback.upload.failed.title", @"Upload Failed");
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.upload.failed.message", @"Upload Failed"), filePath.lastPathComponent, folder.name];
                displayErrorMessageWithTitle(message, title);
            };
            
            if (error)
            {
                // content already exists, then append the current time to it and try again.
                if (error.code == kAlfrescoErrorCodeDocumentFolderNodeAlreadyExists)
                {
                    NSString *updatedFileName = fileNameAppendedWithDate(fileName);
                    NSInputStream *retryInputStream = [NSInputStream inputStreamWithFileAtPath:filePath];
                    [retryInputStream open];
                    AlfrescoContentStream *retryContentStream = [[AlfrescoContentStream alloc] initWithStream:retryInputStream mimeType:mimeType length:fileLength];
                    
                    [documentFolderService createDocumentWithName:updatedFileName inParentFolder:folder contentStream:retryContentStream properties:nil completionBlock:^(AlfrescoDocument *renamedDocument, NSError *renamedError) {
                        if (renamedError)
                        {
                            failureBlock(renamedError, retryInputStream);
                        }
                        else
                        {
                            successBlock(renamedDocument, retryInputStream);
                        }
                    } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                        // Update progress HUD
                        progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
                    }];
                }
                else
                {
                    failureBlock(error, inputStream);
                }
            }
            else
            {
                successBlock(document, inputStream);
            }
        } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
            // Update progress HUD
            progressHUD.progress = (bytesTotal != 0) ? (float)bytesTransferred / (float)bytesTotal : 0;
        }];
    }
    else
    {
        // MOBILE-2995: ensure we have all the information we need to attempt save back
        // TODO: Use a more informative error message i.e. save back failed due to insufficient information being provided
        NSString *title = NSLocalizedString(@"saveback.failed.title", @"SaveBack Failed Title");
        displayErrorMessageWithTitle(title, title);
    }
}

- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController saveFileAtPathToDownloads:(NSString *)filePath
{
    [selectionController dismissViewControllerAnimated:YES completion:^{
        [[DownloadManager sharedManager] saveDocument:nil contentPath:filePath completionBlock:^(NSString *downloadFilePath) {
            [[AlfrescoFileManager sharedManager] removeItemAtPath:filePath error:nil];
        }];
    }];
}

#pragma mark - Private Functions

- (BOOL)overwriteItemAtPath:(NSString *)targetPath withItemAtPath:(NSString *)sourcePath
{
    // Copy the new file into the old location
    NSError *error = nil;
    NSFileManager *fileManager = [[NSFileManager alloc] init];
    fileManager.delegate = self;
    [fileManager moveItemAtPath:sourcePath toPath:targetPath error:&error];
    
    if (error)
    {
        AlfrescoLogError(@"Unable to overwrite file at path: %@ with file at path: %@", targetPath, sourcePath);
        return NO;
    }
    return YES;
}

- (void)removeFileAtPath:(NSString *)filePath
{
    NSError *removalError = nil;
    [[AlfrescoFileManager sharedManager] removeItemAtPath:filePath error:&removalError];
    
    if (removalError)
    {
        AlfrescoLogDebug(@"Unable to remove item at path: %@", filePath);
    }
}

#pragma mark - NSFileManagerDelegate methods

- (BOOL)fileManager:(NSFileManager *)fileManager shouldProceedAfterError:(NSError *)error movingItemAtPath:(NSString *)srcPath toPath:(NSString *)dstPath
{
    return (error.code == NSFileWriteFileExistsError);
}

@end
