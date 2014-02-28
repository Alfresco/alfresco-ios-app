//
//  ErrorNotifier.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "Notifier.h"

@implementation Notifier

+ (void)notifyWithAlfrescoError:(NSError *)alfrescoError
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
            
        default:
            break;
    }
}

+ (void)postDocumentDownloadedNotificationWithUserInfo:(NSDictionary *)userInfo
{
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoDocumentDownloadedNotification object:nil userInfo:userInfo];
}

@end
