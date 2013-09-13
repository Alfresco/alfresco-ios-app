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
/** The AlfrescoPermissions holds the doable actions for nodes (documents/folders).
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoPermissions : NSObject <NSCoding>

/// edit flag
@property (nonatomic, assign, readonly) BOOL canEdit;
/// delete flag
@property (nonatomic, assign, readonly) BOOL canDelete;
/// add children flag
@property (nonatomic, assign, readonly) BOOL canAddChildren;
/// add comment flag
@property (nonatomic, assign, readonly) BOOL canComment;
/// read content flag
@property (nonatomic, assign, readonly) BOOL canGetContent;
/// write content flag
@property (nonatomic, assign, readonly) BOOL canSetContent;
/// read properties flag
@property (nonatomic, assign, readonly) BOOL canGetProperties;

/// can get children flag
@property (nonatomic, assign, readonly) BOOL canGetChildren;

/// can get all versions flag
@property (nonatomic, assign, readonly) BOOL canGetAllVersions;

- (id)initWithPermissions:(NSSet *)permissionsSet;

@end
