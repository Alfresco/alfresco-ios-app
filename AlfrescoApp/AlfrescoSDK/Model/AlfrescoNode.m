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

#import "AlfrescoNode.h"
#import "AlfrescoProperty.h"
#import "AlfrescoInternalConstants.h"
#import "CMISObject.h"
#import "CMISDocument.h"
#import "CMISSession.h"
#import "CMISQueryResult.h"
#import "CMISObjectConverter.h"
#import "CMISEnums.h"
#import "CMISConstants.h"
#import "CMISQueryResult.h"


static NSInteger kNodeModelVersion = 1;
NSString * const kAlfrescoPermissionsObjectKey = @"AlfrescoPermissionsObjectKey";

@interface AlfrescoNode ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSString *summary;
@property (nonatomic, strong, readwrite) NSString *type;
@property (nonatomic, strong, readwrite) NSString *createdBy;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) NSString *modifiedBy;
@property (nonatomic, strong, readwrite) NSDate *modifiedAt;
@property (nonatomic, strong, readwrite) NSDictionary *properties;
@property (nonatomic, strong, readwrite) NSArray *aspects;
@property (nonatomic, assign, readwrite) BOOL isFolder;
@property (nonatomic, assign, readwrite) BOOL isDocument;
@end


@implementation AlfrescoNode


- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        self.identifier = nil;
        self.name = nil;
        self.title = nil;
        self.summary = nil;
        self.type = nil;
        self.createdAt = nil;
        self.createdBy = nil;
        self.modifiedAt = nil;
        self.modifiedBy = nil;
        self.properties = nil;
        self.aspects = nil;
        [self setUpProperties:properties];
    }
    return self;
}

- (void)setUpProperties:(NSDictionary *)properties
{
    if ([[properties allKeys] containsObject:kCMISPropertyObjectId])
    {
        self.identifier = [properties valueForKey:kCMISPropertyObjectId];
    }
    if ([[properties allKeys] containsObject:kCMISPropertyName])
    {
        self.name = [properties valueForKey:kCMISPropertyName];
    }
    if ([[properties allKeys] containsObject:kCMISPropertyObjectTypeId])
    {
        self.type = [properties valueForKey:kCMISPropertyObjectTypeId];
    }
    if ([[properties allKeys] containsObject:kCMISPropertyCreatedBy])
    {
        self.createdBy = [properties valueForKey:kCMISPropertyCreatedBy];
    }
    if ([[properties allKeys] containsObject:kCMISPropertyCreationDate])
    {
        self.createdAt = [properties valueForKey:kCMISPropertyCreationDate];
    }
    
    if ([[properties allKeys] containsObject:kCMISPropertyModifiedBy])
    {
        self.modifiedBy = [properties valueForKey:kCMISPropertyModifiedBy];
    }
    if ([[properties allKeys] containsObject:kCMISPropertyModificationDate])
    {
        self.modifiedAt = [properties valueForKey:kCMISPropertyModificationDate];
    }
    
    if ([[properties allKeys] containsObject:kAlfrescoPropertyTitle])
    {
        self.title = [properties valueForKey:kAlfrescoPropertyTitle];
    }
    if ([[properties allKeys] containsObject:kAlfrescoPropertyDescription])
    {
        self.summary = [properties valueForKey:kAlfrescoPropertyDescription];
    }
    if ([[properties allKeys] containsObject:kAlfrescoNodeAspects])
    {
        self.aspects = [properties valueForKey:kAlfrescoNodeAspects];
    }
    if ([[properties allKeys] containsObject:kAlfrescoNodeProperties])
    {
        self.properties = [properties valueForKey:kAlfrescoNodeProperties];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kNodeModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.identifier forKey:kCMISPropertyObjectId];
    [aCoder encodeObject:self.name forKey:kCMISPropertyName];
    [aCoder encodeObject:self.title forKey:kAlfrescoPropertyTitle];
    [aCoder encodeObject:self.summary forKey:kAlfrescoPropertyDescription];
    [aCoder encodeObject:self.type forKey:kCMISPropertyObjectTypeId];
    [aCoder encodeObject:self.createdAt forKey:kCMISPropertyCreationDate];
    [aCoder encodeObject:self.createdBy forKey:kCMISPropertyCreatedBy];
    [aCoder encodeObject:self.modifiedBy forKey:kCMISPropertyModifiedBy];
    [aCoder encodeObject:self.modifiedAt forKey:kCMISPropertyModificationDate];
    [aCoder encodeObject:self.properties forKey:kAlfrescoNodeProperties];
    [aCoder encodeObject:self.aspects forKey:kAlfrescoNodeAspects];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.identifier = [aDecoder decodeObjectForKey:kCMISPropertyObjectId];
        self.name = [aDecoder decodeObjectForKey:kCMISPropertyName];
        self.title = [aDecoder decodeObjectForKey:kAlfrescoPropertyTitle];
        self.summary = [aDecoder decodeObjectForKey:kAlfrescoPropertyDescription];
        self.type = [aDecoder decodeObjectForKey:kCMISPropertyObjectTypeId];
        self.createdAt = [aDecoder decodeObjectForKey:kCMISPropertyCreationDate];
        self.createdBy = [aDecoder decodeObjectForKey:kCMISPropertyCreatedBy];
        self.modifiedBy = [aDecoder decodeObjectForKey:kCMISPropertyModifiedBy];
        self.modifiedAt = [aDecoder decodeObjectForKey:kCMISPropertyModificationDate];
        self.properties = [aDecoder decodeObjectForKey:kAlfrescoNodeProperties];
        self.aspects = [aDecoder decodeObjectForKey:kAlfrescoNodeAspects];
    }
    return self;
}

- (id)propertyValueWithName:(NSString *)propertyName
{
    AlfrescoProperty *property = [self.properties objectForKey:propertyName];
    id value;
    if(property != nil)
    {
        value = property.value;
    }
    return value;
}

- (BOOL)hasAspectWithName:(NSString *)aspectName
{
    return [self.aspects containsObject:aspectName];
}

@end

