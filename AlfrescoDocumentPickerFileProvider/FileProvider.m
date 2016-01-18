/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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
#import "KeychainUtils.h"
#import "UserAccountWrapper.h"
#import "AlfrescoFileManager+Extensions.h"
#import "NSFileManager+Extension.h"
#import "Utilities.h"

static NSString * const kAccountsListIdentifier = @"AccountListNew";

@interface FileProvider ()
@property (nonatomic, strong) PersistentQueueStore *queueStore;
@property (nonatomic, strong) NSMutableDictionary *accountIdentifierToSessionMappings;
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

- (NSMutableDictionary *)accountIdentifierToSessionMappings
{
    if (!_accountIdentifierToSessionMappings)
    {
        _accountIdentifierToSessionMappings = [NSMutableDictionary dictionary];
    }
    return _accountIdentifierToSessionMappings;
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
    
    NSURL *searchURL = [self.documentStorageURL URLByAppendingPathComponent:lastTwoPathString];
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"fileURL == %@", searchURL];
    NSArray *urlSearchResultArray = [self.queueStore.queue filteredArrayUsingPredicate:searchPredicate];
    
    returnMetadata = urlSearchResultArray.lastObject;
    
    return returnMetadata;
}

- (UserAccountWrapper *)userAccountForMetadataItem:(FileMetadata *)metadata
{
    NSError *keychainError = nil;
    NSArray *accounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
    
    if (keychainError)
    {
        AlfrescoLogError(@"Error retreiving accounts. Error: %@", keychainError.localizedDescription);
    }
    
    // Get the account for the file
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accountIdentifier == %@", metadata.accountIdentifier];
    NSArray *accountArray = [accounts filteredArrayUsingPredicate:predicate];
    UserAccount *keychainAccount = accountArray.firstObject;
    UserAccountWrapper *account = [[UserAccountWrapper alloc] initWithUserAccount:keychainAccount];
    
    return account;
}

- (void)loginToAccount:(id<AKUserAccount>)account completionBlock:(void (^)(BOOL successful, id<AlfrescoSession> session, NSError *loginError))completionBlock
{
    AKLoginService *loginService = [[AKLoginService alloc] init];
    [loginService loginToAccount:account networkIdentifier:nil completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *loginError) {
        if (successful)
        {
            self.accountIdentifierToSessionMappings[account.identifier] = session;
        }
        
        completionBlock(successful, session, loginError);
    }];
}

- (void)uploadDocument:(AlfrescoDocument *)document sourceURL:(NSURL *)fileURL session:(id<AlfrescoSession>)session completionBlock:(void (^)(AlfrescoDocument *document, NSError *updateError))completionBlock
{
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:fileURL];
    
    AlfrescoVersionService *versionService = [[AlfrescoVersionService alloc] initWithSession:session];
    [versionService checkoutDocument:document completionBlock:^(AlfrescoDocument *checkoutDocument, NSError *checkoutError) {
        if (checkoutError)
        {
            completionBlock(checkoutDocument, checkoutError);
        }
        else
        {
            [versionService checkinDocument:checkoutDocument asMajorVersion:NO contentFile:contentFile properties:nil comment:nil completionBlock:^(AlfrescoDocument *checkinDocument, NSError *checkinError) {
                completionBlock(checkinDocument, checkinError);
            } progressBlock:nil];
        }
    }];
}

