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

#import "AlfrescoListingContext+Dictionary.h"

@implementation AlfrescoListingContext (Dictionary)

+ (AlfrescoListingContext *)listingContextFromDictionary:(NSDictionary *)dictionary
{
    return [[AlfrescoListingContext alloc] initWithDictionary:dictionary];
}

- (AlfrescoListingContext *)initWithDictionary:(NSDictionary *)dictionary
{
    if (dictionary)
    {
        int maxItems = kMaxItemsPerListingRetrieve;
        NSNumber *maxItemsNumber = dictionary[kAlfrescoConfigViewParameterPaginationMaxItemsKey];
        
        if (maxItemsNumber && maxItemsNumber.intValue >= 0)
        {
            maxItems = maxItemsNumber.intValue;
        }
        
        int skipCount = 0;
        NSNumber *skipCountNumber = dictionary[kAlfrescoConfigViewParameterPaginationSkipCountKey];
        
        if (skipCountNumber && skipCountNumber.intValue > 0)
        {
            skipCount = skipCountNumber.intValue;
        }
        
        self = [self initWithMaxItems:maxItems skipCount:skipCount];
    }
    else
    {
        self = nil;
    }
    
    return self;
}

@end
