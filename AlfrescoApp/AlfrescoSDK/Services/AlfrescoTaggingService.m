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

#import "AlfrescoTaggingService.h"
#import "AlfrescoPlaceholderTaggingService.h"

@implementation AlfrescoTaggingService

+ (id)alloc
{
    if (self == [AlfrescoTaggingService self])
    {
        return [AlfrescoPlaceholderTaggingService alloc];
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

- (AlfrescoRequest *)retrieveAllTagsWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveAllTagsWithListingContext:(AlfrescoListingContext *)listingContext
                                       completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                         completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}
- (AlfrescoRequest *)retrieveTagsForNode:(AlfrescoNode *)node
                          listingContext:(AlfrescoListingContext *)listingContext
                         completionBlock:(AlfrescoPagingResultCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)addTags:(NSArray *)tags
                      toNode:(AlfrescoNode *)node
             completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
