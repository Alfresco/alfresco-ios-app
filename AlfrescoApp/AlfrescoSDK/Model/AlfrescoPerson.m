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

#import "AlfrescoPerson.h"
#import "AlfrescoInternalConstants.h"

static NSInteger kPersonModelVersion = 1;

@interface AlfrescoPerson ()
@property (nonatomic, strong, readwrite) NSString *identifier;
@property (nonatomic, strong, readwrite) NSString *firstName;
@property (nonatomic, strong, readwrite) NSString *lastName;
@property (nonatomic, strong, readwrite) NSString *fullName;
@property (nonatomic, strong, readwrite) NSString *avatarIdentifier;
@property (nonatomic, strong, readwrite) NSString *jobTitle;
@property (nonatomic, strong, readwrite) NSString *location;
@property (nonatomic, strong, readwrite) NSString *description;
@property (nonatomic, strong, readwrite) NSString *telephoneNumber;
@property (nonatomic, strong, readwrite) NSString *mobileNumber;
@property (nonatomic, strong, readwrite) NSString *email;
@property (nonatomic, strong, readwrite) NSString *skypeId;
@property (nonatomic, strong, readwrite) NSString *instantMessageId;
@property (nonatomic, strong, readwrite) NSString *googleId;
@property (nonatomic, strong, readwrite) NSString *status;
@property (nonatomic, strong, readwrite) NSDate *statusTime;
@property (nonatomic, strong, readwrite) AlfrescoCompany *company;
@end

@implementation AlfrescoPerson


///Cloud
/*
 AlfrescoPerson *alfPerson = [[AlfrescoPerson alloc] init];
 alfPerson.identifier = [personDict valueForKey:kAlfrescoJSONIdentifier];
 alfPerson.firstName = [personDict valueForKey:kAlfrescoJSONFirstName];
 alfPerson.lastName = [personDict valueForKey:kAlfrescoJSONLastName];
 if (alfPerson.lastName != nil && alfPerson.lastName.length > 0)
 {
 if (alfPerson.firstName != nil && alfPerson.firstName.length > 0)
 {
 alfPerson.fullName = [NSString stringWithFormat:@"%@ %@", alfPerson.firstName, alfPerson.lastName];
 }
 else
 {
 alfPerson.fullName = alfPerson.lastName;
 }
 }
 else if (alfPerson.firstName != nil && alfPerson.firstName.length > 0)
 {
 alfPerson.fullName = alfPerson.firstName;
 }
 else
 {
 alfPerson.fullName = alfPerson.identifier;
 }
 alfPerson.avatarIdentifier = [personDict valueForKey:kAlfrescoJSONAvatarId];
 */

///OnPremise
/*
 - (AlfrescoPerson *)personFromJSON:(NSDictionary *)personDict
 {
 AlfrescoPerson *alfPerson = [[AlfrescoPerson alloc] init];
 alfPerson.identifier = [personDict valueForKey:kAlfrescoJSONUserName];
 alfPerson.firstName = [personDict valueForKey:kAlfrescoJSONFirstName];
 alfPerson.lastName = [personDict valueForKey:kAlfrescoJSONLastName];
 if (alfPerson.lastName != nil && alfPerson.lastName.length > 0)
 {
 if (alfPerson.firstName != nil && alfPerson.firstName.length > 0)
 {
 alfPerson.fullName = [NSString stringWithFormat:@"%@ %@", alfPerson.firstName, alfPerson.lastName];
 }
 else
 {
 alfPerson.fullName = alfPerson.lastName;
 }
 }
 else if (alfPerson.firstName != nil && alfPerson.firstName.length > 0)
 {
 alfPerson.fullName = alfPerson.firstName;
 }
 else
 {
 alfPerson.fullName = alfPerson.identifier;
 }
 alfPerson.avatarIdentifier = [personDict valueForKey:kAlfrescoJSONAvatar];
 return alfPerson;
 }
 */

