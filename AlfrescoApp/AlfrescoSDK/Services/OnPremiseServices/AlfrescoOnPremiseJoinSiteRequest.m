/*
 ******************************************************************************
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
 *****************************************************************************
 */

#import "AlfrescoOnPremiseJoinSiteRequest.h"
#import "AlfrescoInternalConstants.h"

@interface AlfrescoOnPremiseJoinSiteRequest ()
@property (nonatomic, strong, readwrite) NSString *shortName;
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *message;
@end

@implementation AlfrescoOnPremiseJoinSiteRequest

- (id)initWithIdentifier:(NSString *)identifier message:(NSString *)message
{
    self = [super init];
    if (nil != self)
    {
        self.message = message;
        self.identifier = identifier;
        self.shortName  = identifier;
    }
    return self;
}

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self && nil != properties)
    {
        NSArray *allKeys = [properties allKeys];
        if ([allKeys containsObject:kAlfrescoJSONResourceName])
        {
            self.shortName = [properties objectForKey:kAlfrescoJSONResourceName];
        }
        if ([allKeys containsObject:kAlfrescoJSONInviteId])
        {
            self.identifier = [properties objectForKey:kAlfrescoJSONInviteId];
        }
        if ([allKeys containsObject:kAlfrescoJSONInviteeComments])
        {
            self.message = [properties objectForKey:kAlfrescoJSONInviteeComments];
        }        
    }
    return self;
}


#pragma NSCoding methods

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.message forKey:kAlfrescoJSONMessage];
    [aCoder encodeObject:self.identifier forKey:kAlfrescoJSONInviteId];
    [aCoder encodeObject:self.shortName forKey:kAlfrescoJSONResourceName];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.shortName = [aDecoder decodeObjectForKey:kAlfrescoJSONResourceName];
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoJSONInviteId];
        self.message = [aDecoder decodeObjectForKey:kAlfrescoJSONMessage];
    }
    return self;
}

@end
