/*******************************************************************************
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
 ******************************************************************************/

#import "AlfrescoSortingUtils.h"
#import "AlfrescoConstants.h"

@implementation AlfrescoSortingUtils

+(NSArray *)sortedArrayForArray:(NSArray *)array sortKey:(NSString *)key ascending:(BOOL)isAscending
{
    if (nil == array)
    {
        return nil;
    }
    if (0 == array.count)
    {
        return array;
    }
    if ([key isEqualToString:kAlfrescoSortByCreatedAt] || [key isEqualToString:kAlfrescoSortByModifiedAt])
    {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key
                                                                     ascending:isAscending
                                                                      selector:@selector(compare:)];
        NSArray *sortArray = [NSArray arrayWithObject:descriptor];
        return [array sortedArrayUsingDescriptors:sortArray];
    }
    else
    {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:key
                                                                     ascending:isAscending
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortArray = [NSArray arrayWithObject:descriptor];
        return [array sortedArrayUsingDescriptors:sortArray];
    }
}

+(NSArray *)sortedArrayForArray:(NSArray *)array
                        sortKey:(NSString *)key
                  supportedKeys:(NSArray* )keys
                     defaultKey:(NSString *)defaultKey
                      ascending:(BOOL)isAscending
{
    if (nil == array || nil == keys || nil == defaultKey)
    {
        return nil;
    }
    if (0 == array.count)
    {
        return array;
    }
    NSString *sortKey = [AlfrescoSortingUtils sortKeyForDesiredKey:key supportedKeys:keys defaultKey:defaultKey];
    if ([sortKey isEqualToString:kAlfrescoSortByCreatedAt] || [sortKey isEqualToString:kAlfrescoSortByModifiedAt])
    {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey
                                                                     ascending:isAscending
                                                                      selector:@selector(compare:)];
        NSArray *sortArray = [NSArray arrayWithObject:descriptor];
        return [array sortedArrayUsingDescriptors:sortArray];
    }
    else
    {
        NSSortDescriptor *descriptor = [NSSortDescriptor sortDescriptorWithKey:sortKey
                                                                     ascending:isAscending
                                                                      selector:@selector(localizedCaseInsensitiveCompare:)];
        NSArray *sortArray = [NSArray arrayWithObject:descriptor];
        return [array sortedArrayUsingDescriptors:sortArray];
    }
}

+(NSString *)sortKeyForDesiredKey:(NSString *)desiredKey supportedKeys:(NSArray *)keys defaultKey:(NSString *)defaultKey
{
    if ([keys containsObject:desiredKey])
    {
        return desiredKey;
    }
    else
    {
        return defaultKey;
    }
    
}



+(NSString *)sortKeyFromListingContext:(AlfrescoListingContext *)listingContext supportedKeys:(NSArray *)keys defaultKey:(NSString *)defaultKey
{
    if (nil == keys || nil == defaultKey || nil == listingContext)
    {
        return nil;
    }
    NSString *desiredSortKey = listingContext.sortProperty;
    if ([keys containsObject:desiredSortKey])
    {
        return desiredSortKey;
    }
    else
    {
        return defaultKey;
    }
}


@end
