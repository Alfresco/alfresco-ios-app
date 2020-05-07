/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
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
 
#import "RequestHandler.h"
#import "Constants.h"
#import "ConnectivityManager.h"

static NSString * const kJSONContentType = @"application/json";
static NSString * const kContentTypeHeaderKey = @"Content-Type";

@interface RequestHandler()
@property (nonatomic, strong) NSURLSessionDataTask *urlSessionDataTask;
@property (nonatomic, copy) AlfrescoDataCompletionBlock completionBlock;
@end

@implementation RequestHandler

- (void)connectWithURL:(NSURL *)requestURL
                method:(NSString *)method
               headers:(NSDictionary *)headers
           requestBody:(NSData *)requestBody
       completionBlock:(AlfrescoDataCompletionBlock)completionBlock
{
    self.completionBlock = completionBlock;
    AlfrescoLogDebug(@"%@ %@", method, requestURL);
    
    NSMutableURLRequest *urlRequest = [NSMutableURLRequest requestWithURL:requestURL
                                                              cachePolicy:NSURLRequestReloadIgnoringCacheData
                                                          timeoutInterval:kRequestTimeOutInterval];
    [urlRequest setHTTPMethod:method];
    
    [headers enumerateKeysAndObjectsUsingBlock:^(NSString *headerKey, NSString *headerValue, BOOL *stop) {
        [urlRequest addValue:headerValue forHTTPHeaderField:headerKey];
    }];
    
    if (nil != requestBody)
    {
        [urlRequest setHTTPBody:requestBody];
        [urlRequest addValue:kJSONContentType forHTTPHeaderField:kContentTypeHeaderKey];
    }
    
    void (^processResponse)(NSURLResponse *, NSData *) = ^(NSURLResponse *response, NSData *responseData) {
        NSInteger statusCode;
        
        if ([response isKindOfClass:[NSHTTPURLResponse class]])
        {
            NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
            statusCode = httpResponse.statusCode;
        }
        else
        {
            statusCode = -1;
        }
        
        NSError *error = nil;
        if (statusCode < 200 || statusCode > 299)
        {
            if (statusCode == 401)
            {
                error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeUnauthorisedAccess];
            }
            else if (statusCode == 404)
            {
                error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeRequestedNodeNotFound];
            }
            else
            {
                error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeHTTPResponse];
            }
        }
        
        if (self.completionBlock != NULL)
        {
            if (error)
            {
                self.completionBlock(nil, error);
            }
            else
            {
                self.completionBlock(responseData, nil);
            }
        }
        
        self.completionBlock = nil;
        self.urlSessionDataTask = nil;
    };
    
    NSURLSession *urlSession = [NSURLSession sessionWithConfiguration:[NSURLSessionConfiguration defaultSessionConfiguration] delegate:nil delegateQueue:nil];
    self.urlSessionDataTask = [urlSession dataTaskWithRequest:urlRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error)
        {
            if (self.completionBlock != NULL)
            {
                self.completionBlock(nil, error);
            }
        }
        else
        {
            processResponse(response, data);
        }
    }];
    
    if ([[ConnectivityManager sharedManager] hasInternetConnection])
    {
        [self.urlSessionDataTask resume];
    }
    else if (self.completionBlock != NULL)
    {
        NSError *noConnectionError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNoNetworkConnection];
        self.completionBlock(nil, noConnectionError);
    }
}

- (void)cancelRequest
{
    if (self.urlSessionDataTask)
    {
        [self.urlSessionDataTask cancel];
        self.urlSessionDataTask = nil;
        
        NSError *cancelError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
        self.completionBlock(nil, cancelError);
    }
}

@end
