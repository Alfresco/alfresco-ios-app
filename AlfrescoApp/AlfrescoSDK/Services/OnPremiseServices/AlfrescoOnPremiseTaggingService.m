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

#import "AlfrescoOnPremiseTaggingService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoTag.h"
#import "AlfrescoObjectConverter.h"
#import "AlfrescoNetworkProvider.h"

@interface AlfrescoOnPremiseTaggingService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoOnPremiseTaggingService

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


- (AlfrescoRequest *)retrieveAllTagsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoOnPremiseTagsAPI];
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
            NSArray *tagArray = [self tagArrayFromJSONData:data error:&conversionError];
            completionBlock(tagArray, conversionError);
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveAllTagsWithListingContext:(AlfrescoListingContext *)listingContext
                                       completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:kAlfrescoOnPremiseTagsAPI];
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
            NSArray *tagArray = [self tagArrayFromJSONData:data error:&conversionError];
            AlfrescoPagingResult *pagingResults = [AlfrescoPagingUtils pagedResultFromArray:tagArray listingContext:listingContext];
            completionBlock(pagingResults, conversionError);
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                         completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    NSString *cleanNodeId = [nodeId stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *requestString = [kAlfrescoOnPremiseTagsForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                          withString:cleanNodeId];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if(nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSArray *tagArray = [self customTagArrayFromJSONData:data];
            completionBlock(tagArray, nil);
        }
    }];
    return request;
}

- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                          listingContext:(AlfrescoListingContext *)listingContext
                         completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    if (nil == listingContext)
    {
        listingContext = self.session.defaultListingContext;
    }
    
    NSString *nodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    NSString *cleanNodeId = [nodeId stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *requestString = [kAlfrescoOnPremiseTagsForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                          withString:cleanNodeId];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *request = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                        alfrescoRequest:request
                                        completionBlock:^(NSData *data, NSError *error){
        if(nil == data)
        {
            completionBlock(nil, error);
        }
        else
        {
            NSArray *tagArray = [self customTagArrayFromJSONData:data];
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:tagArray listingContext:listingContext];
            completionBlock(pagingResult, nil);
        }
    }];
    return request;
}

- (AlfrescoRequest *)addTags:(NSArray *)tags
                      toNode:(AlfrescoNode *)node
             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:tags argumentName:@"tags"];
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    NSString *cleanNodeId = [nodeId stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *requestString = [kAlfrescoOnPremiseTagsForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                          withString:cleanNodeId];
    NSError *jsonError = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:tags options:0 error:&jsonError];
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
            completionBlock(YES, nil);
        }
    }];
    return request;
}

#pragma mark Site service internal methods

- (NSArray *) tagArrayFromJSONData:(NSData *)data error:(NSError **)outError
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
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeTagging];
            
        }
        return nil;
    }
    NSError *error = nil;
    id jsonTagArray = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if (nil != error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeTagging];
        return nil;
    }
    if ([jsonTagArray isKindOfClass:[NSArray class]] == NO)
    {
        if([jsonTagArray isKindOfClass:[NSDictionary class]] == YES &&
           [[jsonTagArray valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
        {
            // no results found
            *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeTagging];
            return nil;
        }
        else
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
    }
    NSMutableArray *resultsArray = [NSMutableArray array];
    for (NSString * tagValue in jsonTagArray)
    {
        NSMutableDictionary *tagDict = [NSMutableDictionary dictionary];
        [tagDict setValue:tagValue forKey:kAlfrescoJSONTag];
        AlfrescoTag *tag = [[AlfrescoTag alloc] initWithProperties:tagDict];
        [resultsArray addObject:tag];
    }
    return resultsArray;
}

- (NSArray *) customTagArrayFromJSONData:(NSData *) data
{
    NSString *tagString = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    tagString = [tagString stringByReplacingOccurrencesOfString:@"[" withString:@""];
    tagString = [tagString stringByReplacingOccurrencesOfString:@"]" withString:@""];
    NSArray *separatedTagArray = [tagString componentsSeparatedByString:@","];
    NSMutableArray *tagArray = [NSMutableArray arrayWithCapacity:separatedTagArray.count];
    for (NSString *tag in separatedTagArray)
    {
        NSString *trimmedString = [tag stringByTrimmingCharactersInSet:
                                   [NSCharacterSet whitespaceAndNewlineCharacterSet]];
        if ([trimmedString length] > 0)
        {
            NSMutableDictionary *tagDict = [NSMutableDictionary dictionary];
            [tagDict setValue:trimmedString forKey:kAlfrescoJSONTag];
            AlfrescoTag *tag = [[AlfrescoTag alloc] initWithProperties:tagDict];
            [tagArray addObject:tag];
        }
    }
    
    return tagArray;
}

@end
