/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 * 
 * This file is part of the Alfresco Mobile iOS App.
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
 
#import "SaveBackMetadata.h"
#import <objc/runtime.h>

@interface SaveBackMetadata ()

@property (nonatomic, strong, readwrite) NSString *accountID;
@property (nonatomic, strong, readwrite) NSString *nodeRef;
@property (nonatomic, strong, readwrite) NSString *originalFileLocation;
@property (nonatomic, assign, readwrite) InAppDocumentLocation documentLocation;

@end

@implementation SaveBackMetadata

- (instancetype)initWithAccountID:(NSString *)accountID nodeRef:(NSString *)nodeRef  originalFileLocation:(NSString *)urlString documentLocation:(InAppDocumentLocation)location
{
    self = [self init];
    if (self)
    {
        self.accountID = accountID;
        self.nodeRef = nodeRef;
        self.originalFileLocation = urlString;
        self.documentLocation = location;
    }
    return self;
}

- (instancetype)initWithDictionary:(NSDictionary *)dictionary
{
    self = [self init];
    if (self && dictionary != nil)
    {
        [self setValuesForKeysWithDictionary:dictionary];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    return [self dictionaryWithValuesForKeys:[self getPropertyNames]];
}

- (BOOL)isValid
{
    BOOL valid = NO;
    
    // determine whether the currently stored information is valid
    if (self.accountID && self.nodeRef && self.originalFileLocation)
    {
        valid = YES;
    }
    
    return valid;
}

#pragma mark - Custom Getters and Setters

- (void)setOriginalFileLocation:(NSString *)originalFileLocation
{
    _originalFileLocation = [originalFileLocation stringByRemovingPercentEncoding];
}

#pragma mark - Private Functions

- (NSArray *)getPropertyNames
{
    NSMutableArray *propertyNames = [NSMutableArray array];
    
    unsigned int propertyCount;
    objc_property_t *properties = class_copyPropertyList([self class], &propertyCount);
    
    for (int i = 0; i < propertyCount; i++)
    {
        objc_property_t property = properties[i];
        const char *propertyName = property_getName(property);
        if (propertyName)
        {
            NSString *propertyNameString = [NSString stringWithCString:propertyName encoding:[NSString defaultCStringEncoding]];
            [propertyNames addObject:propertyNameString];
        }
    }
    
    free(properties);
    
    return propertyNames;
}

@end
