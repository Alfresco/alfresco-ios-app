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

#import "ThumbnailOperation.h"

@interface ThumbnailOperation ()
@property (nonatomic, strong) AlfrescoDocumentFolderService *documentFolderService;
@property (nonatomic, strong) AlfrescoDocument *document;
@property (nonatomic, strong) NSString *rendition;
@property (nonatomic, copy) AlfrescoContentFileCompletionBlock contentFileCompletionBlock;
@property (nonatomic, strong) AlfrescoRequest *renditionRequest;
@property (nonatomic, assign) BOOL stopRunLoop;
@end

@implementation ThumbnailOperation

- (id)initWithDocumentFolderService:(AlfrescoDocumentFolderService *)service document:(AlfrescoDocument *)document renditionName:(NSString *)rendition completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    self = [super init];
    if (self)
    {
        self.documentFolderService = service;
        self.document = document;
        self.rendition = rendition;
        self.contentFileCompletionBlock = completionBlock;
        self.minimumDelayBetweenRequests = 0;
    }
    return self;
}

- (void)rateLimitMonitor:(NSTimer *)timer
{
    [timer invalidate];
    [self initiateRenditionRequest];
}

- (void)initiateRenditionRequest
{
    __weak typeof(self) weakSelf = self;
    self.renditionRequest = [self.documentFolderService retrieveRenditionOfNode:self.document renditionName:self.rendition completionBlock:^(AlfrescoContentFile *contentFile, NSError *error) {
        __strong typeof(self) strongSelf = weakSelf;
        
        if (strongSelf.contentFileCompletionBlock)
        {
            dispatch_async(dispatch_get_main_queue(), ^{
                strongSelf.contentFileCompletionBlock(contentFile, error);
            });
        }
        strongSelf.stopRunLoop = YES;
    }];
}

- (void)main
{
    if (self.minimumDelayBetweenRequests > 0)
    {
        // Used for cloud accounts: rate-limits the rendition requests
        NSTimer *myTimer = [NSTimer timerWithTimeInterval:self.minimumDelayBetweenRequests target:self selector:@selector(rateLimitMonitor:) userInfo:nil repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:myTimer forMode:NSDefaultRunLoopMode];
    }
    else
    {
        [self initiateRenditionRequest];
    }
    
    while (!self.isCancelled && !_stopRunLoop)
    {
        [[NSRunLoop currentRunLoop] runMode:NSDefaultRunLoopMode beforeDate:[NSDate distantFuture]];
        if (self.isCancelled)
        {
            [self.renditionRequest cancel];
        }
    }
}

@end
