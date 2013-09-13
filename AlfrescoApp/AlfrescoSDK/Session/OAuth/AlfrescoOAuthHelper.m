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


#import "AlfrescoOAuthHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"
#import "AlfrescoLog.h"

@interface AlfrescoOAuthHelper ()
@property (nonatomic, strong, readwrite) NSURLConnection *connection;
@property (nonatomic, strong, readwrite) NSMutableData *receivedData;
@property (nonatomic, copy, readwrite) AlfrescoOAuthCompletionBlock completionBlock;
@property (nonatomic, strong, readwrite) AlfrescoOAuthData *oauthData;
@property (nonatomic, strong, readwrite) NSString *baseURL;
@property (nonatomic, weak, readwrite) id<AlfrescoOAuthLoginDelegate> oauthDelegate;
@end

@implementation AlfrescoOAuthHelper

- (id)init
{
    return [self initWithParameters:nil delegate:nil];
}

- (id)initWithParameters:(NSDictionary *)parameters
{
    return [self initWithParameters:parameters delegate:nil];
}

- (id)initWithParameters:(NSDictionary *)parameters delegate:(id<AlfrescoOAuthLoginDelegate>)oauthDelegate
{
    self = [super init];
    if (nil != self)
    {
        self.baseURL = [NSString stringWithFormat:@"%@%@", kAlfrescoCloudURL, kAlfrescoOAuthToken];
        if (nil != parameters)
        {
            if ([[parameters allKeys] containsObject:kAlfrescoSessionCloudURL])
            {
                NSString *supplementedURL = [parameters valueForKey:kAlfrescoSessionCloudURL];
                self.baseURL = [NSString stringWithFormat:@"%@%@",supplementedURL,kAlfrescoOAuthToken];
            }
            self.oauthDelegate = oauthDelegate;
        }
        
    }
    return self;
}


- (void)retrieveOAuthDataForAuthorizationCode:(NSString *)authorizationCode
                                    oauthData:(AlfrescoOAuthData *)oauthData
                              completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:authorizationCode argumentName:@"authorizationCode"];
    [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    self.completionBlock = completionBlock;
    self.oauthData = oauthData;
    self.receivedData = nil;
    AlfrescoLogDebug(@"URL used is %@", self.baseURL);
    NSURL *url = [NSURL URLWithString:self.baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 60];
    
    [request setHTTPMethod:@"POST"];
    
    NSMutableString *contentString = [NSMutableString string];
    NSString *codeID   = [kAlfrescoOAuthCode stringByReplacingOccurrencesOfString:kAlfrescoCode withString:authorizationCode];
    NSString *clientID = [kAlfrescoOAuthClientID stringByReplacingOccurrencesOfString:kAlfrescoClientID withString:self.oauthData.apiKey];
    NSString *secretID = [kAlfrescoOAuthClientSecret stringByReplacingOccurrencesOfString:kAlfrescoClientSecret withString:self.oauthData.secretKey];
    NSString *redirect = [kAlfrescoOAuthRedirectURI stringByReplacingOccurrencesOfString:kAlfrescoRedirectURI withString:self.oauthData.redirectURI];
    
    [contentString appendString:codeID];
    [contentString appendString:@"&"];
    [contentString appendString:clientID];
    [contentString appendString:@"&"];
    [contentString appendString:secretID];
    [contentString appendString:@"&"];
    [contentString appendString:kAlfrescoOAuthGrantType];
    [contentString appendString:@"&"];
    [contentString appendString:redirect];
    AlfrescoLogDebug(@"body is %@", contentString);
    
    NSData *data = [contentString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
}


- (void)refreshAccessToken:(AlfrescoOAuthData *)oauthData
           completionBlock:(AlfrescoOAuthCompletionBlock)completionBlock
{
    [AlfrescoErrors assertArgumentNotNil:oauthData argumentName:@"oauthData"];
    [AlfrescoErrors assertArgumentNotNil:completionBlock argumentName:@"completionBlock"];
    self.completionBlock = completionBlock;
    self.oauthData = oauthData;
    NSURL *url = [NSURL URLWithString:self.baseURL];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL: url
                                                           cachePolicy: NSURLRequestReloadIgnoringCacheData
                                                       timeoutInterval: 60];
    
    [request setHTTPMethod:@"POST"];
    
    // add the access token header
    NSString *authHeader = [NSString stringWithFormat:@"%@ %@",self.oauthData.tokenType, self.oauthData.accessToken];
    AlfrescoLogDebug(@"URL is: %@ auth header is %@", self.baseURL, authHeader);
    [request addValue:authHeader forHTTPHeaderField:@"Authorization"];
    
    NSMutableString *contentString = [NSMutableString string];
    NSString *refreshID = [kAlfrescoOAuthRefreshToken stringByReplacingOccurrencesOfString:kAlfrescoRefreshID withString:self.oauthData.refreshToken];
    NSString *clientID  = [kAlfrescoOAuthClientID stringByReplacingOccurrencesOfString:kAlfrescoClientID withString:self.oauthData.apiKey];
    NSString *secretID  = [kAlfrescoOAuthClientSecret stringByReplacingOccurrencesOfString:kAlfrescoClientSecret withString:self.oauthData.secretKey];
    
    [contentString appendString:refreshID];
    [contentString appendString:@"&"];
    [contentString appendString:clientID];
    [contentString appendString:@"&"];
    [contentString appendString:secretID];
    [contentString appendString:@"&"];
    [contentString appendString:kAlfrescoOAuthGrantTypeRefresh];
    AlfrescoLogDebug(@"body is %@", contentString);
    
    NSData *data = [contentString dataUsingEncoding:NSUTF8StringEncoding];
    [request setHTTPBody:data];
    
    self.connection = [NSURLConnection connectionWithRequest:request delegate:self];
    
}


