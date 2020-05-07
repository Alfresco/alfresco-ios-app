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
 
#import "Notifier.h"

@implementation Notifier

+ (void)notifyWithAlfrescoError:(NSError *)alfrescoError
{
    if (alfrescoError)
    {
        NSInteger errorCode = [alfrescoError code];
        
        switch (errorCode)
        {
            case kAlfrescoErrorCodeUnauthorisedAccess:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccessDeniedNotification object:alfrescoError userInfo:nil];
            }
            break;
                
            // RELATED TO BUG MOBSDK-560
            case kAlfrescoErrorCodeDocumentFolderPermissions:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccessDeniedNotification object:alfrescoError userInfo:nil];
            }
            break;
                
            // RELATED TO BUG MOBSDK-561
            case kAlfrescoErrorCodeUnknown:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccessDeniedNotification object:alfrescoError userInfo:nil];
            }
            break;
             
            case kAlfrescoErrorCodeAccessTokenExpired:
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoTokenExpiredNotification object:alfrescoError userInfo:nil];
            }
                break;
                
            default:
                break;
        }
    }
}

+ (void)postDocumentDownloadedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDownloadedNotification object:nil userInfo:userInfo];
}

@end
