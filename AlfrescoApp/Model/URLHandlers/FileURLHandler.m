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

static NSString * const kHandlerPrefix = @"file://";

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
        NSError *removalError = nil;
        NSString *filePath = [metadata.originalFileLocation stringByReplacingOccurrencesOfString:kHandlerPrefix withString:@""];
        [[AlfrescoFileManager sharedManager] removeItemAtPath:filePath error:&removalError];
        
        if (removalError)
        {
            AlfrescoLogError(@"Unable to delete file at path: %@", metadata.originalFileLocation);
        }
        
        // Copy the new file into the old location
        NSError *replaceError = nil;
        [[AlfrescoFileManager sharedManager] copyItemAtPath:url.path toPath:filePath error:&replaceError];
        
        if (replaceError)
        {
            AlfrescoLogError(@"Unable to copy file at path: %@ to path: %@", metadata.originalFileLocation, url.path);
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
        // Come from another app, not saveback ...
        // Save to downloads for the moment
        [[DownloadManager sharedManager] saveDocument:nil contentPath:url.path completionBlock:nil];
        handled = YES;
    }
    
    return handled;
}

@end
