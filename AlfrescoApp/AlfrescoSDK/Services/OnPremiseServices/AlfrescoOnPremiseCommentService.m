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

#import "AlfrescoOnPremiseCommentService.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoAuthenticationProvider.h"
#import "AlfrescoBasicAuthenticationProvider.h"
#import "AlfrescoErrors.h"
#import "AlfrescoURLUtils.h"
#import "AlfrescoPagingUtils.h"
#import "AlfrescoSortingUtils.h"
#import "AlfrescoObjectConverter.h"
#import "AlfrescoNetworkProvider.h"
#import "AlfrescoLog.h"
#import <objc/runtime.h>

@interface AlfrescoOnPremiseCommentService ()
@property (nonatomic, strong, readwrite) id<AlfrescoSession> session;
@property (nonatomic, strong, readwrite) NSString *baseApiUrl;
@property (nonatomic, strong, readwrite) AlfrescoCMISToAlfrescoObjectConverter *objectConverter;
@property (nonatomic, weak, readwrite) id<AlfrescoAuthenticationProvider> authenticationProvider;
@end

@implementation AlfrescoOnPremiseCommentService

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

- (AlfrescoRequest *)retrieveCommentsForNode:(AlfrescoNode *)node completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];

    NSString *nodeString = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeString];
    NSString *requestString = [kAlfrescoOnPremiseCommentsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                       withString:cleanNodeId];
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
            NSArray *comments = [self commentArrayFromJSONData:responseData error:&conversionError];
            NSArray *sortedCommentArray = nil;
            if (nil != comments)
            {
                sortedCommentArray = [AlfrescoSortingUtils sortedArrayForArray:comments sortKey:kAlfrescoSortByCreatedAt ascending:YES];
            }
            completionBlock(sortedCommentArray, conversionError);
        }
    }];
    return alfrescoRequest;
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
    
    NSString *nodeString = [node.identifier stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    NSString *cleanNodeId = [AlfrescoObjectConverter nodeRefWithoutVersionID:nodeString];
    NSString *requestString = [kAlfrescoOnPremiseCommentsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                       withString:cleanNodeId];
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
            NSArray *comments = [self commentArrayFromJSONData:responseData error:&conversionError];
            AlfrescoPagingResult *pagingResult = [AlfrescoPagingUtils pagedResultFromArray:comments listingContext:listingContext];
            completionBlock(pagingResult, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)addCommentToNode:(AlfrescoNode *)node content:(NSString *)content
                   title:(NSString *)title completionBlock:(AlfrescoCommentCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:node argumentName:@"node"];
    [AlfrescoErrors assertArgumentNotNil:node.identifier argumentName:@"node.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *nodeString = [AlfrescoObjectConverter nodeRefWithoutVersionID:node.identifier];
    NSString *cleanNodeId = [nodeString stringByReplacingOccurrencesOfString:@"://" withString:@"/"];
    
    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    NSError *error = nil;
    [commentDict setValue:content forKey:kAlfrescoJSONContent];
    [commentDict setValue:cleanNodeId forKey:kAlfrescoJSONNodeRef];
    [commentDict setValue:title forKey:kAlfrescoJSONTitle];
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commentDict options:0 error:&error];
    
    NSString *requestString = [kAlfrescoOnPremiseCommentsAPI stringByReplacingOccurrencesOfString:kAlfrescoNodeRef
                                                                                       withString:cleanNodeId];
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
            AlfrescoComment *comment = [self alfrescoCommentDictFromJSONData:data error:&conversionError];
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
    [AlfrescoErrors assertArgumentNotNil:comment argumentName:@"comment"];
    [AlfrescoErrors assertArgumentNotNil:comment.identifier argumentName:@"comment.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    NSString *commentId = [AlfrescoObjectConverter nodeRefWithoutVersionID:comment.identifier];
    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    [commentDict setValue:content forKey:kAlfrescoJSONContent];
    [commentDict setValue:commentId forKey:kAlfrescoJSONNodeRef];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commentDict options:0 error:&error];
    NSString *requestString = [kAlfrescoOnPremiseCommentForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoCommentId
                                                                                             withString:[commentId stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    
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
            AlfrescoComment *comment = [self alfrescoCommentDictFromJSONData:data error:&conversionError];
            completionBlock(comment, conversionError);
        }
    }];
    return alfrescoRequest;
}

- (AlfrescoRequest *)deleteCommentFromNode:(AlfrescoNode *)node
                      comment:(AlfrescoComment *)comment
              completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:comment argumentName:@"comment"];
    [AlfrescoErrors assertArgumentNotNil:comment.identifier argumentName:@"comment.identifier"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    
    
    NSString *commentId = [AlfrescoObjectConverter nodeRefWithoutVersionID:comment.identifier];
    NSMutableDictionary *commentDict = [NSMutableDictionary dictionary];
    [commentDict setValue:commentId forKey:kAlfrescoJSONNodeRef];
    NSError *error = nil;
    NSData *jsonData = [NSJSONSerialization dataWithJSONObject:commentDict options:0 error:&error];
    NSString *requestString = [kAlfrescoOnPremiseCommentForNodeAPI stringByReplacingOccurrencesOfString:kAlfrescoCommentId
                                                                                             withString:[commentId stringByReplacingOccurrencesOfString:@"://" withString:@"/"]];
    NSURL *url = [AlfrescoURLUtils buildURLFromBaseURLString:self.baseApiUrl extensionURL:requestString];
    AlfrescoRequest *alfrescoRequest = [[AlfrescoRequest alloc] init];
    [self.session.networkProvider executeRequestWithURL:url
                                                session:self.session
                                            requestBody:jsonData
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
- (NSArray *) commentArrayFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
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
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeCommentNoCommentFound];
        return nil;
    }
    if ([[jsonCommentDict valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeCommentNoCommentFound];
        return nil;
    }
    NSArray *jsonCommentArray = [jsonCommentDict valueForKey:kAlfrescoJSONItems];
    NSMutableArray *resultArray = [NSMutableArray arrayWithCapacity:[jsonCommentArray count]];
    for (NSDictionary *commentDict in jsonCommentArray)
    {
        [resultArray addObject:[[AlfrescoComment alloc] initWithProperties:commentDict]];
    }
    return resultArray;
}

- (AlfrescoComment *) alfrescoCommentDictFromJSONData:(NSData *)data error:(NSError *__autoreleasing *)outError
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
    if(error)
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeComment];
        return nil;
    }
    if ([[jsonCommentDict valueForKeyPath:kAlfrescoJSONStatusCode] isEqualToNumber:[NSNumber numberWithInt:404]])
    {
        *outError = [AlfrescoErrors alfrescoErrorWithUnderlyingError:error andAlfrescoErrorCode:kAlfrescoErrorCodeCommentNoCommentFound];
        return nil;
    }
    NSDictionary *jsonComment = [jsonCommentDict valueForKey:kAlfrescoJSONItem];
    return [[AlfrescoComment alloc] initWithProperties:jsonComment];
}

@end
