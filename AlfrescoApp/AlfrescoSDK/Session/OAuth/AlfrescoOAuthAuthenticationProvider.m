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

#import "AlfrescoOAuthAuthenticationProvider.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoErrors.h"

@interface AlfrescoOAuthAuthenticationProvider ()
@property (nonatomic, strong, readwrite) NSMutableDictionary *httpHeaders;
@property (nonatomic, strong, readwrite) AlfrescoOAuthData *oauthData;
@end

@implementation AlfrescoOAuthAuthenticationProvider


- (id)initWithOAuthData:(AlfrescoOAuthData *)oauthData
{
    self = [super init];
    if (nil != self)
    {
        self.oauthData = oauthData;
    }
    return self;
}





#pragma AlfrescoAuthenticationProvider method

- (NSDictionary *)willApplyHTTPHeadersForSession:(id<AlfrescoSession>)session
{
    if (nil == self.httpHeaders)
    {
        self.httpHeaders = [NSMutableDictionary dictionary];
        NSString *authHeader = [NSString stringWithFormat:@"%@ %@",self.oauthData.tokenType ,self.oauthData.accessToken];
        [self.httpHeaders setValue:authHeader forKey:@"Authorization"];
    }
    return self.httpHeaders;
}





@end
