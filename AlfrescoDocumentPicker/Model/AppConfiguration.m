/*******************************************************************************
 * Copyright (C) 2005-2020 Alfresco Software Limited.
 *
 * This file is part of the Alfresco Mobile iOS App.
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

#import "AppConfiguration.h"
#import "SharedConstants.h"

static NSString * const kAlfrescoRepositoryConfigurationRootMenuKey = @"rootMenu";
static NSString * const kAlfrescoRepositoryConfigurationVisibilityKey = @"visible";

@interface AppConfiguration ()
@property (nonatomic, strong, readwrite) NSDictionary *configurationDictionary;
@end

@implementation AppConfiguration

- (instancetype)initWithAppConfiguration:(NSDictionary *)configuration
{
    self = [self init];
    if (self)
    {
        self.configurationDictionary = configuration;
    }
    return self;
}

- (instancetype)initWithAppConfigurationFileURL:(NSURL *)configurationURL
{
    self = [self init];
    if (self)
    {
        NSData *fileData = [NSData dataWithContentsOfFile:configurationURL.path];
        NSError *parseError = nil;
        id jsonObject = [NSJSONSerialization JSONObjectWithData:fileData options:0 error:&parseError];
        
        if (jsonObject)
        {
            if ([jsonObject isKindOfClass:[NSDictionary class]])
            {
                self.configurationDictionary = (NSDictionary *)jsonObject;
            }
        }
    }
    return self;
}

#pragma mark - Private Methods

- (BOOL)visibilityKeyInDictionary:(NSDictionary *)dictionary
{
    BOOL shouldDisplay = YES;
    NSNumber *visibilityValue = dictionary[kAlfrescoRepositoryConfigurationVisibilityKey];
    
    if (visibilityValue)
    {
        shouldDisplay = visibilityValue.boolValue;
    }
    
    return shouldDisplay;
}

#pragma mark - Public Methods

- (BOOL)visibilityInRootMenuForKey:(NSString *)key
{
    NSDictionary *rootMenuDictionary = self.configurationDictionary[kAlfrescoRepositoryConfigurationRootMenuKey];
    NSDictionary *keyDictionary = rootMenuDictionary[key];
    return [self visibilityKeyInDictionary:keyDictionary];
}

@end
