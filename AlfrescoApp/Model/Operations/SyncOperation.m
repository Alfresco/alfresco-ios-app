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
 
#import "SyncOperation.h"

@interface SyncOperation ()
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoRequest *syncRequest;
@property (nonatomic, strong) NSStream *stream;
@property (nonatomic, strong) AlfrescoBOOLCompletionBlock downloadCompletionBlock;
@property (nonatomic, strong) AlfrescoDocumentCompletionBlock uploadCompletionBlock;
@property (nonatomic, strong) AlfrescoProgressBlock progressBlock;
@property (nonatomic, assign) BOOL isDownload;
@property (nonatomic, strong) NSThread *operationThread;
@end

@implementation SyncOperation

- (id)initWithDocumentFolderService:(id)documentFolderService
                   downloadDocument:(AlfrescoDocument *)document
                       outputStream:outputStream
            downloadCompletionBlock:(AlfrescoBOOLCompletionBlock)downloadCompletionBlock
                      progressBlock:(AlfrescoProgressBlock)progressBlock
{
    self = [super init];
    
    if (self)
    {
        self.documentFolderService = documentFolderService;
        self.document = document;
        self.stream = outputStream;
        self.downloadCompletionBlock = downloadCompletionBlock;
        self.progressBlock = progressBlock;
        self.isDownload = YES;
    }
    return self;
}

- (id)initWithDocumentFolderService:(id)documentFolderService
                     uploadDocument:(AlfrescoDocument *)document
                        inputStream:inputStream
              uploadCompletionBlock:(AlfrescoDocumentCompletionBlock)uploadCompletionBlock
                      progressBlock:(AlfrescoProgressBlock)progressBlock
{
    self = [super init];
    
    if (self)
    {
        self.documentFolderService = documentFolderService;
        self.document = document;
        self.stream = inputStream;
        self.uploadCompletionBlock = uploadCompletionBlock;
        self.progressBlock = progressBlock;
        self.isDownload = NO;
    }
    return self;
}

- (void)main
{
    @autoreleasepool
    {
        if (self.isCancelled)
        {
            return;
        }
        
        self.operationThread = [NSThread currentThread];
        
        __block BOOL operationCompleted = NO;
        __weak SyncOperation *weakSelf = self;
        
        if (self.isDownload)
        {
            self.syncRequest = [self.documentFolderService retrieveContentOfDocument:self.document outputStream:(NSOutputStream *)self.stream completionBlock:^(BOOL succeeded, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.downloadCompletionBlock)
                    {
                        weakSelf.downloadCompletionBlock(succeeded, error);
                    }
                });
                operationCompleted = YES;
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.progressBlock)
                    {
                        weakSelf.progressBlock(bytesTransferred, bytesTotal);
                    }
                });
            }];
        }
        else
        {
            self.syncRequest = [self.documentFolderService updateContentOfDocument:self.document contentStream:(AlfrescoContentStream *)self.stream completionBlock:^(AlfrescoDocument *uploadedDocument, NSError *error) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.uploadCompletionBlock)
                    {
                        weakSelf.uploadCompletionBlock(uploadedDocument, error);
                    }
                });
                operationCompleted = YES;
            } progressBlock:^(unsigned long long bytesTransferred, unsigned long long bytesTotal) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (weakSelf.progressBlock)
                    {
                        weakSelf.progressBlock(bytesTransferred, bytesTotal);
                    }
                });
            }];
        }

        while (!self.isCancelled && !operationCompleted)
        {
            [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
            if (self.isCancelled)
            {
                [self.syncRequest cancel];
            }
        }
    }
}

- (void)wakeUpThread
{
    // No-op
}

- (void)cancelOperation
{
    if(self.syncRequest)
    {
        [self.syncRequest cancel];
    }
    else if(self.isDownload)
    {
        if(self.downloadCompletionBlock)
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
            self.downloadCompletionBlock(NO, error);
        }
    }
    else
    {
        if(self.uploadCompletionBlock)
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
            self.uploadCompletionBlock(nil, error);
        }
    }
    [self cancel];
    [self performSelector:@selector(wakeUpThread) onThread:self.operationThread withObject:nil waitUntilDone:NO];
}

- (void)dealloc
{
    _documentFolderService = nil;
    _document = nil;
    _syncRequest = nil;
    _stream = nil;
    _downloadCompletionBlock = nil;
    _uploadCompletionBlock = nil;
    _progressBlock = nil;
}

@end
