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

#import "AlfrescoCloudRatingService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"
#import <objc/runtime.h>

@interface AlfrescoCloudRatingService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoCloudRatingService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoCloudAPIPath];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
    }
    return self;
}

- (AlfrescoRequest *)retrieveLikeCountForNode:(AlfrescoNode *)node
                              completionBlock:(AlfrescoNumberCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoCloudRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                  withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSNumber *count = nil;
            NSDictionary *ratingsDict = [self dictionaryFromJSONData:data error:&conversionError];
            id aggregateObject = [ratingsDict valueForKey:kAlfrescoJSONAggregate];
            if ([aggregateObject isKindOfClass:[NSDictionary class]])
            {
                NSDictionary *aggregateDict = (NSDictionary *)aggregateObject;
                count = [aggregateDict valueForKey:kAlfrescoJSONNumberOfRatings];
            }
            else
            {
                conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRatings];                
            }
            completionBlock(count, conversionError);
        }
    }];
    return request;
}

- (AlfrescoRequest *)isNodeLiked:(AlfrescoNode *)node completionBlock:(AlfrescoLikedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *requestString = [kAlfrescoCloudRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                  withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (nil == data)
        {
            completionBlock(NO, NO, error);
        }
        else
        {
            NSError *conversionError = nil;
            BOOL isLiked = NO;
            BOOL success = NO;
            NSDictionary *ratingsDict = [self dictionaryFromJSONData:data error:&conversionError];
            if (nil == ratingsDict)
            {
                completionBlock(NO, NO, error);
            }
            else
            {                
                id aggregateObject = [ratingsDict valueForKey:kAlfrescoJSONAggregate];
                if ([aggregateObject isKindOfClass:[NSDictionary class]])
                {
                    NSDictionary *aggregateDict = (NSDictionary *)aggregateObject;
                    NSNumber *count = [aggregateDict valueForKey:kAlfrescoJSONNumberOfRatings];
                    NSNumber *isLikedValue = [ratingsDict valueForKey:kAlfrescoJSONMyRating];
                    if (0 < [count intValue])
                    {
                        isLiked = [isLikedValue boolValue];
                    }
                    success = YES;
                }
                else
                {
                    conversionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRatings];
                    success = NO;
                }
                completionBlock(success, isLiked, conversionError);
            }
        }
    }];
    return request;
}


- (AlfrescoRequest *)likeNode:(AlfrescoNode *)node
              completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableDictionary *likeDict = [NSMutableDictionary dictionaryWithCapacity:2];
    [likeDict setValue:[NSNumber numberWithBool:YES] forKey:kAlfrescoJSONMyRating];
    [likeDict setValue:kAlfrescoJSONLikes forKey:kAlfrescoJSONIdentifier];
    
    NSString *requestString = [kAlfrescoCloudRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                  withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:likeDict options:0 error:&error];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *responseError){
        if (nil != error)
        {
            completionBlock(NO, error);
        }
        else
        {
            completionBlock(YES, nil);
        }
    }];
    return request;
}




- (AlfrescoRequest *)unlikeNode:(AlfrescoNode *)node
                completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeRatings = [kAlfrescoCloudRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSString *requestString = [NSString stringWithFormat:@"%@/%@",nodeRatings, kAlfrescoJSONLikes];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                                 method:kAlfrescoHTTPDelete
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if (nil != error)
        {
            completionBlock(NO, error);
        }
        else
        {
            completionBlock(YES, error);
        }
    }];
    return request;
}


- (NSDictionary *) dictionaryFromJSONData:(NSData *)data error:(NSError **)outError
{
    NSArray *entriesArray = [AlfrescoObjectConverter arrayJSONEntriesFromListData:data error:outError];
    if (nil == entriesArray)
    {
        return nil;
    }

    
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
                NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
                *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
                
            }
            return nil;
        }
        NSString *ratingsType = [individualEntry valueForKey:kAlfrescoJSONIdentifier];
        if ([ratingsType hasPrefix:kAlfrescoJSONLikes])
        {
            return individualEntry;
        }
    }
    if (nil == *outError)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRatings];
    }
    else
    {
        NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRatings];
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeRatings];
    }
    return nil;
    
}


@end
