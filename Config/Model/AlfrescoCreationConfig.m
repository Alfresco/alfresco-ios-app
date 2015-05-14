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

#import "AlfrescoCreationConfig.h"
#import "AlfrescoPropertyConstants.h"

@interface AlfrescoCreationConfig ()
@property (nonatomic, strong, readwrite) NSArray *creatableMimeTypes;
@property (nonatomic, strong, readwrite) NSArray *creatableDocumentTypes;
@property (nonatomic, strong, readwrite) NSArray *creatableFolderTypes;
@end

@implementation AlfrescoCreationConfig

- (id)initWithDictionary:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        self.creatableMimeTypes = properties[kAlfrescoCreationConfigPropertyCreatableMimeTypes];
        self.creatableDocumentTypes = properties[kAlfrescoCreationConfigPropertyCreatableDocumentTypes];
        self.creatableFolderTypes = properties[kAlfrescoCreationConfigPropertyCreatableFolderTypes];
    }
    return self;
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        self.creatableMimeTypes = [aDecoder decodeObjectForKey:kAlfrescoCreationConfigPropertyCreatableMimeTypes];
        self.creatableDocumentTypes = [aDecoder decodeObjectForKey:kAlfrescoCreationConfigPropertyCreatableDocumentTypes];
        self.creatableFolderTypes = [aDecoder decodeObjectForKey:kAlfrescoCreationConfigPropertyCreatableFolderTypes];
    }
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.creatableMimeTypes forKey:kAlfrescoCreationConfigPropertyCreatableMimeTypes];
    [aCoder encodeObject:self.creatableDocumentTypes forKey:kAlfrescoCreationConfigPropertyCreatableDocumentTypes];
    [aCoder encodeObject:self.creatableFolderTypes forKey:kAlfrescoCreationConfigPropertyCreatableFolderTypes];
}

@end
