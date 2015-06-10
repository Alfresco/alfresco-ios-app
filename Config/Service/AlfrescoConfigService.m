/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "AlfrescoConfigService.h"
#import "AlfrescoPlaceholderConfigService.h"

@interface AlfrescoConfigService ()
@property (nonatomic, strong, readwrite) AlfrescoConfigScope *defaultConfigScope;
@end

@implementation AlfrescoConfigService

+ (id)alloc
{
    if (self == [AlfrescoConfigService self])
    {
        return [AlfrescoPlaceholderConfigService alloc];
    }
    return [super alloc];
}

- (instancetype)initWithSession:(id<AlfrescoSession>)session
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithDictionary:(NSDictionary *)parameters
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (void)clear
{
    [self doesNotRecognizeSelector:_cmd];
}

- (AlfrescoRequest *)retrieveConfigInfoWithCompletionBlock:(AlfrescoConfigInfoCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveDefaultProfileWithCompletionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveProfileWithIdentifier:(NSString *)identifier
                                   completionBlock:(AlfrescoProfileConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveProfilesWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveRepositoryConfigWithCompletionBlock:(AlfrescoRepositoryConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveFeatureConfigWithCompletionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFeatureConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                          completionBlock:(AlfrescoArrayCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveFeatureConfigWithIdentifier:(NSString *)identifier
                                                   scope:(AlfrescoConfigScope *)scope
                                         completionBlock:(AlfrescoFeatureConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveViewConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoViewConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveViewGroupConfigWithIdentifier:(NSString *)identifier
                                                     scope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoViewGroupConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveFormConfigWithIdentifier:(NSString *)identifier
                                                scope:(AlfrescoConfigScope *)scope
                                      completionBlock:(AlfrescoFormConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveCreationConfigWithCompletionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}


- (AlfrescoRequest *)retrieveCreationConfigWithConfigScope:(AlfrescoConfigScope *)scope
                                           completionBlock:(AlfrescoCreationConfigCompletionBlock)completionBlock
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

@end
