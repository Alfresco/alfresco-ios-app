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

#import "AlfrescoComment.h"
#import "AlfrescoInternalConstants.h"
#import "CMISDateUtil.h"

static NSUInteger kCommentModelVersion = 1;

@interface AlfrescoComment ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *title;
@property (nonatomic, strong, readwrite) NSDate *createdAt;
@property (nonatomic, strong, readwrite) NSDate *modifiedAt;
@property (nonatomic, strong, readwrite) NSString *content;
@property (nonatomic, strong, readwrite) NSString *createdBy;
@property (nonatomic, readwrite) BOOL isEdited;
@property (nonatomic, readwrite) BOOL canEdit;
@property (nonatomic, readwrite) BOOL canDelete;
@property (nonatomic, strong) NSDateFormatter * standardDateFormatter;
@end


@implementation AlfrescoComment


- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        self.standardDateFormatter = [[NSDateFormatter alloc] init];
        [self.standardDateFormatter setDateFormat:@"MMM' 'dd' 'yyyy' 'HH:mm:ss' 'zzz"];
        if ([[properties allKeys] containsObject:kAlfrescoJSONTitle])
        {
            self.title = [properties valueForKey:kAlfrescoJSONTitle];
        }
        if ([[properties allKeys] containsObject:kAlfrescoJSONContent])
        {
            self.content = [properties valueForKey:kAlfrescoJSONContent];
        }
        [self setCloudProperties:properties];
        [self setOnPremiseProperties:properties];
    }
    return self;
}

- (void)setOnPremiseProperties:(NSDictionary *)properties
{
    if ([[properties allKeys] containsObject:kAlfrescoJSONNodeRef])
    {
        self.identifier = [properties valueForKey:kAlfrescoJSONNodeRef];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONName])
    {
        self.name = [properties valueForKey:kAlfrescoJSONName];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONAuthor])
    {
        NSDictionary *authorDict = [properties valueForKey:kAlfrescoJSONAuthor];
        if ([[authorDict allKeys] containsObject:kAlfrescoJSONUsername]) {
            self.createdBy = [authorDict valueForKey:kAlfrescoJSONUsername];
        }
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONPermissions])
    {
        NSDictionary *permissionDict = [properties valueForKey:kAlfrescoJSONPermissions];
        if ([[permissionDict allKeys] containsObject:kAlfrescoJSONEdit])
        {
            self.canEdit = [[permissionDict valueForKeyPath:kAlfrescoJSONEdit] boolValue];
        }
        if ([[permissionDict allKeys] containsObject:kAlfrescoJSONDelete])
        {
            self.canDelete = [[permissionDict valueForKeyPath:kAlfrescoJSONDelete] boolValue];
        }
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONIsUpdated])
    {
        self.isEdited = [[properties valueForKey:kAlfrescoJSONIsUpdated] boolValue];
    }
    
    if ([[properties allKeys] containsObject:kAlfrescoJSONCreatedOnISO] || [[properties allKeys] containsObject:kAlfrescoJSONCreatedOn])
    {
        if ([[properties allKeys] containsObject:kAlfrescoJSONCreatedOnISO])
        {
            NSString *created = [properties valueForKey:kAlfrescoJSONCreatedOnISO];
            if (nil != created)
            {
                self.createdAt = [CMISDateUtil dateFromString:created];
            }
        }
        else
        {
            NSString *created = [properties valueForKey:kAlfrescoJSONCreatedOn];
            if (nil != created)
            {
                NSArray *dateComponents = [created componentsSeparatedByString:@"("];
                NSString *dateWithZZZTimeZone = [dateComponents objectAtIndex:0];
                self.createdAt = [self.standardDateFormatter dateFromString:dateWithZZZTimeZone];
            }
        }
    }
    
    if ([[properties allKeys] containsObject:kAlfrescoJSONModifiedOnISO] || [[properties allKeys] containsObject:kAlfrescoJSONModifiedOn])
    {
        if ([[properties allKeys] containsObject:kAlfrescoJSONModifiedOnISO])
        {
            NSString *modified = [properties valueForKey:kAlfrescoJSONModifiedOnISO];
            if (nil != modified)
            {
                self.modifiedAt = [CMISDateUtil dateFromString:modified];
            }
        }
        else
        {
            NSString *modified = [properties valueForKey:kAlfrescoJSONModifiedOn];
            if (nil != modified)
            {
                NSArray *dateComponents = [modified componentsSeparatedByString:@"("];
                NSString *dateWithZZZTimeZone = [dateComponents objectAtIndex:0];
                self.modifiedAt = [self.standardDateFormatter dateFromString:dateWithZZZTimeZone];
            }
        }
    }
    
}

