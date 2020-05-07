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
 
#import "FileFolderCell.h"

@implementation FileFolderCell

- (void)registerForNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(updateProgress:)
                                                 name:kDocumentPreviewManagerProgressNotification
                                               object:nil];
}

- (void)updateProgress:(NSNotification *)notification
{
    AlfrescoDocument *notificationDocument = notification.object;
    
    if ([self.node.identifier isEqualToString:notificationDocument.identifier])
    {
        unsigned long long bytesTransferred = [notification.userInfo[kDocumentPreviewManagerProgressBytesRecievedNotificationKey] unsignedLongLongValue];
        unsigned long long bytesTotal = [notification.userInfo[kDocumentPreviewManagerProgressBytesTotalNotificationKey] unsignedLongLongValue];
        
        if (bytesTotal != 0)
        {
            [self.progressBar setProgress:(float)bytesTransferred/(float)bytesTotal];
            
            if (self.progressBar.hidden)
            {
                self.progressBar.hidden = NO;
            }
        }
    }
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

@end
