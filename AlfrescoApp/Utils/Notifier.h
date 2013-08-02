//
//  ErrorNotifier.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Notifier : NSObject

+ (void)notifyWithAlfrescoError:(NSError *)alfrescoError;

/*
 * Used to post notification when a download finished successfully
 *
 * User Info: None
 */
+ (void)postDocumentDownloadedNotificationWithUserInfo:(NSDictionary *)userInfo;


@end
