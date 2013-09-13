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

#import "AlfrescoTag.h"
#import "AlfrescoInternalConstants.h"

static NSInteger kTagModelVersion = 1;

@interface AlfrescoTag ()
@property (nonatomic, strong, readwrite) NSString * identifier;
@property (nonatomic, strong, readwrite) NSString * value;
@end

@implementation AlfrescoTag

/* OnPremise
 - (AlfrescoTag *)tagFromJSON:(NSString *)jsonString
 {
 AlfrescoTag *tag = [[AlfrescoTag alloc] init];
 tag.identifier = jsonString;
 tag.value = jsonString;
 return tag;
 }
*/

/*
 - (AlfrescoTag *)tagFromJSON:(NSDictionary *)jsonDict
 {
 AlfrescoTag *tag = [[AlfrescoTag alloc]init];
 tag.value = [jsonDict valueForKey:kAlfrescoJSONTag];
 tag.identifier = [jsonDict valueForKey:kAlfrescoJSONIdentifier];
 return tag;
 }
 */

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        [self setUpCloudProperties:properties];
        [self setUpOnPremiseProperties:properties];
    }
    return self;
}

- (void)setUpOnPremiseProperties:(NSDictionary *)properties
{
    if ([[properties allKeys] containsObject:kAlfrescoJSONTag])
    {
        self.identifier = [properties valueForKey:kAlfrescoJSONTag];
        NSString *valueString = [properties valueForKey:kAlfrescoJSONTag];
        self.value = [valueString stringByReplacingOccurrencesOfString:@"\"" withString:@""];
    }
    
    
}

- (void)setUpCloudProperties:(NSDictionary *)properties
{
    if ([[properties allKeys] containsObject:kAlfrescoJSONIdentifier])
    {
        self.identifier = [properties valueForKey:kAlfrescoJSONIdentifier];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONTag])
    {
        self.value = [properties valueForKey:kAlfrescoJSONTag];
    }
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kTagModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.value forKey:kAlfrescoJSONTag];
    [aCoder encodeObject:self.identifier forKey:kAlfrescoJSONIdentifier];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.value = [aDecoder decodeObjectForKey:kAlfrescoJSONTag];
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoJSONIdentifier];
    }
    return self;
}


@end
