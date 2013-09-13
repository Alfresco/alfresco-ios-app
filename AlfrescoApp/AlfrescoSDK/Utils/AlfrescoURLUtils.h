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

/**
 Author: Tauseef Mughal (Alfresco)
 */

#import <Foundation/Foundation.h>
#import "AlfrescoListingContext.h"

@interface AlfrescoURLUtils : NSObject

+ (NSURL *)buildURLFromBaseURLString:(NSString *)baseURL extensionURL:(NSString *)extensionURL;

+ (NSURL *)buildURLFromBaseURLString:(NSString *)baseURL extensionURL:(NSString *)extensionURL listingContext:(AlfrescoListingContext *)listingContext;

+ (NSString *)buildQueryStringWithDictionary:(NSDictionary *)parameters;

@end