- (id)initWithProperties:(NSDictionary *)properties
{
    self = [super init];
    if (nil != self)
    {
        [self setOnPremiseProperties:properties];
        [self setCloudProperties:properties];
        
        self.firstName = [self valueForProperty:kAlfrescoJSONFirstName inProperties:properties];
        self.lastName = [self valueForProperty:kAlfrescoJSONLastName inProperties:properties];
        self.location = [self valueForProperty:kAlfrescoJSONLocation inProperties:properties];
        self.telephoneNumber = [self valueForProperty:kAlfrescoJSONTelephoneNumber inProperties:properties];
        self.mobileNumber = [self valueForProperty:kAlfrescoJSONMobileNumber inProperties:properties];
        self.email = [self valueForProperty:kAlfrescoJSONEmail inProperties:properties];
        self.status = [self valueForProperty:kAlfrescoJSONStatus inProperties:properties];
        self.statusTime = [self valueForProperty:kAlfrescoJSONStatusTime inProperties:properties];
        self.company = [self valueForProperty:kAlfrescoJSONCompany inProperties:properties];
        
        
        if (self.lastName != nil && self.lastName.length > 0)
        {
            if (self.firstName != nil && self.firstName.length > 0)
            {
                self.fullName = [NSString stringWithFormat:@"%@ %@", self.firstName, self.lastName];
            }
            else
            {
                self.fullName = self.lastName;
            }
        }
        else if (self.firstName != nil && self.firstName.length > 0)
        {
            self.fullName = self.firstName;
        }
        else
        {
            self.fullName = self.identifier;
        }
    }
    return self;
}

- (void)setOnPremiseProperties:(NSDictionary *)properties
{
    if (!self.identifier)
    {
        self.identifier = [self valueForProperty:kAlfrescoJSONUserName inProperties:properties];
    }
    if (!self.avatarIdentifier)
    {
        self.avatarIdentifier = [self valueForProperty:kAlfrescoJSONAvatar inProperties:properties];
    }
    if (!self.jobTitle)
    {
        self.jobTitle = [self valueForProperty:kAlfrescoJSONJobTitle inProperties:properties];
    }
    if (!self.description)
    {
        self.description = [self valueForProperty:kAlfrescoJSONPersonDescription inProperties:properties];
    }
    if (!self.skypeId)
    {
        self.skypeId = [self valueForProperty:kAlfrescoJSONSkype inProperties:properties];
    }
    if (!self.instantMessageId)
    {
        self.instantMessageId = [self valueForProperty:kAlfrescoJSONInstantMessage inProperties:properties];
    }
    if (!self.googleId)
    {
        self.googleId = [self valueForProperty:kAlfrescoJSONGoogle inProperties:properties];
    }
}

