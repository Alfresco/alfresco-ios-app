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

#import "AlfrescoObjectConverter.h"
#import "AlfrescoInternalConstants.h"

@implementation AlfrescoObjectConverter

+ (NSDictionary *)listJSONFromData:(NSData *)data error:(NSError **)outError
{
    if (nil == data)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    NSError *error = nil;
    id jsonDictionary = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (nil == jsonDictionary)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    
    if (![jsonDictionary isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    
    id listObject = [jsonDictionary valueForKey:kAlfrescoCloudJSONList];
    if (![listObject isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    return (NSDictionary *)listObject;
}



+ (NSDictionary *)paginationJSONFromData:(NSData *)data error:(NSError **)outError
{
    NSDictionary *list = [AlfrescoObjectConverter listJSONFromData:data error:outError];
    if (nil == list)
    {
        return nil;
    }
    id paginationObj = [list valueForKey:kAlfrescoCloudJSONPagination];
    if (![paginationObj isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    return (NSDictionary *)paginationObj;
}


+ (NSArray *)arrayJSONEntriesFromListData:(NSData *)data error:(NSError **)outError
{
    NSDictionary *list = [AlfrescoObjectConverter listJSONFromData:data error:outError];
    if (nil == list)
    {
        return nil;
    }
    id entries = [list valueForKey:kAlfrescoCloudJSONEntries];
    if (![entries isKindOfClass:[NSArray class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    NSArray *entriesArray = [NSArray arrayWithArray:entries];
    return entriesArray;
}


+ (NSDictionary *)dictionaryJSONEntryFromListData:(NSData *)data error:(NSError **)outError
{
    if (nil == data)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    NSError *error = nil;
    id jsonSite = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(nil == jsonSite)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        return nil;
    }
    if ([jsonSite isKindOfClass:[NSDictionary class]] == NO)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    if([[jsonSite valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
    {
        //        *outError = [AlfrescoErrors createAlfrescoErrorWithCode:kAlfrescoErrorCodeSites withDetailedDescription:@"Parse result is no sites"];
        return nil;
    }
    id jsonDictObj = (NSDictionary *)jsonSite;
    if (![jsonDictObj isKindOfClass:[NSDictionary class]])
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    NSDictionary *jsonDict = (NSDictionary *)jsonDictObj;
    NSDictionary *entryDict = [jsonDict valueForKey:kAlfrescoCloudJSONEntry];
    if (nil == entryDict)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNoEntry];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNoEntry];
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNoEntry];
        }
    }
    return entryDict;
}

+ (NSString *)nodeRefWithoutVersionID:(NSString *)originalIdentifier
{
    if (nil == originalIdentifier)
    {
        return originalIdentifier;
    }
    //    NSString *stringId = [originalIdentifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    
    NSArray *strings = [originalIdentifier componentsSeparatedByString:@";"];
    if (strings.count > 1)
    {
        return (NSString *)[strings objectAtIndex:0];
    }
    return originalIdentifier;
}

- (id)parseJSONData:(NSData *)jsonData notFoundErrorCode:(AlfrescoErrorCodes)errorCode parseBlock:(id (^)(id jsonObject, NSError *parseError))parseBlock
{
    NSError *conversionError = nil;
    
    if (jsonData == nil)
    {
        if (conversionError == nil)
        {
            conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            return parseBlock(nil, conversionError);
        }
        else
        {
            NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            conversionError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            return parseBlock(nil, conversionError);
        }
    }
    
    NSError *parseError = nil;
    id jsonResponseObject = [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:&parseError];
    if (parseError)
    {
        conversionError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:parseError andAlfrescoErrorCode:errorCode];
        return parseBlock(jsonResponseObject, conversionError);
    }
    if ([[jsonResponseObject valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
    {
        conversionError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:parseError andAlfrescoErrorCode:errorCode];
        return parseBlock(jsonResponseObject, conversionError);
    }
    
    return parseBlock(jsonResponseObject, conversionError);
}

@end