- (void)setCloudProperties:(NSDictionary *)properties
{
    if ([[properties allKeys] containsObject:kAlfrescoJSONIdentifier])
    {
        self.identifier = [properties valueForKey:kAlfrescoJSONIdentifier];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONCreatedAt])
    {
        NSString *createdDateString = [properties valueForKey:kAlfrescoJSONCreatedAt];
        if (nil != createdDateString)
        {
            self.createdAt = [CMISDateUtil dateFromString:createdDateString];
        }
        
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONCreatedBy])
    {
        NSDictionary *createdByDict = [properties valueForKey:kAlfrescoJSONCreatedBy];
        self.createdBy = [createdByDict valueForKey:kAlfrescoJSONIdentifier];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONModifedAt])
    {
        NSString *modifiedDateString = [properties valueForKey:kAlfrescoJSONModifedAt];
        if (nil != modifiedDateString)
        {
            self.modifiedAt = [CMISDateUtil dateFromString:modifiedDateString];
        }
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONCanEdit])
    {
        self.canEdit = [[properties valueForKey:kAlfrescoJSONCanEdit] boolValue];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONEdited])
    {
        self.isEdited = [[properties valueForKey:kAlfrescoJSONEdited] boolValue];
    }
    if ([[properties allKeys] containsObject:kAlfrescoJSONCanDelete])
    {
        self.canDelete = [[properties valueForKey:kAlfrescoJSONCanDelete] boolValue];
    }
    
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kCommentModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.title forKey:kAlfrescoJSONTitle];
    [aCoder encodeObject:self.content forKey:kAlfrescoJSONContent];
    [aCoder encodeObject:self.identifier forKey:kAlfrescoJSONIdentifier];
    [aCoder encodeObject:self.createdAt forKey:kAlfrescoJSONCreatedAt];
    [aCoder encodeObject:self.createdBy forKey:kAlfrescoJSONCreatedBy];
    [aCoder encodeObject:self.modifiedAt forKey:kAlfrescoJSONModifedAt];
    [aCoder encodeBool:self.canDelete forKey:kAlfrescoJSONCanDelete];
    [aCoder encodeBool:self.canEdit forKey:kAlfrescoJSONCanEdit];
    [aCoder encodeBool:self.isEdited forKey:kAlfrescoJSONEdited];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
//        NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.title = [aDecoder decodeObjectForKey:kAlfrescoJSONTitle];
        self.content = [aDecoder decodeObjectForKey:kAlfrescoJSONContent];
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoJSONIdentifier];
        self.createdBy = [aDecoder decodeObjectForKey:kAlfrescoJSONCreatedBy];
        self.createdAt = [aDecoder decodeObjectForKey:kAlfrescoJSONCreatedAt];
        self.modifiedAt = [aDecoder decodeObjectForKey:kAlfrescoJSONModifedAt];
        self.isEdited = [aDecoder decodeBoolForKey:kAlfrescoJSONEdited];
        self.canEdit = [aDecoder decodeBoolForKey:kAlfrescoJSONCanEdit];
        self.canDelete = [aDecoder decodeBoolForKey:kAlfrescoJSONCanDelete];
    }
    return self;
}


@end
