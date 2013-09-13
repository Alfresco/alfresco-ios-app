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

#import "AlfrescoCompany.h"
#import "AlfrescoInternalConstants.h"

static NSInteger kCompanyModelVersion = 1;

@interface AlfrescoCompany ()
@property (nonatomic, strong, readwrite) NSString *name;
@property (nonatomic, strong, readwrite) NSString *addressLine1;
@property (nonatomic, strong, readwrite) NSString *addressLine2;
@property (nonatomic, strong, readwrite) NSString *addressLine3;
@property (nonatomic, strong, readwrite) NSString *postCode;
@property (nonatomic, strong, readwrite) NSString *telephoneNumber;
@property (nonatomic, strong, readwrite) NSString *faxNumber;
@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *fullAddress;
@end

@implementation AlfrescoCompany

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        [self setOnPremiseProperties:properties];
        [self setCloudProperties:properties];
        
        self.name = [self valueForProperty:kAlfrescoJSONCompanyName inProperties:properties];
        
        if (self.addressLine1 && self.addressLine1.length > 0)
        {
            self.fullAddress = self.addressLine1;
        }
        if (self.addressLine2 && self.addressLine2.length > 0)
        {
            self.fullAddress = [NSString stringWithFormat:@"%@, %@", self.fullAddress, self.addressLine2];
        }
        if (self.addressLine3 && self.addressLine3.length > 0)
        {
            self.fullAddress = [NSString stringWithFormat:@"%@, %@", self.fullAddress, self.addressLine3];
        }
        if (self.postCode && self.postCode.length > 0)
        {
            self.fullAddress = [NSString stringWithFormat:@"%@, %@", self.fullAddress, self.postCode];
        }
    }
    return self;
}

- (void)setOnPremiseProperties:(NSDictionary *)properties
{
    if (!self.addressLine1)
    {
        self.addressLine1 = [self valueForProperty:kAlfrescoJSONCompanyAddressLine1 inProperties:properties];
    }
    if (!self.addressLine2)
    {
        self.addressLine2 = [self valueForProperty:kAlfrescoJSONCompanyAddressLine2 inProperties:properties];
    }
    if (!self.addressLine3)
    {
        self.addressLine3 = [self valueForProperty:kAlfrescoJSONCompanyAddressLine3 inProperties:properties];
    }
    if (!self.postCode)
    {
        self.postCode = [self valueForProperty:kAlfrescoJSONCompanyPostcode inProperties:properties];
    }
    if (!self.faxNumber)
    {
        self.faxNumber = [self valueForProperty:kAlfrescoJSONCompanyFaxNumber inProperties:properties];
    }
    if (!self.telephoneNumber)
    {
        self.telephoneNumber = [self valueForProperty:kAlfrescoJSONCompanyTelephone inProperties:properties];
    }
    if (!self.email)
    {
        self.email = [self valueForProperty:kAlfrescoJSONCompanyEmail inProperties:properties];
    }
}

- (void)setCloudProperties:(NSDictionary *)properties
{
    if (!self.addressLine1)
    {
        self.addressLine1 = [self valueForProperty:kAlfrescoJSONAddressLine1 inProperties:properties];
    }
    if (!self.addressLine2)
    {
        self.addressLine2 = [self valueForProperty:kAlfrescoJSONAddressLine2 inProperties:properties];
    }
    if (!self.addressLine3)
    {
        self.addressLine3 = [self valueForProperty:kAlfrescoJSONAddressLine3 inProperties:properties];
    }
    if (!self.postCode)
    {
        self.postCode = [self valueForProperty:kAlfrescoJSONPostcode inProperties:properties];
    }
    if (!self.faxNumber)
    {
        self.faxNumber = [self valueForProperty:kAlfrescoJSONFaxNumber inProperties:properties];
    }
    if (!self.telephoneNumber)
    {
        self.telephoneNumber = [self valueForProperty:kAlfrescoJSONTelephoneNumber inProperties:properties];
    }
    if (!self.email)
    {
        self.email = [self valueForProperty:kAlfrescoJSONEmail inProperties:properties];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kCompanyModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.name forKey:kAlfrescoJSONCompanyName];
    [aCoder encodeObject:self.addressLine1 forKey:kAlfrescoJSONCompanyAddressLine1];
    [aCoder encodeObject:self.addressLine2 forKey:kAlfrescoJSONCompanyAddressLine2];
    [aCoder encodeObject:self.addressLine3 forKey:kAlfrescoJSONCompanyAddressLine3];
    [aCoder encodeObject:self.postCode forKey:kAlfrescoJSONCompanyPostcode];
    [aCoder encodeObject:self.telephoneNumber forKey:kAlfrescoJSONCompanyTelephone];
    [aCoder encodeObject:self.faxNumber forKey:kAlfrescoJSONCompanyFaxNumber];
    [aCoder encodeObject:self.email forKey:kAlfrescoJSONCompanyEmail];
    [aCoder encodeObject:self.fullAddress forKey:kAlfrescoJSONCompanyFullAddress];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
        //NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.name = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyName];
        self.addressLine1 = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyAddressLine1];
        self.addressLine2 = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyAddressLine2];
        self.addressLine3 = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyAddressLine3];
        self.postCode = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyPostcode];
        self.telephoneNumber = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyTelephone];
        self.faxNumber = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyFaxNumber];
        self.email = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyEmail];
        self.fullAddress = [aDecoder decodeObjectForKey:kAlfrescoJSONCompanyFullAddress];
    }
    return self;
}

- (id)valueForProperty:(NSString *)property inProperties:(NSDictionary *)properties
{
    id value = [properties valueForKey:property];
    
    if (value && ![value isKindOfClass:[NSNull class]])
    {
        return value;
    }
    return nil;
}

@end
