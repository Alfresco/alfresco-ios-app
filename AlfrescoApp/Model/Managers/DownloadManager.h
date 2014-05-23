//
//  DownloadManager.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 29/07/2013
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

@class AlfrescoDocument;
@protocol AlfrescoSession;

typedef void (^DownloadManagerFileSavedBlock)(NSString *filePath);

@interface DownloadManager : NSObject

+ (DownloadManager *)sharedManager;

- (NSMutableArray *)downloadedDocumentPaths;

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath session:(id<AlfrescoSession>)alfrescoSession
                      completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)moveFileIntoSecureContainer:(NSString *)absolutePath completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)removeFromDownloads:(NSString *)filePath;
- (void)renameLocalDocument:(NSString *)documentLocalName toName:(NSString *)newName;
- (BOOL)isDownloadedDocument:(NSString *)filePath;
- (AlfrescoDocument *)infoForDocument:(NSString *)documentName;
- (NSString *)updateDownloadedDocument:(AlfrescoDocument *)document withContentsOfFileAtPath:(NSString *)filePath;

@end
