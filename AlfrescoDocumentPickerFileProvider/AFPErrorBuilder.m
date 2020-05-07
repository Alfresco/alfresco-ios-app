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

#import "AFPErrorBuilder.h"
#import <FileProvider/FileProvider.h>
#import "AFPAccountManager.h"

@implementation AFPErrorBuilder

+ (NSError *)authenticationError
{
    NSError *error = nil;
    if (@available(iOS 11.0, *))
    {
        error = [NSError errorWithDomain:NSFileProviderErrorDomain
                                    code:NSFileProviderErrorNotAuthenticated
                                userInfo:nil];
    }
    
    return error;
}

+ (NSError *)authenticationErrorForPIN {
    if ([AFPAccountManager isPINAuthenticationSet]) {
        return [self authenticationError];
    }
    
    return nil;
}

+ (NSError *)fileProviderErrorForGenericError:(NSError *)error
{
    if ([kAlfrescoErrorDomainName isEqualToString:error.domain])
    {
        if (kAlfrescoErrorCodeUnauthorisedAccess == error.code)
        {
            return [self authenticationError];
        }
    }
    
    return error;
}

@end