- (void)setCloudProperties:(NSDictionary *)properties
{
    if (!self.identifier)
    {
        self.identifier = [self valueForProperty:kAlfrescoJSONIdentifier inProperties:properties];
    }
    if (!self.jobTitle)
    {
        self.jobTitle = [self valueForProperty:kAlfrescoCloudJSONJobTitle inProperties:properties];
    }
    if (!self.description)
    {
        self.description = [self valueForProperty:kAlfrescoJSONDescription inProperties:properties];
    }
    if (!self.skypeId)
    {
        self.skypeId = [self valueForProperty:kAlfrescoJSONSkypeId inProperties:properties];
    }
    if (!self.instantMessageId)
    {
        self.instantMessageId = [self valueForProperty:kAlfrescoJSONInstantMessageId inProperties:properties];
    }
    if (!self.googleId)
    {
        self.googleId = [self valueForProperty:kAlfrescoJSONGoogleId inProperties:properties];
    }
    
    id avatarObj = [self valueForProperty:kAlfrescoJSONAvatarId inProperties:properties];
    if (!self.avatarIdentifier && [avatarObj isKindOfClass:[NSString class]])
    {
        self.avatarIdentifier = avatarObj;
    }
    else if (!self.avatarIdentifier && [avatarObj isKindOfClass:[NSDictionary class]])
    {
        NSDictionary *avatarDict = (NSDictionary *)avatarObj;
        self.avatarIdentifier = [self valueForProperty:kAlfrescoJSONIdentifier inProperties:avatarDict];
    }
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInteger:kPersonModelVersion forKey:NSStringFromClass([self class])];
    [aCoder encodeObject:self.avatarIdentifier forKey:kAlfrescoJSONAvatarId];
    [aCoder encodeObject:self.firstName forKey:kAlfrescoJSONFirstName];
    [aCoder encodeObject:self.lastName forKey:kAlfrescoJSONLastName];
    [aCoder encodeObject:self.fullName forKey:kAlfrescoJSONFullName];
    [aCoder encodeObject:self.identifier forKey:kAlfrescoJSONIdentifier];
    [aCoder encodeObject:self.jobTitle forKey:kAlfrescoCloudJSONJobTitle];
    [aCoder encodeObject:self.location forKey:kAlfrescoJSONLocation];
    [aCoder encodeObject:self.description forKey:kAlfrescoJSONDescription];
    [aCoder encodeObject:self.telephoneNumber forKey:kAlfrescoJSONTelephoneNumber];
    [aCoder encodeObject:self.mobileNumber forKey:kAlfrescoJSONMobileNumber];
    [aCoder encodeObject:self.skypeId forKey:kAlfrescoJSONSkypeId];
    [aCoder encodeObject:self.instantMessageId forKey:kAlfrescoJSONInstantMessageId];
    [aCoder encodeObject:self.status forKey:kAlfrescoJSONStatus];
    [aCoder encodeObject:self.statusTime forKey:kAlfrescoJSONStatusTime];
    [aCoder encodeObject:self.googleId forKey:kAlfrescoJSONGoogleId];
    [aCoder encodeObject:self.email forKey:kAlfrescoJSONEmail];
    [aCoder encodeObject:self.company forKey:kAlfrescoJSONCompany];
}

- (id)initWithCoder:(NSCoder *)aDecoder
{
    self = [super init];
    if (nil != self)
    {
        //uncomment this line if you need to check the model version
        //NSInteger version = [aDecoder decodeIntForKey:NSStringFromClass([self class])];
        self.avatarIdentifier = [aDecoder decodeObjectForKey:kAlfrescoJSONAvatarId];
        self.firstName = [aDecoder decodeObjectForKey:kAlfrescoJSONFirstName];
        self.lastName = [aDecoder decodeObjectForKey:kAlfrescoJSONLastName];
        self.fullName = [aDecoder decodeObjectForKey:kAlfrescoJSONFullName];
        self.identifier = [aDecoder decodeObjectForKey:kAlfrescoJSONIdentifier];
        self.jobTitle = [aDecoder decodeObjectForKey:kAlfrescoCloudJSONJobTitle];
        self.location = [aDecoder decodeObjectForKey:kAlfrescoJSONLocation];
        self.description = [aDecoder decodeObjectForKey:kAlfrescoJSONDescription];
        self.telephoneNumber = [aDecoder decodeObjectForKey:kAlfrescoJSONTelephoneNumber];
        self.mobileNumber = [aDecoder decodeObjectForKey:kAlfrescoJSONMobileNumber];
        self.skypeId = [aDecoder decodeObjectForKey:kAlfrescoJSONSkypeId];
        self.instantMessageId = [aDecoder decodeObjectForKey:kAlfrescoJSONInstantMessageId];
        self.status = [aDecoder decodeObjectForKey:kAlfrescoJSONStatus];
        self.statusTime = [aDecoder decodeObjectForKey:kAlfrescoJSONStatusTime];
        self.googleId = [aDecoder decodeObjectForKey:kAlfrescoJSONGoogleId];
        self.email = [aDecoder decodeObjectForKey:kAlfrescoJSONEmail];
        self.company = [aDecoder decodeObjectForKey:kAlfrescoJSONCompany];
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
