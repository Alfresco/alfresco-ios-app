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
/** The AlfrescoCloudNetwork stores defines properties for a particular network/tenant.
 
 Author: Gavin Cornwell (Alfresco), Tijs Rademakers (Alfresco), Peter Schmidt (Alfresco)
 */

@interface AlfrescoCloudNetwork : NSObject
/**
 identifier string for network/tenant
 */
@property (nonatomic, strong) NSString * identifier;
/**
 flag indicating whether the network object is the Home network
 */
@property (nonatomic, assign) BOOL isHomeNetwork;
/**
 flag indicating whether this is a paid network
 */
@property (nonatomic, assign) BOOL isPaidNetwork;
/**
 the subscription level for this network
 */
@property (nonatomic, strong) NSString * subscriptionLevel;
/**
 the date the network was created at
 */
@property (nonatomic, strong) NSDate * createdAt;

/**
 the flag indicating whether this network is enabled
 */
@property (nonatomic, assign) BOOL isEnabled;
@end
