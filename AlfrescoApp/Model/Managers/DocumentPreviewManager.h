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
  
typedef void (^DocumentPreviewManagerFileSavedBlock)(NSString *filePath);

@interface DocumentPreviewManager : NSObject

+ (DocumentPreviewManager *)sharedManager;

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
