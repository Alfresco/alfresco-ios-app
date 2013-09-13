/*
 ******************************************************************************
 * Copyright (C) 2005-2012 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile SDK.
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
 *****************************************************************************
 */

#import <Foundation/Foundation.h>
#import "AlfrescoContent.h"
/** The AlfrescoContentFile objects are used for download/upload content.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoContentFile : AlfrescoContent

/// @name Properties
/// @param the file based URL
@property (nonatomic, strong, readonly) NSURL *fileUrl;

/**---------------------------------------------------------------------------------------
 * @name initialisers.
 *  ---------------------------------------------------------------------------------------
 */

/**
 Creates a new file in the temporary directory folder and copies the data of the file at URL
 Detects the mime type based on the extension of the file. This method is when downloading a file from a given URL
 @param the URL of the file.
 */
- (id)initWithUrl:(NSURL *)url;

/**
 Creates a new file in the temporary directory folder and copies the data of the file at URL
 Detects the mime type based on the extension of the file. This method is when downloading a file from a given URL
 @param the URL of the file.
 @param mimeType. If nil is passed in, AlfrescoContentFile attempts to deduce the mimetype from the file name. In case none can be found, the mimeType will remain nil.
 */
- (id)initWithUrl:(NSURL *)url mimeType:(NSString *)mimeType;

/** creates a new  file in the temporary folder. This method is used for uploading. E.g. images from the Photolibrary
 are accessible through their data, but not directly through a file URL.
 
 @param data The data to initialise the AlfrescoContentFile with
 @param mimeType the mime type of the data
 */
- (id)initWithData:(NSData *)data mimeType:(NSString *)mimeType;

@end
