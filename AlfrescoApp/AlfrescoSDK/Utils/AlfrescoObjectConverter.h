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

/** AlfrescoObjectConverter
 
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>
#import "AlfrescoErrors.h"

@interface AlfrescoObjectConverter : NSObject

+ (NSArray *)arrayJSONEntriesFromListData:(NSData *)data error:(NSError **)outError;

+ (NSDictionary *)paginationJSONFromData:(NSData *)data error:(NSError **)outError;

+ (NSDictionary *)listJSONFromData:(NSData *)data error:(NSError **)outError;

+ (NSDictionary *)dictionaryJSONEntryFromListData:(NSData *)data error:(NSError **)outError;

+ (NSString *)nodeRefWithoutVersionID:(NSString *)originalIdentifier;

- (id)parseJSONData:(NSData *)jsonData notFoundErrorCode:(AlfrescoErrorCodes)errorCode parseBlock:(id (^)(id jsonObject, NSError *parseError))parseBlock;

@end
