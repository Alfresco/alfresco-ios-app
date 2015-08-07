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

#import "AlfrescoItemConfig.h"
#import "AlfrescoPropertyConstants.h"
#import "CMISDictionaryUtil.h"

@interface AlfrescoItemConfig ()
@property (nonatomic, strong, readwrite) NSString *iconIdentifier;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSDictionary *parameters;
@property (nonatomic, strong, readwrite) NSString *formIdentifier;
@end

@implementation AlfrescoItemConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super initWithDictionary:properties];
    if (nil != self)
    {
        self.iconIdentifier = [properties cmis_objectForKeyNotNull:kAlfrescoItemConfigPropertyIconIdentifier];
        self.type = [properties cmis_objectForKeyNotNull:kAlfrescoItemConfigPropertyType];
        self.parameters = [properties cmis_objectForKeyNotNull:kAlfrescoItemConfigPropertyParameters];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.iconIdentifier = [aDecoder decodeObjectForKey:kAlfrescoItemConfigPropertyIconIdentifier];
        self.type = [aDecoder decodeObjectForKey:kAlfrescoItemConfigPropertyType];
        self.parameters = [aDecoder decodeObjectForKey:kAlfrescoItemConfigPropertyParameters];
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.iconIdentifier forKey:kAlfrescoItemConfigPropertyIconIdentifier];
    [aCoder encodeObject:self.type forKey:kAlfrescoItemConfigPropertyType];
    [aCoder encodeObject:self.parameters forKey:kAlfrescoItemConfigPropertyParameters];
}

- (id)valueForParameterWithKey:(NSString *)key
{
    return self.parameters[key];
}

@end
