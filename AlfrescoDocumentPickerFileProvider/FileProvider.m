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
    
    NSArray *queuedObjects = self.queueStore.queue;
    NSPredicate *searchPredicate = [NSPredicate predicateWithFormat:@"fileURL == %@", fileURL];
    NSArray *urlSearchResultArray = [queuedObjects filteredArrayUsingPredicate:searchPredicate];
    
    returnMetadata = urlSearchResultArray.firstObject;
    
    return returnMetadata;
}

- (void)loginToAccount:(id<AKUserAccount>)account completionBlock:(void (^)(BOOL successful, id<AlfrescoSession> session, NSError *loginError))completionBlock
{
    // Login to account
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
    // Retreive the cached document
    AlfrescoContentFile *contentFile = [[AlfrescoContentFile alloc] initWithUrl:fileURL];
    
    // Initiate the upload
    AlfrescoDocumentFolderService *docService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
    [docService updateContentOfDocument:document contentFile:contentFile completionBlock:completionBlock progressBlock:nil];
}

#pragma mark - File Provider Methods

- (void)providePlaceholderAtURL:(NSURL *)url completionHandler:(void (^)(NSError *error))completionHandler
{
    FileMetadata *fileMetadata = [self fileMetadataForURL:url];
    AlfrescoDocument *document = (AlfrescoDocument *)fileMetadata.repositoryNode;
    
    // Should call + writePlaceholderAtURL:withMetadata:error: with the placeholder URL, then call the completion handler with the error if applicable.
    NSString *fileName = document.name;
    NSURL *placeholderURL = [NSFileProviderExtension placeholderURLForURL:[self.documentStorageURL URLByAppendingPathComponent:fileName]];
    
    // Get file size for file at from model
    unsigned long long fileSize = document.contentLength;
    
    NSError *placeholderWriteError = nil;
    [self.fileCoordinator coordinateWritingItemAtURL:placeholderURL options:0 error:&placeholderWriteError byAccessor:^(NSURL *newURL) {
        NSDictionary *metadata = @{NSURLNameKey : document.name ,NSURLFileSizeKey : @(fileSize)};
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
        NSError *noFilePresent = [NSError errorWithDomain:@"File doesn't Exist" code:-1 userInfo:nil];
        completionHandler(noFilePresent);
    }
}

/*
 * Called at some point after the file has changed; the provider may then trigger an upload
 */
- (void)itemChangedAtURL:(NSURL *)url
{
    // Mark file at <url> as needing an update in the model; kick off update process.
    NSLog(@"Item changed at URL %@", url);
    
    // Read Accounts from the keychain
    NSError *keychainError = nil;
    NSArray *accounts = [KeychainUtils savedAccountsForListIdentifier:kAccountsListIdentifier error:&keychainError];
    
    if (keychainError)
    {
        AlfrescoLogError(@"Error retreiving accounts. Error: %@", keychainError.localizedDescription);
    }
    
    // Get all metadata objects that can be uploaded
    NSArray *queuedObjects = self.queueStore.queue;
    NSPredicate *uploadPendingPredicate = [NSPredicate predicateWithFormat:@"status == %d", FileMetadataStatusPendingUpload];
    NSArray *queuedForUpload = [queuedObjects filteredArrayUsingPredicate:uploadPendingPredicate];
    
    // For each metadata item, initiate an upload
    for (FileMetadata *metadata in queuedForUpload)
    {
        // Get the account for the file
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"accountIdentifier == %@", metadata.accountIdentifier];
        NSArray *accountArray = [accounts filteredArrayUsingPredicate:predicate];
        UserAccount *keychainAccount = accountArray.firstObject;
        UserAccountWrapper *account = [[UserAccountWrapper alloc] initWithUserAccount:keychainAccount];
        
        // Coordinate the reading of the file for uploading
        [self.fileCoordinator coordinateReadingItemAtURL:metadata.fileURL options:NSFileCoordinatorReadingForUploading error:nil byAccessor:^(NSURL *newURL) {
            // define an upload block
            void (^uploadBlock)(id<AlfrescoSession>session) = ^(id<AlfrescoSession>session) {
                // Retreive the cached document
                AlfrescoDocument *updateDocument = (AlfrescoDocument *)metadata.repositoryNode;
                [self uploadDocument:updateDocument sourceURL:newURL session:session completionBlock:^(AlfrescoDocument *document, NSError *updateError) {
                    if (updateError)
                    {
                        AlfrescoLogError(@"Error updating: %@", updateError.localizedDescription);
                    }
                    else
                    {
                        //
                        AlfrescoLogInfo(@"SUCCESSFUL UPDATE: %@, %@, %@", document.name, document.modifiedAt, document.createdAt);
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
                // Callback for number of login attempts made
                __block int loginAttemptsMade = 0;
                
                // Login to account
                [self loginToAccount:account completionBlock:^(BOOL successful, id<AlfrescoSession> session, NSError *loginError) {
                    if (successful)
                    {
                        uploadBlock(session);
                    }
                    else
                    {
                        AlfrescoLogError(@"Error Logging In: %@", loginError.localizedDescription);
                    }
                    loginAttemptsMade++;
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
                while (loginAttemptsMade != queuedForUpload.count);
            }
            else
            {
                uploadBlock(cachedSession);
            }
        }];
    }
}

/*
 * Called after the last claim to the file has been released. At this point, it is safe for the file provider to remove the content file.
 * Care should be taken that the corresponding placeholder file stays behind after the content file has been deleted.
 */
- (void)stopProvidingItemAtURL:(NSURL *)url
{
    FileMetadata *completedMetadata = [self fileMetadataForURL:url];
    [self.queueStore removeObjectFromQueue:completedMetadata];
    [self.queueStore saveQueue];
    
    [self.fileCoordinator coordinateWritingItemAtURL:url options:NSFileCoordinatorWritingForDeleting error:NULL byAccessor:^(NSURL *newURL) {
        [[NSFileManager defaultManager] removeItemAtURL:newURL error:NULL];
    }];
    [self providePlaceholderAtURL:url completionHandler:NULL];
}

@end
