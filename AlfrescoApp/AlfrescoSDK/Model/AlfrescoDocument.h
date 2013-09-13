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

#import "AlfrescoNode.h"

/** The AlfrescoDocument represents a document in an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoDocument : AlfrescoNode

/// @name Properties.

/// The mime type of the content stored in the document.
@property (nonatomic, strong, readonly) NSString *contentMimeType;


/// The length of the content stored in the document, in bytes.
@property (nonatomic, assign, readonly) unsigned long long contentLength;


/// The version of the document.
@property (nonatomic, strong, readonly) NSString *versionLabel;


/// The version of the document.
@property (nonatomic, strong, readonly) NSString *versionComment;


/// Specifies whether this is the latest version.
@property (nonatomic, assign, readonly) BOOL isLatestVersion;

- (id)initWithProperties:(NSDictionary *)properties;


@end
