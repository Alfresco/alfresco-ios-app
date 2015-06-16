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

#import "AlfrescoRepositoryConfig.h"
#import "AlfrescoPropertyConstants.h"

@interface AlfrescoRepositoryConfig ()
@property (nonatomic, strong, readwrite) NSURL *shareURL;
@property (nonatomic, strong, readwrite) NSURL *cmisURL;
@end

@implementation AlfrescoRepositoryConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        id shareURLObject = properties[kAlfrescoRepositoryConfigPropertyShareURL];
        if ([shareURLObject isKindOfClass:[NSURL class]])
        {
            self.shareURL = shareURLObject;
        }
        else if ([shareURLObject isKindOfClass:[NSString class]])
        {
            self.shareURL = [NSURL URLWithString:(NSString *)shareURLObject];
        }
        
        id cmisURLObject = properties[kAlfrescoRepositoryConfigPropertyCMISURL];
        if ([cmisURLObject isKindOfClass:[NSURL class]])
        {
            self.cmisURL = cmisURLObject;
        }
        else if ([cmisURLObject isKindOfClass:[NSString class]])
        {
            self.cmisURL = [NSURL URLWithString:(NSString *)cmisURLObject];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.shareURL = [aDecoder decodeObjectForKey:kAlfrescoRepositoryConfigPropertyShareURL];
        self.cmisURL = [aDecoder decodeObjectForKey:kAlfrescoRepositoryConfigPropertyCMISURL];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.shareURL forKey:kAlfrescoRepositoryConfigPropertyShareURL];
    [aCoder encodeObject:self.cmisURL forKey:kAlfrescoRepositoryConfigPropertyCMISURL];
}

@end
