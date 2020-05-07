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

#import "AlfrescoConfigInfo.h"
#import "AlfrescoConfigPropertyConstants.h"

@interface AlfrescoConfigInfo ()
@property (nonatomic, strong, readwrite) NSString *schemaVersion;
@end

@implementation AlfrescoConfigInfo

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        id schemaVersionObject = properties[kAlfrescoConfigInfoPropertySchemaVersion];
        if ([schemaVersionObject isKindOfClass:[NSString class]])
        {
            self.schemaVersion = schemaVersionObject;
        }
        else if ([schemaVersionObject isKindOfClass:[NSNumber class]])
        {
            self.schemaVersion = [schemaVersionObject stringValue];
        }
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.schemaVersion = [aDecoder decodeObjectForKey:kAlfrescoConfigInfoPropertySchemaVersion];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.schemaVersion forKey:kAlfrescoConfigInfoPropertySchemaVersion];
}

@end
