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

#import "AlfrescoFolder.h"

/** The AlfrescoSite represents a site in an Alfresco repository.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

// Site visibility type enum.
typedef enum 
{
    AlfrescoSiteVisibilityPublic = 0,
    AlfrescoSiteVisibilityModerated,
    AlfrescoSiteVisibilityPrivate
} AlfrescoSiteVisibility;


@interface AlfrescoSite : NSObject <NSCoding>

/// Returns the short name of the site.
@property (nonatomic, strong, readonly) NSString *shortName;


/// Returns the title of the site.
@property (nonatomic, strong, readonly) NSString *title;


/// Returns the description of the site.
@property (nonatomic, strong, readonly) NSString *summary;


@property (nonatomic, strong, readonly) NSString *identifier;

@property (nonatomic, strong, readonly) NSString *GUID;

@property (nonatomic, assign, readonly) BOOL isMember;

@property (nonatomic, assign, readonly) BOOL isPendingMember;

@property (nonatomic, assign, readonly) BOOL isFavorite;

/// The visibility of the site.
@property (nonatomic, assign, readonly) AlfrescoSiteVisibility visibility;

- (id)initWithProperties:(NSDictionary *)properties;


@end

