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

#import "AlfrescoCloudCommentService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"
#import <objc/runtime.h>
#import "AlfrescoObjectConverter.h"

@interface AlfrescoCloudCommentService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoCloudCommentService

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

- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    AlfrescoListingContext *maxListing = [[AlfrescoListingContext alloc] initWithMaxItems:-1];
    return [self retrieveCommentsForNode:node arrayCompletionBlock:completionBlock pagingCompletionBlock:nil listingContext:maxListing usePaging:NO];
}

- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node
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
    return [self retrieveCommentsForNode:node arrayCompletionBlock:nil pagingCompletionBlock:completionBlock listingContext:listingContext usePaging:YES];
}



- (AlfrescoRequest *)addCommentToNode:(AlfrescoNode *)node
                              content:(NSString *)content
                                title:(NSString *)title
                      completionBlock:(AlfrescoCommentCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    [commentDict setValue:content forKey:kAlfrescoJSONContent];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commentDict options:0 error:&error];
    
    NSString *requestString = [kAlfrescoCloudCommentsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                   withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPOST
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *data, NSError *responseError){
        if (nil == data)
        {
            completionBlock(nil, responseError);
        }
        else
        {
            NSError *conversionError = nil;
            AlfrescoComment *comment = [self alfrescoCommentFromJSONData:data error:&conversionError];
            completionBlock(comment, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)updateCommentOnNode:(AlfrescoNode *)node
                                 comment:(AlfrescoComment *)comment
                                 content:(NSString *)content
                         completionBlock:(AlfrescoCommentCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [AlfrescoErrors assertArgumentNotNil:comment argumentName:@"comment"];
    [AlfrescoErrors assertArgumentNotNil:comment.identifier argumentName:@"comment.identifier"];

    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    [commentDict setValue:content forKey:kAlfrescoJSONContent];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commentDict options:0 error:&error];
    NSString *nodeRefString = [kAlfrescoCloudCommentForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                         withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSString *requestString = [nodeRefString stringByReplacingOccurrencesOfString:kAlfrescoCommentId
                                                                       withString:[comment.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
                                                 method:kAlfrescoHTTPPut
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *data, NSError *responseError){
        if (nil == data)
        {
            completionBlock(nil, responseError);
        }
        else
        {
            NSError *conversionError = nil;
            AlfrescoComment *comment = [self alfrescoCommentFromJSONData:data error:&conversionError];
            completionBlock(comment, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)deleteCommentFromNode:(AlfrescoNode *)node
                                   comment:(AlfrescoComment *)comment
                           completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    [AlfrescoErrors assertArgumentNotNil:comment argumentName:@"comment"];
    [AlfrescoErrors assertArgumentNotNil:comment.identifier argumentName:@"comment.identifier"];
    
    NSString *nodeRefString = [kAlfrescoCloudCommentForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                         withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    
    NSString *requestString = [nodeRefString stringByReplacingOccurrencesOfString:kAlfrescoCommentId
                                                                       withString:[comment.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:nil
                                                 method:kAlfrescoHTTPDelete
                                        alfrescoRequest:alfrescoRequest
                                        completionBlock:^(NSData *data, NSError *responseError){
        if (nil == data)
        {
            completionBlock(NO, responseError);
        }
        else
        {
            completionBlock(YES, nil);
        }
    }];
    return alfrescoRequest;
}


#pragma private methods
- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node arrayCompletionBlock:(AlfrescoArrayCompletionBlock)arrayCompletionBlock pagingCompletionBlock:(AlfrescoPagingResultCompletionBlock)pagingCompletionBlock listingContext:(AlfrescoListingContext *)listingContext usePaging:(BOOL)usePaging
{
    NSString *requestString = [kAlfrescoCloudCommentsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                   withString:[node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
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
            NSArray *comments = [self commentArrayFromJSONData:responseData error:&conversionError];
            if (usePaging)
            {
                NSDictionary *pagingInfo = [AlfrescoObjectConverter paginationJSONFromData:responseData error:&conversionError];
                AlfrescoPagingResult *pagingResult = nil;
                if (nil != comments && pagingInfo)
                {
                    BOOL hasMore = [[pagingInfo valueForKeyPath:kAlfrescoCloudJSONHasMoreItems] boolValue];
                    int total = [[pagingInfo valueForKey:kAlfrescoCloudJSONTotalItems] intValue];
                    NSArray *sortedCommentArray = [AlfrescoSortingUtils sortedArrayForArray:comments sortKey:kAlfrescoSortByCreatedAt ascending:YES];
                    pagingResult = [[AlfrescoPagingResult alloc] initWithArray:sortedCommentArray hasMoreItems:hasMore totalItems:total];
                }
                pagingCompletionBlock(pagingResult, conversionError);
            }
            else
            {
                if (nil != comments)
                {
                    NSArray *sortedCommentArray = [AlfrescoSortingUtils sortedArrayForArray:comments sortKey:kAlfrescoSortByCreatedAt ascending:YES];
                    arrayCompletionBlock(sortedCommentArray, nil);
                }
                else
                {
                    arrayCompletionBlock(nil, conversionError);
                }
            }
        }
    }];
    
    return alfrescoRequest;
}


- (NSArray *) commentArrayFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
{
    NSArray *entriesArray = [AlfrescoObjectConverter arrayJSONEntriesFromListData:data error:outError];
    if (nil == entriesArray)
    {
        if (nil == *outError)
        {
            *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeCommentNoCommentFound];
        }
        return nil;
    }
    
    NSMutableArray *resultsArray = [NSMutableArray arrayWithCapacity:entriesArray.count];
    
    for (NSDictionary *entryDict in entriesArray)
    {
        NSDictionary *individualEntry = [entryDict valueForKey:kAlfrescoCloudJSONEntry];
        if (nil == individualEntry)
        {
            if (nil == *outError)
            {
                *outError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeComment];
            }
            else
            {
                NSError *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeComment];
                *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeComment];
                
            }
            return nil;
        }
        else
        {
            [resultsArray addObject:[[AlfrescoComment alloc] initWithProperties:individualEntry]];
        }
    }
    return resultsArray;
}

- (AlfrescoComment *) alfrescoCommentFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
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
    id jsonCommentDict = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
    if(nil == jsonCommentDict)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeComment];
        return nil;
    }
    NSDictionary *jsonComment = [jsonCommentDict valueForKey:kAlfrescoCloudJSONEntry];
    if (nil == jsonComment)
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
    return [[AlfrescoComment alloc] initWithProperties:jsonComment];
}

@end
