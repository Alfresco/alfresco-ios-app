/*******************************************************************************
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
 ******************************************************************************/

#import "AlfrescoCloudActivityStreamService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import <objc/runtime.h>
#import "AlfrescoNetworkProvider.h"

@interface AlfrescoCloudActivityStreamService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoCloudActivityStreamService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudAPIPath];
        self.objectConverter = [[AlfrescoCMISToAlfrescoObjectConverter alloc] initWithSession:self.session];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
    }
    return self;
}



- (AlfrescoRequest *)retrieveActivityStreamWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    return [self retrieveActivityStreamForPerson:self.session.personIdentifier completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveActivityStreamWithListingContext:(AlfrescoListingContext *)listingContext
                                              completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    return [self retrieveActivityStreamForPerson:self.session.personIdentifier listingContext:listingContext completionBlock:completionBlock];
}

- (AlfrescoRequest *)retrieveActivityStreamForPerson:(NSString *)personIdentifier completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:personIdentifier argumentName:@"personIdentifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoListingContext *maxListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:-1];
    return [self requestActivityStreamWithArrayCompletionBlock:completionBlock pagingCompletionBlock:nil listingContext:maxListingContext site:nil usePaging:NO];
}

- (AlfrescoRequest *)retrieveActivityStreamForPerson:(NSString *)personIdentifier
                                      listingContext:(AlfrescoListingContext *)listingContext
                                     completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:personIdentifier argumentName:@"personIdentifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    return [self requestActivityStreamWithArrayCompletionBlock:nil pagingCompletionBlock:completionBlock listingContext:listingContext site:nil usePaging:YES];
}



- (AlfrescoRequest *)retrieveActivityStreamForSite:(AlfrescoSite *)site completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    AlfrescoListingContext *maxListingContext = [[AlfrescoListingContext alloc] initWithMaxItems:-1];
    return [self requestActivityStreamWithArrayCompletionBlock:completionBlock pagingCompletionBlock:nil listingContext:maxListingContext site:site usePaging:NO];
}

- (AlfrescoRequest *)retrieveActivityStreamForSite:(AlfrescoSite *)site
                       listingContext:(AlfrescoListingContext *)listingContext
                      completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }

    return [self requestActivityStreamWithArrayCompletionBlock:nil pagingCompletionBlock:completionBlock listingContext:listingContext site:site usePaging:YES];
}



#pragma mark Activity stream service internal methods
- (AlfrescoRequest *)requestActivityStreamWithArrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock
                                             pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock
                                                    listingContext:(AlfrescoListingContext *)listingContext
                                                              site:(AlfrescoSite *)site
                                                         usePaging:(BOOL)usePaging
{
    NSString *requestString = nil;
    if (site)
    {
        NSString *peopleRefString = [kAlfrescoCloudActivitiesForSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
        requestString = [peopleRefString stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.shortName];
    }
    else
    {
        requestString = [kAlfrescoCloudActivitiesAPI stringByReplacingOccurrencesOfString:kAlfrescoPersonId withString:self.session.personIdentifier];
    }
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString listingContext:listingContext];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error){
        if (nil == responseData)
        {
            if (usePaging)
            {
                pagingCompletionBlock(nil, error);
            }
            else
            {
                arrayCompletionBlock(nil, error);
            }
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
            if (usePaging)
            {
                NSDictionary *pagingInfo = [AlfrescoObjectConverter paginationJSONFromData:responseData error:&conversionError];
                AlfrescoPagingResult *pagingResult = nil;
                if (activityStreamArray && pagingInfo)
                {
                    BOOL hasMore = [[pagingInfo valueForKeyPath:kAlfrescoCloudJSONHasMoreItems] boolValue];
                    int total = -1;
                    if ([pagingInfo valueForKey:kAlfrescoCloudJSONTotalItems])
                    {
                        total = [[pagingInfo valueForKey:kAlfrescoCloudJSONTotalItems] intValue];
                    }
                    pagingResult = [[AlfrescoPagingResult alloc] initWithArray:activityStreamArray hasMoreItems:hasMore totalItems:total];
                }
                pagingCompletionBlock(pagingResult, conversionError);
            }
            else
            {
                NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
                arrayCompletionBlock(activityStreamArray, conversionError);
            }
            
        }
    }];
    
    return alfrescoRequest;
}

- (NSArray *) activityStreamArrayFromJSONData:(NSData *)data error:(NSError **)outError
{
    NSArray *entriesArray = [AlfrescoObjectConverter arrayJSONEntriesFromListData:data error:outError];
    if (nil == entriesArray)
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
    NSMutableArray *resultsArray = [NSMutableArray array];
    
    for (NSDictionary *entryDict in entriesArray)
    {
        NSDictionary *individualEntry = [entryDict valueForKey:kAlfrescoCloudJSONEntry];
        if (nil == individualEntry)
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
        [resultsArray addObject:[[AlfrescoActivityEntry alloc] initWithProperties:individualEntry]];
    }
    return resultsArray;
}

@end
