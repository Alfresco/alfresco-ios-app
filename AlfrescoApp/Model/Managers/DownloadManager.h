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
  
@class AlfrescoDocument;
@protocol AlfrescoSession;

typedef void (^DownloadManagerFileSavedBlock)(NSString *filePath);

@interface DownloadManager : NSObject

+ (DownloadManager *)sharedManager;

- (NSMutableArray *)downloadedDocumentPaths;

- (AlfrescoRequest *)downloadDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath session:(id<AlfrescoSession>)alfrescoSession
                      completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath suppressAlerts:(BOOL)suppressAlerts completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)saveDocument:(AlfrescoDocument *)document documentName:(NSString *)documentName contentPath:(NSString *)contentPath completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)saveDocument:(AlfrescoDocument *)document contentPath:(NSString *)contentPath showOverrideAlert:(BOOL)showOverrideAlert completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)moveFileIntoSecureContainer:(NSString *)absolutePath completionBlock:(DownloadManagerFileSavedBlock)completionBlock;
- (void)removeFromDownloads:(NSString *)filePath;
- (void)renameLocalDocument:(NSString *)documentLocalName toName:(NSString *)newName;
- (BOOL)isDownloadedDocument:(NSString *)filePath;
- (AlfrescoDocument *)infoForDocument:(NSString *)documentName;
- (NSString *)updateDownloadedDocument:(AlfrescoDocument *)document withContentsOfFileAtPath:(NSString *)filePath;
- (void)removeAllDownloads;

@end
