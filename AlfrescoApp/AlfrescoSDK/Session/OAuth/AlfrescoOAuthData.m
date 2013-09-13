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

#import "AlfrescoOAuthData.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"

@interface AlfrescoOAuthData ()
@property (nonatomic, strong, readwrite) NSString           * accessToken;
@property (nonatomic, strong, readwrite) NSString           * refreshToken;
@property (nonatomic, strong, readwrite) NSNumber           * expiresIn;
@property (nonatomic, strong, readwrite) NSString           * tokenType;
@property (nonatomic, strong, readwrite) NSString           * scope;
@property (nonatomic, strong, readwrite) NSString           * apiKey;
@property (nonatomic, strong, readwrite) NSString           * secretKey;
@property (nonatomic, strong, readwrite) NSString           * redirectURI;
@end

@implementation AlfrescoOAuthData

- (id)initWithAPIKey:(NSString *)apiKey secretKey:(NSString *)secretKey
{
    return [self initWithAPIKey:apiKey secretKey:secretKey redirectURI:kAlfrescoCloudDefaultRedirectURI jsonDictionary:nil];
}

- (id)initWithAPIKey:(NSString *)apiKey secretKey:(NSString *)secretKey redirectURI:(NSString *)redirectURI
{
    return [self initWithAPIKey:apiKey secretKey:secretKey redirectURI:redirectURI jsonDictionary:nil];
}

- (id)initWithAPIKey:(NSString *)apiKey secretKey:(NSString *)secretKey jsonDictionary:(NSDictionary *)jsonDictionary
{
    return [self initWithAPIKey:apiKey secretKey:secretKey redirectURI:kAlfrescoCloudDefaultRedirectURI jsonDictionary:jsonDictionary];    
}

- (id)initWithAPIKey:(NSString *)apiKey secretKey:(NSString *)secretKey redirectURI:(NSString *)redirectURI jsonDictionary:(NSDictionary *)jsonDictionary
{
    self = [super init];
    if (nil != self)
    {
        self.apiKey = apiKey;
        self.secretKey = secretKey;
        self.redirectURI = redirectURI;
        self.accessToken = nil;
        self.refreshToken = nil;
        self.expiresIn = nil;
        self.tokenType = nil;
        self.scope = nil;
        if (nil != jsonDictionary)
        {
            self.accessToken    = [jsonDictionary valueForKey:kAlfrescoJSONAccessToken];
            self.refreshToken   = [jsonDictionary valueForKey:kAlfrescoJSONRefreshToken];
            self.expiresIn      = [jsonDictionary valueForKey:kAlfrescoJSONExpiresIn];
            self.scope          = [jsonDictionary valueForKey:kAlfrescoJSONScope];
            self.tokenType      = [jsonDictionary valueForKey:kAlfrescoJSONTokenType];
            
        }
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    if (nil != self.apiKey)
    {
        [aCoder encodeObject:self.apiKey forKey:@"apiKey"];
    }
    if (nil != self.secretKey)
    {
        [aCoder encodeObject:self.secretKey forKey:@"secretKey"];
    }
    if (nil != self.accessToken)
    {
        [aCoder encodeObject:self.accessToken forKey:@"accessToken"];
    }
    if (nil != self.refreshToken)
    {
        [aCoder encodeObject:self.refreshToken forKey:@"refreshToken"];
    }
    if (nil != self.expiresIn)
    {
        [aCoder encodeObject:self.expiresIn forKey:@"expiresIn"];
    }
    if (nil != self.tokenType)
    {
        [aCoder encodeObject:self.tokenType forKey:@"tokenType"];
    }
    if (nil != self.redirectURI)
    {
        [aCoder encodeObject:self.redirectURI forKey:@"redirectURI"];
    }
    if (nil != self.scope)
    {
        [aCoder encodeObject:self.scope forKey:@"scope"];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    NSString *apiKey = [aDecoder decodeObjectForKey:@"apiKey"];
    NSString *secretKey = [aDecoder decodeObjectForKey:@"secretKey"];
    NSString *redirectURI = [aDecoder decodeObjectForKey:@"redirectURI"];
    
    NSString *accessToken = [aDecoder decodeObjectForKey:@"accessToken"];
    NSString *refreshToken = [aDecoder decodeObjectForKey:@"refreshToken"];
    NSNumber *expiresIn = [aDecoder decodeObjectForKey:@"expiresIn"];
    NSString *tokenType = [aDecoder decodeObjectForKey:@"tokenType"];
    NSString *scope = [aDecoder decodeObjectForKey:@"scope"];
    
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    if (nil != accessToken)
    {
        [dictionary setObject:accessToken forKey:kAlfrescoJSONAccessToken];
    }
    if (nil != refreshToken)
    {
        [dictionary setObject:refreshToken forKey:kAlfrescoJSONRefreshToken];
    }
    if (nil != expiresIn)
    {
        [dictionary setObject:expiresIn forKey:kAlfrescoJSONExpiresIn];
    }
    if (nil != tokenType)
    {
        [dictionary setObject:tokenType forKey:kAlfrescoJSONTokenType];
    }
    if (nil != scope)
    {
        [dictionary setObject:scope forKey:kAlfrescoJSONScope];
    }
    
    if (0 < dictionary.count)
    {
        return [self initWithAPIKey:apiKey secretKey:secretKey redirectURI:redirectURI jsonDictionary:dictionary];
    }
    else
    {
        return [self initWithAPIKey:apiKey secretKey:secretKey redirectURI:redirectURI];
    }    
}

@end
