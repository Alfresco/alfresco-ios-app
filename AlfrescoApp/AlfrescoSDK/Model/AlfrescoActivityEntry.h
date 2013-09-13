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

/** The AlfrescoActivityEntry represents an activity in an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoActivityEntry : NSObject <NSCoding>

/// @name Properties.

/// The unique identifier of the activity.
@property (nonatomic, strong, readonly) NSString *identifier;


/// The date the activity was posted.
@property (nonatomic, strong, readonly) NSDate *createdAt;


/// The id of the user that posted the activity.
@property (nonatomic, strong, readonly) NSString *createdBy;


/// The short name of the site the activity occurred in, maybe nil.
@property (nonatomic, strong, readonly) NSString *siteShortName;


/// The type of the activity.
@property (nonatomic, strong, readonly) NSString *type;


/// A dictionary holding the data for the activity, this will vary depending on the activity type.
@property (nonatomic, strong, readonly) NSDictionary *data;


- (id)initWithProperties:(NSDictionary *)properties;

@end