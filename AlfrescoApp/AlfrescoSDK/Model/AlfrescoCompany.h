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

/** The AlfrescoCompany represents the company user belong to.
 
 Author: Mohamad Saeedi (Alfresco)
 */

@interface AlfrescoCompany : NSObject <NSCoding>

// Name of the company
@property (nonatomic, strong, readonly) NSString *name;

// Address Line 1 of the company
@property (nonatomic, strong, readonly) NSString *addressLine1;

// Address Line 2 of the company
@property (nonatomic, strong, readonly) NSString *addressLine2;

// Address Line 3 of the company
@property (nonatomic, strong, readonly) NSString *addressLine3;

// Postcode of the company
@property (nonatomic, strong, readonly) NSString *postCode;

// Telephone Number of the comapny
@property (nonatomic, strong, readonly) NSString *telephoneNumber;

// Fax Number of the company
@property (nonatomic, strong, readonly) NSString *faxNumber;

// Email of the company
@property (nonatomic, strong, readonly) NSString *email;

// Full address of the company
@property (nonatomic, strong, readonly) NSString *fullAddress;

- (id)initWithProperties:(NSDictionary *)properties;

@end
