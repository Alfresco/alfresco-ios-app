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
#import "AlfrescoConstants.h"
/** The AlfrescoRepositoryCapabilities are used as a property on AlfrescoRepositoryInfo.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoRepositoryCapabilities : NSObject <NSCoding>
@property (nonatomic, assign, readonly) BOOL doesSupportLikingNodes;
@property (nonatomic, assign, readonly) BOOL doesSupportCommentCounts;

- (id)initWithProperties:(NSDictionary *)properties;

/**
 Checks whether the capability is supported. At present 2 capabilities are available
 - kAlfrescoCapabilityLike
 - kAlfrescoCapabilityCommentsCount

 @param capability - the defined capability to check.  
 */
- (BOOL)doesSupportCapability:(NSString *)capability;

@end
