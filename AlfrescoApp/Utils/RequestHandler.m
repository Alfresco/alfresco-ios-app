//
//  RequestHandler.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "RequestHandler.h"
#import "Constants.h"

static NSString * const kJSONContentType = @"application/json";
static NSString * const kContentTypeHeaderKey = @"Content-Type";

@interface RequestHandler()
@property (nonatomic, strong) NSURLConnection *connection;
@property (nonatomic, strong) NSMutableData *responseData;
@property (nonatomic, assign) NSInteger statusCode;
@property (nonatomic, copy) AlfrescoDataCompletionBlock completionBlock;
@property (nonatomic, strong, readwrite) NSURL *requestURL;
@end

@implementation RequestHandler

- (void)connectWithURL:(NSURL *)requestURL
                method:(NSString *)method
               headers:(NSDictionary *)headers
           requestBody:(NSData *)requestBody
       completionBlock:(AlfrescoDataCompletionBlock)completionBlock
{
    self.completionBlock = completionBlock;
    self.requestURL = requestURL;
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
    
    self.responseData = nil;
    self.connection = [[NSURLConnection alloc] initWithRequest:urlRequest delegate:self startImmediately:NO];
    [self.connection start];
}

- (void)cancelRequest
{
    if (self.connection)
    {
        [self.connection cancel];
        self.connection = nil;
        
        NSError *cancelError = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeNetworkRequestCancelled];
        self.completionBlock(nil, cancelError);
    }
}

#pragma URL delegate methods

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    self.responseData = [NSMutableData data];
    if ([response isKindOfClass:[NSHTTPURLResponse class]])
    {
        NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
        self.statusCode = httpResponse.statusCode;
    }
    else
    {
        self.statusCode = -1;
    }
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    if (data && data.length > 0 && self.responseData)
    {
        [self.responseData appendData:data];
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSError *error = nil;
    if (self.statusCode < 200 || self.statusCode > 299)
    {
        if (self.statusCode == 401)
        {
            error = [AlfrescoErrors alfrescoErrorWithAlfrescoErrorCode:kAlfrescoErrorCodeUnauthorisedAccess];
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
            self.completionBlock(self.responseData, nil);
        }
    }
    
    self.completionBlock = nil;
    self.connection = nil;
    self.responseData = nil;
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    if (self.completionBlock != NULL)
    {
        self.completionBlock(nil, error);
    }
    self.connection = nil;
}

@end
