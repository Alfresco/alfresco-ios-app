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

#import "AlfrescoRepositoryCapabilities.h"
#import "AlfrescoInternalConstants.h"

static NSInteger kRepositoryCapabilitiesModelVersion = 1;

@interface AlfrescoRepositoryCapabilities ()
@property (nonatomic, assign, readwrite) BOOL doesSupportLikingNodes;
@property (nonatomic, assign, readwrite) BOOL doesSupportCommentCounts;
@end

@implementation AlfrescoRepositoryCapabilities

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        if (nil != properties)
        {
            self.doesSupportCommentCounts = [[properties valueForKey:kAlfrescoCapabilityCommentsCount] boolValue];
            self.doesSupportLikingNodes = [[properties valueForKey:kAlfrescoCapabilityLike] boolValue];
        }
        else
        {
            self.doesSupportCommentCounts = NO;
            self.doesSupportLikingNodes = NO;
        }
    }
    return self;
}


- (BOOL)doesSupportCapability:(NSString *)capability
{
    if ([capability isEqualToString:kAlfrescoCapabilityLike])
    {
        return self.doesSupportLikingNodes;
    }
    else if ([capability isEqualToString:kAlfrescoCapabilityCommentsCount])
    {
        return self.doesSupportCommentCounts;
    }
    return NO;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kRepositoryCapabilitiesModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeBool:self.doesSupportCommentCounts forKey:kAlfrescoCapabilityCommentsCount];
    [aCoder encodeBool:self.doesSupportLikingNodes forKey:kAlfrescoCapabilityLike];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.doesSupportLikingNodes = [aDecoder decodeBoolForKey:kAlfrescoCapabilityCommentsCount];
        self.doesSupportCommentCounts = [aDecoder decodeBoolForKey:kAlfrescoCapabilityLike];
    }
    return self;
}


@end
