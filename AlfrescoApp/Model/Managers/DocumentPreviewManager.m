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
 
#import "DocumentPreviewManager.h"

static NSString * const kTempFileFolderNamePath = @"tmp";

@interface DocumentPreviewManager ()

@property (nonatomic, strong) NSString *tmpDownloadFolderPath;
@property (nonatomic, strong) NSString *downloadFolderPath;
@property (nonatomic, strong) NSMutableArray *downloadDocumentIdentifiers;

@end

@implementation DocumentPreviewManager

+ (DocumentPreviewManager *)sharedManager
{
    static dispatch_once_t predicate = 0;
    static DocumentPreviewManager *sharedManager = nil;
    dispatch_once(&predicate, ^{
        sharedManager = [[self alloc] init];
    });
    return sharedManager;
}

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        [self setupTempDownloadFolder];
        [self setupDownloadFolder];
        self.downloadDocumentIdentifiers = [NSMutableArray array];
    }
    return self;
}

- (BOOL)isCurrentlyDownloadingDocument:(AlfrescoDocument *)document
{
    NSString *documentIdentifier = [self documentIdentifierForDocument:document];
    return [self.downloadDocumentIdentifiers containsObject:documentIdentifier];
}

- (BOOL)hasLocalContentOfDocument:(AlfrescoDocument *)document
{
    NSString *fileLocation = [self filePathForDocument:document];
    BOOL hasContentLocally = [[AlfrescoFileManager sharedManager] fileExistsAtPath:fileLocation];
    return hasContentLocally;
}

- (NSString *)filePathForDocument:(AlfrescoDocument *)document
{
    return [self.downloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
}

- (NSString *)documentIdentifierForDocument:(AlfrescoDocument *)document
{
    return [[self filePathForDocument:document] lastPathComponent];
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session
{
    AlfrescoRequest *request = nil;
    NSString *documentIdentifier = [self documentIdentifierForDocument:document];
    
    if ([self hasLocalContentOfDocument:document])
    {
        AlfrescoLogInfo(@"Document is already cached locally at path");
        
        [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerDocumentDownloadCompletedNotification
                                                            object:document
                                                          userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
    }
    else
    {
        if (![self.downloadDocumentIdentifiers containsObject:documentIdentifier])
        {
            [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerWillStartDownloadNotification
                                                                object:document
                                                              userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
            
            NSString *downloadLocation = [self.downloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
            
            request = [self downloadDocument:document toPath:downloadLocation session:session completionBlock:^(NSString *filePath) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerDocumentDownloadCompletedNotification
                                                                    object:document
                                                                  userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerProgressNotification
                                                                    object:document
                                                                  userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier,
                                                                             kDocumentPreviewManagerProgressBytesRecievedNotificationKey : @(bytesTransferred),
                                                                             kDocumentPreviewManagerProgressBytesTotalNotificationKey : @(bytesTotal)}];
            }];
        }
    }
    
    return request;
}

#pragma mark - Private Functions

- (void)setupTempDownloadFolder
{
    AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
    self.tmpDownloadFolderPath = [[fileManager documentPreviewDocumentFolderPath] stringByAppendingPathComponent:kTempFileFolderNamePath];
    if (![fileManager fileExistsAtPath:self.tmpDownloadFolderPath])
    {
        NSError *creationError = nil;
        [fileManager createDirectoryAtPath:self.tmpDownloadFolderPath withIntermediateDirectories:YES attributes:nil error:&creationError];
        
        if (creationError)
        {
            AlfrescoLogError(@"Error creating document preview temp folder");
        }
    }
}

- (void)setupDownloadFolder
{
    self.downloadFolderPath = [[AlfrescoFileManager sharedManager] documentPreviewDocumentFolderPath];
}

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document toPath:(NSString *)downloadPath session:(id<AlfrescoSession>)session completionBlock:(DocumentPreviewManagerFileSavedBlock)completionBlock progressBlock:(AlfrescoProgressBlock)progressBlock
{
    if (!document)
    {
        AlfrescoLogError(@"Download operation attempted with nil AlfrescoDocument object");
        return nil;
    }
    
    // MOBILE-3310 & MOBILE-3311
    // If the temporary path has been deleted (clearing all data in the app), we need to recreate the destination folders.
    [self setupDownloadFolder];
    [self setupTempDownloadFolder];
    
    NSString *temporaryDownloadLocation = [self.tmpDownloadFolderPath stringByAppendingPathComponent:filenameAppendedWithDateModified(document.name, document)];
    
    AlfrescoRequest *request = nil;
    if (completionBlock != NULL)
    {
        if ([[AlfrescoFileManager sharedManager] fileExistsAtPath:downloadPath])
        {
            progressBlock(1, 1);
            completionBlock(downloadPath);
        }
        else
        {
            NSString *documentIdentifier = downloadPath.lastPathComponent;
            
            if (![self.downloadDocumentIdentifiers containsObject:documentIdentifier])
            {
                [self.downloadDocumentIdentifiers addObject:documentIdentifier];
                NSOutputStream *outputStream = [[AlfrescoFileManager sharedManager] outputStreamToFileAtPath:temporaryDownloadLocation append:NO];
                AlfrescoDocumentFolderService *documentService = [[AlfrescoDocumentFolderService alloc] initWithSession:session];
                
                __weak typeof(self) weakSelf = self;
                request = [documentService retrieveContentOfDocument:document outputStream:outputStream completionBlock:^(BOOL succeeded, NSError *error) {
                    [weakSelf.downloadDocumentIdentifiers removeObject:documentIdentifier];
                    if (succeeded)
                    {
                        // move out of temp location
                        AlfrescoFileManager *fileManager = [AlfrescoFileManager sharedManager];
                        
                        NSError *movingError = nil;
                        [fileManager moveItemAtPath:temporaryDownloadLocation toPath:downloadPath error:&movingError];
                        
                        if (movingError)
                        {
                            AlfrescoLogError(@"Unable to move from path %@ to %@", temporaryDownloadLocation, downloadPath);
                        }
                        
                        completionBlock(downloadPath);
                    }
                    else
                    {
                        [[AlfrescoFileManager sharedManager] removeItemAtPath:downloadPath error:nil];
                        [Notifier notifyWithAlfrescoError:error];
                        
                        if (error.code == kAlfrescoErrorCodeNetworkRequestCancelled)
                        {
                            [[NSNotificationCenter defaultCenter] postNotificationName:kDocumentPreviewManagerDocumentDownloadCancelledNotification
                                                                                object:document
                                                                              userInfo:@{kDocumentPreviewManagerDocumentIdentifierNotificationKey : documentIdentifier}];
                        }
                    }
                } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                    progressBlock(bytesTransferred, bytesTotal);
                }];
            }
        }
    }
    return request;
}

@end
