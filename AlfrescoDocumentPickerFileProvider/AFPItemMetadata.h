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

#import <Realm/Realm.h>

@interface AFPItemMetadata : RLMObject

@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong) NSString *identifier;
@property (nonatomic) AFPItemMetadata *parentFolder;
@property (nonatomic) BOOL isShared;
@property (nonatomic, strong) NSDate *creationDate;
@property (nonatomic, strong) NSData *node;
@property (nonatomic) BOOL downloaded;

@property (nonatomic) BOOL needsUpload;
@property (nonatomic, strong) NSString *filePath;
// parentIdentifier is used for cases when a parentFolder metadata item is not available (ex: sync)
@property (nonatomic, strong) NSString *parentIdentifier;

@property (readonly) AlfrescoNode *alfrescoNode;

@end
