/*
 ******************************************************************************
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
 *****************************************************************************
 */

/**
 The AlfrescoUntrustedSSLHTTPRequest class utilizes NSURLConnection to make requests.
 It allows SSL connections to be made when the certificate is not trusted.
 
 Author: Mike Hatfield (Alfresco)
 */

#import "AlfrescoUntrustedSSLHTTPRequest.h"

@implementation AlfrescoUntrustedSSLHTTPRequest

/**
 * Untrusted SSL connection support
 */
- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge
{
    if (challenge.previousFailureCount == 0 && [challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust])
    {
        if ([self.requestURL.host isEqualToString:challenge.protectionSpace.host])
        {
            [challenge.sender useCredential:[NSURLCredential credentialForTrust:challenge.protectionSpace.serverTrust] forAuthenticationChallenge:challenge];
            return;
        }
    }
    [challenge.sender cancelAuthenticationChallenge:challenge];
}

@end
