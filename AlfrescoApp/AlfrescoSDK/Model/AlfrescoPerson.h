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

#import <Foundation/Foundation.h>
#import "AlfrescoCompany.h"

/** The AlfrescoPerson represents a user in an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco), Mohamad Saeedi (Alfresco)
 */

@interface AlfrescoPerson : NSObject <NSCoding>


/// Username of the person.
@property (nonatomic, strong, readonly) NSString *identifier;


/// First name of the person.
@property (nonatomic, strong, readonly) NSString *firstName;


/// Last name of the person.
@property (nonatomic, strong, readonly) NSString *lastName;


/// Full name of the person.
@property (nonatomic, strong, readonly) NSString *fullName;


/// Returns the unique identifier to the content of the avatar rendition.
@property (nonatomic, strong, readonly) NSString *avatarIdentifier;

// Job title of the person. 
@property (nonatomic, strong, readonly) NSString *jobTitle;

// Location of the person
@property (nonatomic, strong, readonly) NSString *location;

// Summury / Description of the person
@property (nonatomic, strong, readonly) NSString *description;

// Telephone number of the person
@property (nonatomic, strong, readonly) NSString *telephoneNumber;

// Mobile Number of the person
@property (nonatomic, strong, readonly) NSString *mobileNumber;

// Email of the person
@property (nonatomic, strong, readonly) NSString *email;

// Skype Id of the person
@property (nonatomic, strong, readonly) NSString *skypeId;

// Instant Message Id of the person
@property (nonatomic, strong, readonly) NSString *instantMessageId;

// Good Id of the person
@property (nonatomic, strong, readonly) NSString *googleId;

// Status of the person
@property (nonatomic, strong, readonly) NSString *status;

// Time the Status change
@property (nonatomic, strong, readonly) NSDate *statusTime;

// Company Info of the person
@property (nonatomic, strong, readonly) AlfrescoCompany *company;

- (id)initWithProperties:(NSDictionary *)properties;

@end
