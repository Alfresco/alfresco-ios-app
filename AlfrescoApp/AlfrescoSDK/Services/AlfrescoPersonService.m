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

#import "AlfrescoPersonService.h"
#import "AlfrescoPlaceholderPersonService.h"

@implementation AlfrescoPersonService
+ (id)alloc
{
    if (self == [AlfrescoPersonService self])
    {
        return [AlfrescoPlaceholderPersonService alloc];
    }
    else
    {
        return [super alloc];
    }
}
- (id)initWithSession:(id<AlfrescoSession>)session
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrievePersonWithIdentifier:(NSString *)identifier completionBlock:(AlfrescoPersonCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveAvatarForPerson:(AlfrescoPerson *)person completionBlock:(AlfrescoContentFileCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)updateProfile:(NSDictionary *)properties completionBlock:(AlfrescoPersonCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)search:(NSString *)filter completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)search:(NSString *)filter
         WithListingContext:(AlfrescoListingContext *)listingContext
            completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)refreshPerson:(AlfrescoPerson *)person
                   completionBlock:(AlfrescoPersonCompletionBlock)completionBlock
{
    AlfrescoRequest *request = [self retrievePersonWithIdentifier:person.identifier completionBlock:^(AlfrescoPerson *person, NSError *error) {
        
        completionBlock(person, error);
    }];
    return request;
}

@end
