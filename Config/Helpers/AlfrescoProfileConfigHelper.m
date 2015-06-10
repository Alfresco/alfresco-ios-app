/*
 ******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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

#import "AlfrescoProfileConfigHelper.h"
#import "AlfrescoInternalConstants.h"
#import "AlfrescoPropertyConstants.h"
#import "AlfrescoLog.h"

@interface AlfrescoProfileConfigHelper ()
@property (nonatomic, strong, readwrite) NSArray *profiles;
@property (nonatomic, strong, readwrite) AlfrescoProfileConfig *defaultProfile;
@property (nonatomic, strong, readwrite) NSMutableDictionary *profilesDictionary;
@end

@implementation AlfrescoProfileConfigHelper

#pragma mark - Public methods

-(void)parse
{
    NSDictionary *profilesJSON = self.json[kAlfrescoJSONProfiles];
    
    self.profilesDictionary = [NSMutableDictionary dictionary];
    
    NSArray *profileIds = [profilesJSON allKeys];
    for (NSString *profileId in profileIds)
    {
        NSDictionary *profileJSON = profilesJSON[profileId];
        
        NSMutableDictionary *profileProperties = [self configPropertiesFromJSON:profileJSON];
        
        // add the id of the profile
        profileProperties[kAlfrescoBaseConfigPropertyIdentifier] = profileId;
        
        // process view id
        NSString *rootViewId = profileJSON[kAlfrescoJSONRootViewId];
        if (rootViewId != nil)
        {
            profileProperties[kAlfrescoProfileConfigPropertyRootViewId] = rootViewId;
        }
        
        // process default flag
        id isDefault = profileJSON[kAlfrescoJSONDefault];
        if (isDefault != nil)
        {
            profileProperties[kAlfrescoProfileConfigPropertyIsDefault] = isDefault;
        }
        
        // create and store the profile object
        AlfrescoProfileConfig *profile = [[AlfrescoProfileConfig alloc] initWithDictionary:profileProperties];
        self.profilesDictionary[profile.identifier] = profile;
        
        // set as the default profile, if appropriate
        if (profile.isDefault)
        {
            self.defaultProfile = profile;
        }
        
        AlfrescoLogDebug(@"Stored config for profile with id: %@", profileId);
    }
    
    // make sure we have at least one profile
    if (self.profilesDictionary.count == 0)
    {
        NSDictionary *defaultProfileProperties = @{kAlfrescoBaseConfigPropertyIdentifier: kAlfrescoConfigProfileDefaultIdentifier,
                                                   kAlfrescoBaseConfigPropertyLabel: kAlfrescoConfigProfileDefaultLabel,
                                                   kAlfrescoProfileConfigPropertyIsDefault: @YES};
        
        AlfrescoProfileConfig *defaultProfile = [[AlfrescoProfileConfig alloc] initWithDictionary:defaultProfileProperties];
        self.profilesDictionary[kAlfrescoConfigProfileDefaultIdentifier] = defaultProfile;
        self.defaultProfile = defaultProfile;
    }
    
    // set profile property
    self.profiles = [self.profilesDictionary allValues];
    
    // make sure there is a default profile, select first one if not
    if (self.defaultProfile == nil)
    {
        self.defaultProfile = self.profiles.firstObject;
    }
}

- (AlfrescoProfileConfig *)profileConfigForIdentifier:(NSString *)identifier
{
    AlfrescoProfileConfig *profileConfig = self.profilesDictionary[identifier];
    
    AlfrescoLogDebug(@"Returning profile config for identifier '%@': %@", identifier, profileConfig);
    
    return profileConfig;
}

@end
