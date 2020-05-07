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

#import "MDMUserDefaultsConfigurationHelper.h"

@interface MDMUserDefaultsConfigurationHelper ()

@property (nonatomic, strong, readwrite) NSString *configurationKey;
@property (nonatomic, strong, readwrite) NSDictionary *managedConfiguration;
@property (nonatomic, assign, readwrite) BOOL isManaged;

@end

@implementation MDMUserDefaultsConfigurationHelper

- (instancetype)initWithConfigurationKey:(NSString *)configurationKey
{
    self = [self init];
    if (self)
    {
        self.configurationKey = configurationKey;
        self.managedConfiguration = [[NSUserDefaults standardUserDefaults] dictionaryForKey:configurationKey];
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:configurationKey options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:_configurationKey];
}

#pragma mark - Private Methods

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:self.configurationKey])
    {
        self.managedConfiguration = change;
        AlfrescoLogDebug(@"KVO: %@ changed property %@ to value %@", object, keyPath, change);
    }
}

#pragma mark - Custom Getters and Setters

- (NSDictionary *)rootManagedDictionary
{
    return self.managedConfiguration;
}

- (BOOL)isManaged
{
    return (self.managedConfiguration != nil);
}

#pragma mark - Public Methods

- (id)valueForKey:(NSString *)key
{
    return [self.managedConfiguration valueForKey:key];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    return [self.managedConfiguration valueForKeyPath:keyPath];
}

- (void)setManagedDictionary:(NSDictionary *)dictionary
{
    self.managedConfiguration = dictionary;
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setValue:dictionary forKey:self.configurationKey];
    [userDefaults synchronize];
}

@end
