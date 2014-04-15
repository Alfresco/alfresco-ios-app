//
//  SaveBackMetadata.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 10/04/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

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
