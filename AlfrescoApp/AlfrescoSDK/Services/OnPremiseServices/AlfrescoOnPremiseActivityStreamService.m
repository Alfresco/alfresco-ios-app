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

#import "AlfrescoOnPremiseActivityStreamService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import <objc/runtime.h>
#import "AlfrescoNetworkProvider.h"

@interface AlfrescoOnPremiseActivityStreamService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoOnPremiseActivityStreamService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoOnPremiseAPIPath];
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
     NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoOnPremiseActivityAPI];
     AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
     [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error){
         if (nil == responseData)
         {
             completionBlock(nil, error);
         }
         else
         {
             NSError *conversionError = nil;
             NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
             completionBlock(activityStreamArray, conversionError);
         }
     }];
     return alfrescoRequest;
 }
 
 - (AlfrescoRequest *)retrieveActivityStreamForPerson:(NSString *)personIdentifier listingContext:(AlfrescoListingContext *)listingContext
 completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
 {
     [AlfrescoErrors assertArgumentNotNil:personIdentifier argumentName:@"personIdentifier"];
     [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
     if (nil == listingContext)
     {
         listingContext = self.session.defaultListingContext;
     }
     NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoOnPremiseActivityAPI];
     AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
     [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error){
         if (nil == responseData)
         {
             completionBlock(nil, error);
         }
         else
         {
             NSError *conversionError = nil;
             NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
             AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:activityStreamArray listingContext:listingContext];
             completionBlock(pagingResult, conversionError);
         }
     }];
     return alfrescoRequest;
 }
 
 - (AlfrescoRequest *)retrieveActivityStreamForSite:(AlfrescoSite *)site completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
 {
     [AlfrescoErrors assertArgumentNotNil:site argumentName:@"site"];
     [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
     
     NSString *requestString = [kAlfrescoOnPremiseActivityForSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.shortName];
     NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
     AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
     [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error){
         if (nil == responseData)
         {
             completionBlock(nil, error);
         }
         else
         {
             NSError *conversionError = nil;
             NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
             completionBlock(activityStreamArray, conversionError);
         }
     }];
     return alfrescoRequest;
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
    NSString *requestString = [kAlfrescoOnPremiseActivityForSiteAPI stringByReplacingOccurrencesOfString:kAlfrescoSiteId withString:site.shortName];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url session:self.session alfrescoRequest:alfrescoRequest completionBlock:^(NSData *responseData, NSError *error){
        if (nil == responseData)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSArray *activityStreamArray = [self activityStreamArrayFromJSONData:responseData error:&conversionError];
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:activityStreamArray listingContext:listingContext];
            completionBlock(pagingResult, conversionError);
        }
    }];
    return alfrescoRequest;
}
 
 #pragma mark Activity stream service internal methods
 
- (NSArray *) activityStreamArrayFromJSONData:(NSData *)data error:(NSError **)outError
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
    id jsonActivityStreamArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(nil == jsonActivityStreamArray)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeActivityStream];
        return nil;
    }
    if ([jsonActivityStreamArray isKindOfClass:[NSArray class]] == NO)
    {
        if([jsonActivityStreamArray isKindOfClass:[NSDictionary class]] == YES &&
           [[jsonActivityStreamArray valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
        {
            // no results found
            return [NSArray array];
        }
        else
        {
            if (nil == *outError)
            {
                *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeActivityStreamNoActivities];
            }
            else
            {
                NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeActivityStreamNoActivities];
                *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeActivityStreamNoActivities];
            }
            return nil;
        }
    }
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[jsonActivityStreamArray count]];
    for (NSDictionary *activityDict in jsonActivityStreamArray)
    {
        [resultArray addObject:[[AlfrescoActivityEntry alloc] initWithProperties:activityDict]];
    }
    return resultArray;
}

@end
