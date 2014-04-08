//
//  DocumentPreviewManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 07/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^DocumentPreviewManagerFileSavedBlock)(NSString *filePath);

// Download Status Notifications
extern NSString * const kDocumentPreviewManagerWillStartDownloadNotification;
extern NSString * const kDocumentPreviewManagerProgressNotification;
extern NSString * const kDocumentPreviewManagerDocumentDownloadCompletedNotification;

// Download Detail Keys
extern NSString * const kDocumentPreviewManagerDocumentIdentifierNotificationKey;
extern NSString * const kDocumentPreviewManagerProgressBytesRecievedNotificationKey;
extern NSString * const kDocumentPreviewManagerProgressBytesTotalNotificationKey;

@interface DocumentPreviewManager : NSObject

+ (instancetype)sharedManager;

/*
 * This method returns true if the document passed in is currently being downloaded
 */
- (BOOL)isCurrentlyDownloadingDocument:(AlfrescoDocument *)document;

/*
 * This method returns true if the document passed in is has been downloaded and is cached in the temp folder
 */
- (BOOL)hasLocalContentOfDocument:(AlfrescoDocument *)document;

/*
 * This method provides the identifier - essentailly it is the filename with the last modified date appended
 */
- (NSString *)documentIdentifierForDocument:(AlfrescoDocument *)document;

/*
 * This method provides the absolute file path of the document to where the documents are cached. It will return the path regardless of
 * whether the file exists or not
 */
- (NSString *)filePathForDocument:(AlfrescoDocument *)document;

/*
 * This method starts downloading the document if it is not currently cached. To recieve updated to the status of the download, register
 * for the appropiate notifications.
 */
- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document session:(id<AlfrescoSession>)session;

@end
