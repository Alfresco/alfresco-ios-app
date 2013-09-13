/*
 ******************************************************************************
 * Copyright (C) 2005-2013 Alfresco Software Limited.
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

@interface AlfrescoContent : NSObject
/// @param the mimeType
@property (nonatomic, strong, readonly) NSString *mimeType;

/// @param the length of the file
@property (nonatomic, assign, readonly) unsigned long long length;

- (id)initWithMimeType:(NSString *)mimeType;
- (id)initWithMimeType:(NSString *)mimeType length:(unsigned long long)length;
@end
