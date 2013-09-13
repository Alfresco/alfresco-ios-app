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

#import "AlfrescoRatingService.h"
#import "AlfrescoPlaceholderActivityStreamService.h"
#import "AlfrescoPlaceholderRatingService.h"

@implementation AlfrescoRatingService

+ (id)alloc
{
    if (self == [AlfrescoRatingService self])
    {
        return [AlfrescoPlaceholderRatingService alloc];
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

- (AlfrescoRequest *)retrieveLikeCountForNode:(AlfrescoNode *)node
                 completionBlock:(AlfrescoNumberCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];    
    return nil;
}


- (AlfrescoRequest *)isNodeLiked:(AlfrescoNode *)node
    completionBlock:(AlfrescoLikedCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];    
    return nil;
}

- (AlfrescoRequest *)likeNode:(AlfrescoNode *)node
 completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];    
    return nil;
}


- (AlfrescoRequest *)unlikeNode:(AlfrescoNode *)node
   completionBlock:(AlfrescoBOOLCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];    
    return nil;
}

@end
