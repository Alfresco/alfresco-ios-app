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

#import "AlfrescoURLUtils.h"
#import "AlfrescoInternalConstants.h"

@implementation AlfrescoURLUtils

+ (NSURL *)buildURLFromBaseURLString:(NSString *)baseURL extensionURL:(NSString *)extensionURL
{
    return [AlfrescoURLUtils buildURLFromBaseURLString:baseURL extensionURL:extensionURL listingContext:nil];
}

+ (NSURL *)buildURLFromBaseURLString:(NSString *)baseURL extensionURL:(NSString *)extensionURL listingContext:(AlfrescoListingContext *)listingContext
{
    NSMutableString *mutableRequestString = [NSMutableString string];
    if ([baseURL hasSuffix:@"/"] && [extensionURL hasPrefix:@"/"])
    {
        [mutableRequestString appendString:[baseURL substringToIndex:baseURL.length - 1]];
        [mutableRequestString appendString:extensionURL];
    }
    else
    {
        NSString *separator = ([baseURL hasSuffix:@"/"] || [extensionURL hasPrefix:@"/"]) ? @"" : @"/";
        [mutableRequestString appendString:baseURL];
        [mutableRequestString appendString:separator];
        [mutableRequestString appendString:extensionURL];
    }
    
    NSString *pagingExtensionString = [AlfrescoURLUtils buildPagingExtensionFromURL:extensionURL listingContext:listingContext];
    if (nil != pagingExtensionString)
    {
        [mutableRequestString appendString:pagingExtensionString];
    }
    
    NSString *requestString = [mutableRequestString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    return [NSURL URLWithString:requestString];    
}

+ (NSString *)buildPagingExtensionFromURL:(NSString *)extensionURL listingContext:(AlfrescoListingContext *)listingContext
{
    if (nil == listingContext)
    {
        return nil;
    }
    if (listingContext.maxItems <= 0)
    {
        return nil;
    }
    NSString *parameterString = nil;
    if ([extensionURL rangeOfString:@"?"].location == NSNotFound)
    {
        parameterString = @"?";
    }
    else
    {
        parameterString = @"&";
    }
    NSString *parameterExtension = [kAlfrescoCloudPagingAPIParameters stringByReplacingOccurrencesOfString:kAlfrescoMaxItems
                                                                                                withString:[NSString stringWithFormat:@"%d",listingContext.maxItems]];
    
    parameterExtension = [parameterExtension stringByReplacingOccurrencesOfString:kAlfrescoSkipCount
                                                                       withString:[NSString stringWithFormat:@"%d", listingContext.skipCount]];
    
    return [NSString stringWithFormat:@"%@%@",parameterString, parameterExtension];    
}

+ (NSString *)buildQueryStringWithDictionary:(NSDictionary *)parameters
{
    NSMutableString *queryString = [[NSMutableString alloc] init];
    
    if (parameters)
    {
        [queryString appendString:@"?"];
        NSArray *allKeys = [parameters allKeys];
        for (int i = 0; i < allKeys.count; i++)
        {
            id key = allKeys[i];
            id value = [parameters objectForKey:key];
            [queryString appendString:[NSString stringWithFormat:@"%@=%@", key, value]];
            if (i != (allKeys.count -1))
            {
                [queryString appendString:@"&"];
            }
        }
    }
    
    return queryString;
}

@end
