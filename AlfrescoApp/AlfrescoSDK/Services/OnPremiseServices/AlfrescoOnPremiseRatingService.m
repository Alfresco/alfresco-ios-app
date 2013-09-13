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

#import "AlfrescoOnPremiseRatingService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoRepositoryInfo.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoObjectConverter.h"
#import <objc/runtime.h>
#import "AlfrescoNetworkProvider.h"

@interface AlfrescoOnPremiseRatingService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoOnPremiseRatingService

- (id)initWithSession:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.session = session;
        self.baseApiUrl = [[self.session.baseUrl absoluteString] stringByAppendingString:kAlfrescoOnPremiseAPIPath];
        id authenticationObject = [session objectForParameter:kAlfrescoAuthenticationProviderObjectKey];
        self.authenticationProvider = nil;
        if ([authenticationObject isKindOfClass:[AlfrescoBasicAuthenticationProvider class]])
        {
            self.authenticationProvider = (AlfrescoBasicAuthenticationProvider *)authenticationObject;
        }
        AlfrescoRepositoryCapabilities *capabilities = self.session.repositoryInfo.capabilities;
        if (![capabilities doesSupportCapability:kAlfrescoCapabilityLike])
        {
            return nil;
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
    
    NSString *nodeIdentifier = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeIdentifier];
    NSString *requestString = [kAlfrescoOnPremiseRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:cleanNodeId];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *responseData, NSError *error){
        if (nil == responseData)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSError *conversionError = nil;
            NSDictionary *ratingsDict = [NSJSONSerialization JSONObjectWithData:responseData options:0 error:&conversionError];
            NSNumber *count = [ratingsDict valueForKeyPath:kAlfrescoOnPremiseRatingsCount];
            completionBlock(count, conversionError);
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
    [likeDict setValue:[NSNumber numberWithInt:1] forKey:kAlfrescoJSONRating];
    [likeDict setValue:kAlfrescoJSONLikesRatingScheme forKey:kAlfrescoJSONRatingScheme];
    
    NSString *nodeIdentifier = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeIdentifier];
    NSString *requestString = [kAlfrescoOnPremiseRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:cleanNodeId];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:likeDict options:0 error:&error];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
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
 
- (AlfrescoRequest *)unlikeNode:(AlfrescoNode *)node
   completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeIdentifier = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeIdentifier];
    NSString *requestString = [kAlfrescoOnPremiseRatingsLikingSchemeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:cleanNodeId];
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
 
- (AlfrescoRequest *)isNodeLiked:(AlfrescoNode *)node completionBlock:(AlfrescoLikedCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeIdentifier = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeIdentifier];
    NSString *requestString = [kAlfrescoOnPremiseRatingsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef withString:cleanNodeId];
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
            NSDictionary *ratingsDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&conversionError];
            BOOL isLiked = [[ratingsDict valueForKeyPath:kAlfrescoOnPremiseLikesSchemeRatings] boolValue];
            completionBlock(YES, isLiked, nil);
        }
    }];
    return request;
}
@end
