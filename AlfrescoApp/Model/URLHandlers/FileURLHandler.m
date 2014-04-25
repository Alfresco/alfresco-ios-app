//
//  FileOpenURLProtocol.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "FileURLHandler.h"
#import "SaveBackMetadata.h"
#import "DownloadManager.h"
#import "Utility.h"
#import "SyncHelper.h"
#import "SyncManager.h"
#import "NavigationViewController.h"
#import "FileLocationSelectionViewController.h"
#import "UniversalDevice.h"
#import "MBProgressHUD.h"

static NSString * const kHandlerPrefix = @"file://";

@interface FileURLHandler () <FileLocationSelectionViewControllerDelegate>

@end

@implementation FileURLHandler

#pragma mark - URLHandlerProtocol

- (BOOL)canHandleURL:(NSURL *)url
{
    return [url.absoluteString hasPrefix:kHandlerPrefix];
}

- (BOOL)handleURL:(NSURL *)url sourceApplication:(NSString *)sourceApplication annotation:(id)annotation session:(id<AlfrescoSession>)session
{
    BOOL handled = NO;
    
    // Are we using Quickoffice SaveBack?
    if (annotation[kQuickofficeApplicationSecretUUIDKey])
    {
        NSDictionary *partnerApplicationInfo = annotation[kQuickofficeApplicationInfoKey];
        NSDictionary *metadataDictionary = partnerApplicationInfo[kAlfrescoInfoMetadataKey];
        SaveBackMetadata *metadata = [[SaveBackMetadata alloc] initWithDictionary:metadataDictionary];
        
        // Save the file to the original location
        // Delete the old file
        NSString *filePath = [metadata.originalFileLocation stringByReplacingOccurrencesOfString:kHandlerPrefix withString:@""];
        [self deleteItemAtPath:filePath];
        
        // Copy the new file into the old location
        NSError *replaceError = nil;
        [[AlfrescoFileManager sharedManager] moveItemAtPath:url.path toPath:filePath error:&replaceError];
        
        if (replaceError)
        {
            AlfrescoLogError(@"Unable to move file at path: %@ to path: %@", metadata.originalFileLocation, url.path);
        }
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSaveBackLocalComplete object:metadata.nodeRef userInfo:nil];
        
        AlfrescoDocument *syncedDocument = [[SyncHelper sharedHelper] syncDocumentFromDocumentIdentifier:metadata.nodeRef];
        
        if (metadata.documentLocation == InAppDocumentLocationSync || syncedDocument)
        {
            [[SyncManager sharedManager] retrySyncForDocument:syncedDocument];
        }
        else if (metadata.documentLocation == InAppDocumentLocationFilesAndFolders)
        {
            AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
            [documentService retrieveNodeWithIdentifier:metadata.nodeRef completionBlock:^(AlfrescoNode *node, NSError *error) {
                if (node)
                {
                    NSInputStream *inputStream = [[NSInputStream alloc] initWithFileAtPath:filePath];
                    [inputStream open];
                    
                    AlfrescoContentStream *stream = [[AlfrescoContentStream alloc] initWithStream:inputStream mimeType:[Utility mimeTypeForFileExtension:filePath.pathExtension]];
                    [documentService updateContentOfDocument:(AlfrescoDocument *)node contentStream:stream completionBlock:^(AlfrescoDocument *document, NSError *error) {
                        [inputStream close];
                        // If successful, display a message and let the observers know, else, save it to downloads to ensure no data is lost
                        if (!error)
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSaveBackRemoteComplete object:metadata.nodeRef userInfo:@{kAlfrescoDocumentUpdatedDocumentParameterKey : document}];
                            
                            NSString *title = NSLocalizedString(@"saveback.completed.title", @"SaveBack Completed Title");
                            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.completed.message", @"SaveBack Completed Message"), node.name];
                            displayInformationMessageWithTitle(message, title);
                        }
                        else
                        {
                            [[DownloadManager sharedManager] saveDocument:(AlfrescoDocument *)node contentPath:filePath completionBlock:nil];
                            NSString *title = NSLocalizedString(@"saveback.failed.title", @"SaveBack Failed Title");
                            NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.failed.message", @"SaveBack Failed Message"), node.name];
                            displayErrorMessageWithTitle(message, title);
                        }
                    } progressBlock:nil];
                }
            }];
        }
        handled = YES;
    }
    else
    {
        // User selection
        FileLocationSelectionViewController *locationSelectionViewController = [[FileLocationSelectionViewController alloc] initWithFilePath:url.path session:session delegate:self];
        NavigationViewController *locationNavigationController = [[NavigationViewController alloc] initWithRootViewController:locationSelectionViewController];
        [UniversalDevice displayModalViewController:locationNavigationController onController:[UniversalDevice containerViewController] withCompletionBlock:nil];
        
        handled = YES;
    }
    
    return handled;
}

#pragma mark - Private Functions

- (void)deleteItemAtPath:(NSString *)filePath
{
    NSError *deleteError = nil;
    [[AlfrescoFileManager sharedManager] removeItemAtPath:filePath error:&deleteError];
    
    if (deleteError)
    {
        AlfrescoLogError(@"Unable to delete file at path: %@", filePath);
    }
}

#pragma mark - FileLocationSelectionViewControllerDelegate Functions

- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController uploadToFolder:(AlfrescoFolder *)folder session:(id<AlfrescoSession>)session filePath:(NSString *)filePath
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
    
    MBProgressHUD *progressHUD = [[MBProgressHUD alloc] initWithView:selectionController.navigationController.view];
    [selectionController.navigationController.view addSubview:progressHUD];
    [progressHUD show:YES];
    [documentFolderService createDocumentWithName:fileName inParentFolder:folder contentStream:contentStream properties:nil completionBlock:^(AlfrescoDocument *document, NSError *error) {
        [progressHUD hide:YES];
        
        // success block
        void (^successBlock)(AlfrescoDocument *createdDocument, NSInputStream *creationInputStream) = ^(AlfrescoDocument *createdDocument, NSInputStream *creationInputStream) {
            [creationInputStream close];
            [self deleteItemAtPath:filePath];
            [selectionController dismissViewControllerAnimated:YES completion:^{
                NSString *title = NSLocalizedString(@"saveback.upload.completed.title", @"Upload Completed");
                NSString *message = [NSString stringWithFormat:NSLocalizedString(@"saveback.upload.completed.message", @"Upload Completed"), createdDocument.name, folder.name];
                displayInformationMessageWithTitle(message, title);
            }];
        };
        
        // failure block
        void (^failureBlock)(NSError *creationError, NSInputStream *creationInputStream) = ^(NSError *creationError, NSInputStream *creationInputStream) {
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
                    //
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
        //
    }];
}

- (void)fileLocationSelectionViewController:(FileLocationSelectionViewController *)selectionController saveFileAtPathToDownloads:(NSString *)filePath
{
    [selectionController dismissViewControllerAnimated:YES completion:^{
        [[DownloadManager sharedManager] saveDocument:nil contentPath:filePath completionBlock:^(NSString *downloadFilePath) {
            [self deleteItemAtPath:filePath];
        }];
    }];
}

@end
