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

#import "AlfrescoActivityEntry.h"
#import "AlfrescoInternalConstants.h"
#import "CMISDateUtil.h"

static NSUInteger kActivityModelVersion = 1;

@interface AlfrescoActivityEntry ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) NSString *createdBy;
@property (nonatomic, strong, readwrite) NSString *siteShortName;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSDictionary *data;
@end

@implementation AlfrescoActivityEntry

/**
 Cloud and OnPremise sessions have slightly different JSON response types
 Cloud: postedAt OnPremise: postDate
 Cloud: postPersonID OnPremise: postUserId
 Cloud: siteId OnPremise: siteNetwork
 */

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self && nil != properties)
    {
        if ([[properties allKeys] containsObject:kAlfrescoJSONIdentifier])
        {
            self.identifier = [properties valueForKey:kAlfrescoJSONIdentifier];
        }
        if ([[properties allKeys] containsObject:kAlfrescoJSONActivityType])
        {
            self.type = [properties valueForKey:kAlfrescoJSONActivityType];
        }
        if ([[properties allKeys] containsObject:kAlfrescoJSONActivitySummary])
        {
            id summary = [properties valueForKey:kAlfrescoJSONActivitySummary];
            if ([summary isKindOfClass:[NSDictionary class]])
            {
                self.data = (NSDictionary *)summary;
            }
            else
            {
                NSError *error = nil;
                self.data = [NSJSONSerialization JSONObjectWithData:[[properties valueForKey:kAlfrescoJSONActivitySummary]
                                                                     dataUsingEncoding:NSUTF8StringEncoding]
                                                            options:0 error:&error];
            }
        }

        [self setOnPremiseProperties:properties];
        [self setCloudProperties:properties];        
    }
    return self;
}

- (void)setOnPremiseProperties:(NSDictionary *)properties
{
    //OnPremise Response
    if ([[properties allKeys] containsObject:kAlfrescoJSONActivityPostUserID])
    {
        self.createdBy = [properties valueForKey:kAlfrescoJSONActivityPostUserID];
    }
    //On Premise Response
    if ([[properties allKeys] containsObject:kAlfrescoJSONActivityPostDate])
    {
        NSString *rawDateString = [properties valueForKey:kAlfrescoJSONActivityPostDate];
        if (nil != rawDateString)
        {
            self.createdAt = [CMISDateUtil dateFromString:rawDateString];
        }
    }
    //On Premise Response
    if ([[properties allKeys] containsObject:kAlfrescoJSONActivitySiteNetwork])
    {
        self.siteShortName = [properties valueForKey:kAlfrescoJSONActivitySiteNetwork];
    }
    
}
- (void)setCloudProperties:(NSDictionary *)properties
{
    //Cloud Response - Activity Person/User Id
    if ([[properties allKeys] containsObject:kAlfrescoJSONActivityPostPersonID])
    {
        self.createdBy = [properties valueForKey:kAlfrescoJSONActivityPostPersonID];
    }
    
    //Cloud Response - Activity Posting date
    if ([[properties allKeys] containsObject:kAlfrescoJSONPostedAt])
    {
        NSString *rawDateString = [properties valueForKey:kAlfrescoJSONPostedAt];
        if (nil != rawDateString)
        {
            self.createdAt = [CMISDateUtil dateFromString:rawDateString];
        }
    }
    //Cloud Response - Activity Network/Site Id
    if ([[properties allKeys] containsObject:kAlfrescoJSONSiteID])
    {
        self.siteShortName = [properties valueForKey:kAlfrescoJSONSiteID];
    }
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kActivityModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.createdAt forKey:kAlfrescoJSONActivityPostDate];
    [aCoder encodeObject:self.identifier forKey:kAlfrescoJSONIdentifier];
    [aCoder encodeObject:self.type forKey:kAlfrescoJSONActivityType];
    [aCoder encodeObject:self.data forKey:kAlfrescoJSONActivitySummary];
    [aCoder encodeObject:self.createdBy forKey:kAlfrescoJSONActivityPostPersonID];
    [aCoder encodeObject:self.siteShortName forKey:kAlfrescoJSONSiteID];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.createdBy = [aDecoder decodeObjectForKey:kAlfrescoJSONActivityPostPersonID];
        self.createdAt = [aDecoder decodeObjectForKey:kAlfrescoJSONActivityPostDate];
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoJSONIdentifier];
        self.type = [aDecoder decodeObjectForKey:kAlfrescoJSONActivityType];
        self.data = [aDecoder decodeObjectForKey:kAlfrescoJSONActivitySummary];
        self.siteShortName = [aDecoder decodeObjectForKey:kAlfrescoJSONSiteID];
    }
    return self;
}

@end
