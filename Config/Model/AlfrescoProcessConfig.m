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

#import "AlfrescoProcessConfig.h"
#import "AlfrescopropertyConstants.h"

@interface AlfrescoProcessConfig ()
@property (nonatomic, assign, readwrite) BOOL isVisible;
@end

@implementation AlfrescoProcessConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super initWithDictionary:properties];
    if (nil != self)
    {
        self.isVisible = [properties[kAlfrescoProcessConfigPropertyIsVisible] boolValue];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.isVisible = [aDecoder decodeBoolForKey:kAlfrescoProcessConfigPropertyIsVisible];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeBool:self.isVisible forKey:kAlfrescoProcessConfigPropertyIsVisible];
}

@end
