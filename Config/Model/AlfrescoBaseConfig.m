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

#import "AlfrescoBaseConfig.h"
#import "AlfrescoPropertyConstants.h"
#import "CMISDictionaryUtil.h"

@interface AlfrescoBaseConfig ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *label;
@property (nonatomic, strong, readwrite) NSString *summary;
@end

@implementation AlfrescoBaseConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        self.identifier = [properties cmis_objectForKeyNotNull:kAlfrescoBaseConfigPropertyIdentifier];
        self.label = [properties cmis_objectForKeyNotNull:kAlfrescoBaseConfigPropertyLabel];
        self.summary = [properties cmis_objectForKeyNotNull:kAlfrescoBaseConfigPropertySummary];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoBaseConfigPropertyIdentifier];
        self.label = [aDecoder decodeObjectForKey:kAlfrescoBaseConfigPropertyLabel];
        self.summary = [aDecoder decodeObjectForKey:kAlfrescoBaseConfigPropertySummary];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.identifier forKey:kAlfrescoBaseConfigPropertyIdentifier];
    [aCoder encodeObject:self.label forKey:kAlfrescoBaseConfigPropertyLabel];
    [aCoder encodeObject:self.summary forKey:kAlfrescoBaseConfigPropertySummary];
}

@end