#pragma mark - File Provider Methods

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler
{
    FileMetadata *fileMetadata = [self fileMetadataForURL:url];
    AlfrescoDocument *document = (AlfrescoDocument *)fileMetadata.repositoryNode;
    NSString *fileName = document.name;
    unsigned long long fileSize = document.contentLength;
    
    NSURL *placeholderURL = [NSFileProviderExtension placeholderURLForURL:[self.documentStorageURL URLByAppendingPathComponent:fileName]];
    
    NSError *placeholderWriteError = nil;
    [self.fileCoordinator coordinateWritingItemAtURL:placeholderURL options:0 error:&placeholderWriteError byAccessor:^(NSURL *newURL) {
        NSDictionary *metadata = @{NSURLNameKey : document.name, NSURLFileSizeKey : @(fileSize), NSURLContentModificationDateKey : document.modifiedAt};
        [NSFileProviderExtension writePlaceholderAtURL:placeholderURL withMetadata:metadata error:NULL];
    }];
    
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
        
        if (metadata.saveLocation == FileMetadataSaveLocationRepository)
        {
            UserAccountWrapper *account = [self userAccountForMetadataItem:metadata];
            [self loginToAccount:account completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *loginError) {
                if (successful)
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
            
            [self.fileCoordinator coordinateReadingItemAtURL:sourceURL options:NSFileCoordinatorReadingForUploading writingItemAtURL:url options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                NSError *copyError = nil;
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL error:&copyError];
                
                if (copyError)
                {
                    AlfrescoLogError(@"Unable to copy item from: %@, to: %@. Error: %@", newReadingURL, newWritingURL, copyError.localizedDescription);
                }
                
                completionHandler(copyError);
            }];
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
    AlfrescoDocument *repoNode = (AlfrescoDocument *)metadata.repositoryNode;
    
    if (![repoNode.modifiedAt isEqualToDate:urlModificationDate] && metadata.status != FileMetadataStatusUploading)
    {
        if (metadata.saveLocation == FileMetadataSaveLocationRepository)
        {
            UserAccountWrapper *account = [self userAccountForMetadataItem:metadata];
        
            // Coordinate the reading of the file for uploading
            [self.fileCoordinator coordinateReadingItemAtURL:metadata.fileURL options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL *newURL) {
                // define an upload block
                void (^uploadBlock)(id<AlfrescoSession>session) = ^(id<AlfrescoSession>session) {
                    AlfrescoDocument *updateDocument = (AlfrescoDocument *)metadata.repositoryNode;
                    [self uploadDocument:updateDocument sourceURL:newURL session:session completionBlock:^(AlfrescoDocument *document, NSError *updateError) {
                        if (updateError)
                        {
                            AlfrescoLogError(@"Error Updating Document: %@. Error: %@", updateDocument.name, updateError.localizedDescription);
                        }
                        else
                        {
                            AlfrescoLogInfo(@"Successfully updated document: %@, Modified At: %@, Created At: %@", document.name, document.modifiedAt, document.createdAt);
                            metadata.repositoryNode = document;
                        }
                        metadata.status = FileMetadataStatusPendingUpload;
                        [self.queueStore saveQueue];
                    }];
                    
                    // Set the metadata to uploading - ensure the upload doesnt start again.
                    metadata.status = FileMetadataStatusUploading;
                    [self.queueStore saveQueue];
                };
                
                // Session exists, use that, else do a login and then upload.
                id<AlfrescoSession> cachedSession = self.accountIdentifierToSessionMappings[account.identifier];
                if (!cachedSession)
                {
                    __block BOOL loginCallbackComplete = NO;
                    
                    [self loginToAccount:account completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *loginError) {
                        if (successful)
                        {
                            uploadBlock(session);
                        }
                        else
                        {
                            AlfrescoLogError(@"Error Logging In: %@", loginError.localizedDescription);
                        }
                        
                        loginCallbackComplete = YES;
                    }];
                    
                    /*
                     * Keep this object around long enough for the login attempt to complete.
                     * Running as a background thread, seperate from the UI, so should not cause
                     * Any issues when blocking the thread.
                     */
                    do
                    {
                        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
                    }
                    while (loginCallbackComplete == NO);
                }
                else
                {
                    uploadBlock(cachedSession);
                }
            }];

        }
        else if (metadata.saveLocation == FileMetadataSaveLocationLocalFiles)
        {
            NSString *downloadContentPath = [[AlfrescoFileManager sharedManager] downloadsContentFolderPath];
            NSString *fullDestinationPath = [downloadContentPath stringByAppendingPathComponent:url.lastPathComponent];
            NSURL *destinationURL = [NSURL fileURLWithPath:fullDestinationPath];
            [self.fileCoordinator coordinateReadingItemAtURL:url options:NSFileCoordinatorReadingForUploading writingItemAtURL:destinationURL options:NSFileCoordinatorWritingForReplacing error:nil byAccessor:^(NSURL *newReadingURL, NSURL *newWritingURL) {
                NSError *copyError = nil;
                NSFileManager *fileManager = [[NSFileManager alloc] init];
                
                [fileManager copyItemAtURL:newReadingURL toURL:newWritingURL overwritingExistingFile:YES error:&copyError];
                
                if (copyError)
                {
                    AlfrescoLogError(@"Unable to copy file at path: %@, to location: %@. Error: %@", newReadingURL, newWritingURL, copyError.localizedDescription);
                }
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

@end
