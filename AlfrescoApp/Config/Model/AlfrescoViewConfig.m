/*
 ******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
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

#import "AlfrescoViewConfig.h"
#import "AlfrescoConfigPropertyConstants.h"
#import "NSDictionary+Extension.h"

@interface AlfrescoViewConfig ()
@property (nonatomic, strong, readwrite) NSString *formIdentifier;
@end

@implementation AlfrescoViewConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super initWithDictionary:properties];
    if (nil != self)
    {
        self.formIdentifier = [properties objectForKeyNotNSNull:kAlfrescoViewConfigPropertyFormIdentifier];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super initWithCoder:aDecoder];
    
    if (self)
    {
        self.formIdentifier = [aDecoder decodeObjectForKey:kAlfrescoViewConfigPropertyFormIdentifier];
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [super encodeWithCoder:aCoder];
    
    [aCoder encodeObject:self.formIdentifier forKey:kAlfrescoViewConfigPropertyFormIdentifier];
}

@end
