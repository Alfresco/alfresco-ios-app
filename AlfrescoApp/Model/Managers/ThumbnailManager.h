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
  
@interface ThumbnailManager : NSObject

/*
 * Returns the shared object.
 */
+ (ThumbnailManager *)sharedManager;

/*
 * Returns the cached image for the given document identifier.
 *
 * If the image is not cached, nil will be returned.
 */
- (UIImage *)thumbnailForDocumentIdentifier:(NSString *)documentIdentifier renditionType:(NSString *)renditionType;

/*
 * Returns the cached image for the given document. Both the document identifier and modified date are matched.
 *
 * If the image is not cached, nil will be returned.
 */
- (UIImage *)thumbnailForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType;

/*
 * Retrieves the image for the given document. If it is currently cached, the completion block is called, otherwise a network request
 * to the server is made. Multiple calls to this function for the same document will not result in multiple network requests. Instead,
 * all completion blocks will be called once the call is completed.
 *
 * Once complete, the image is cached and the completion block is called.
 */
- (void)retrieveImageForDocument:(AlfrescoDocument *)document renditionType:(NSString *)renditionType session:(id<AlfrescoSession>)session completionBlock:(ImageCompletionBlock)completionBlock;

@end