#pragma NSURLConnection Delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (nil != data && data.length > 0)
    {
        if (nil == self.receivedData)
        {
            self.receivedData = [NSMutableData data];
        }
        
        NSError *error = nil;
        id jsonObj = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
        if (nil != jsonObj)
        {
            if ([jsonObj isKindOfClass:[NSDictionary class]])
            {
                [self.receivedData appendBytes:[data bytes] length:data.length];
            }
            
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    AlfrescoOAuthData *updatedOAuthData = [self updatedOAuthDataFromJSONWithError:&error];
    if (nil == updatedOAuthData)
    {
        if (nil != self.oauthDelegate)
        {
            if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
            {
                [self.oauthDelegate oauthLoginDidFailWithError:error];
            }
        }
    }
    self.completionBlock(updatedOAuthData, error);
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    AlfrescoLogError(@"Error is %@ and code is %d", [error localizedDescription], [error code]);
    
    if (nil != self.oauthDelegate)
    {
        if ([self.oauthDelegate respondsToSelector:@selector(oauthLoginDidFailWithError:)])
        {
            [self.oauthDelegate oauthLoginDidFailWithError:error];
        }
    }
    
    if (nil == self.receivedData)
    {
        self.completionBlock(nil, error);
        return;
    }
    if (0 == self.receivedData.length)
    {
        self.completionBlock(nil, error);
        return;
    }
    else
    {
        NSError *error = nil;
        AlfrescoOAuthData *updatedOAuthData = [self updatedOAuthDataFromJSONWithError:&error];
        self.completionBlock(updatedOAuthData, error);        
    }

}

#pragma private methods

- (AlfrescoOAuthData *)updatedOAuthDataFromJSONWithError:(NSError **)error
{
    if (nil == self.receivedData)
    {
        if (nil == *error)
        {
            *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *internalError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *error = [AlfrescoErrors alfrescoErrorWithUnderlyingError:internalError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
    if (0 == self.receivedData.length)
    {
        if (nil == *error)
        {
            *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        else
        {
            NSError *internalError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
            *error = [AlfrescoErrors alfrescoErrorWithUnderlyingError:internalError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        }
        return nil;
    }
        
    NSError *jsonError = nil;
    id jsonDictionary = [NSJSONSerialization JSONObjectWithData:self.receivedData options:0 error:&jsonError];
    if (nil == jsonDictionary)
    {
        *error = [AlfrescoErrors alfrescoErrorWithUnderlyingError:jsonError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsingNilData];
        return nil;
    }
    
    if (![jsonDictionary isKindOfClass:[NSDictionary class]])
    {
        if (nil == *error)
        {
            *error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
            *error = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    
    if ([[jsonDictionary allKeys] containsObject:kAlfrescoJSONError])
    {
        if (nil == *error)
        {
            *error = [AlfrescoErrors alfrescoErrorFromJSONParameters:jsonDictionary];
        }
        else
        {
            NSError *underlyingError = [AlfrescoErrors alfrescoErrorFromJSONParameters:jsonDictionary];
            *error = [AlfrescoErrors alfrescoErrorWithUnderlyingError:underlyingError andAlfrescoErrorCode:kAlfrescoErrorCodeJSONParsing];
        }
        return nil;
    }
    
    AlfrescoOAuthData *updatedOAuthData = [[AlfrescoOAuthData alloc] initWithAPIKey:self.oauthData.apiKey
                                                                          secretKey:self.oauthData.secretKey
                                                                        redirectURI:self.oauthData.redirectURI
                                                                     jsonDictionary:(NSDictionary *)jsonDictionary];
    
    return updatedOAuthData;
}

@end
