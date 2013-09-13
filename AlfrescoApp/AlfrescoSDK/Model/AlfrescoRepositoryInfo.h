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
 * The AlfrescoRepositoryInfo holds the information of a specific Alfresco repository.
 * Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 *****************************************************************************
 */

#import <Foundation/Foundation.h>
#import "AlfrescoFolder.h"
#import "AlfrescoRepositoryCapabilities.h"
/** The AlfrescoRepositoryInfo stores metadata about the repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */


@interface AlfrescoRepositoryInfo : NSObject <NSCoding>


/// The name of the repository connected to.
@property (nonatomic, strong, readonly) NSString *name;


/// The unique identifier of the repository.
@property (nonatomic, strong, readonly) NSString *identifier;


/// The summary (a description) of the repository.
@property (nonatomic, strong, readonly) NSString *summary;


/// The edition of the repository, will be either "Community" or "Enterprise".
@property (nonatomic, strong, readonly) NSString *edition;


/// The major version of the repository.
@property (nonatomic, strong, readonly) NSNumber *majorVersion;


/// The minor version of the repository.
@property (nonatomic, strong, readonly) NSNumber *minorVersion;


/// The maintenance version of the repository.
@property (nonatomic, strong, readonly) NSNumber *maintenanceVersion;


/// The build number of the repository.
@property (nonatomic, strong, readonly) NSString *buildNumber;


/// The version of the repository i.e. 4.0.0 (b 124).
@property (nonatomic, strong, readonly) NSString *version;


/// Stores the Like/Comment Count capabilities.
@property (nonatomic, strong, readonly) AlfrescoRepositoryCapabilities *capabilities;

- (id)initWithProperties:(NSDictionary *)properties;
@end