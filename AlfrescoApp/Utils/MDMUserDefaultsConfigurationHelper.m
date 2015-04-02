/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

@property (nonatomic, strong) NSDictionary *managedConfiguration;

@end

@implementation MDMUserDefaultsConfigurationHelper

- (instancetype)init
{
    self = [super init];
    if (self)
    {
        self.managedConfiguration = [[NSUserDefaults standardUserDefaults] dictionaryForKey:kAppleManagedConfigurationKey];
        
        [[NSUserDefaults standardUserDefaults] addObserver:self forKeyPath:kAppleManagedConfigurationKey options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}

- (void)dealloc
{
    [[NSUserDefaults standardUserDefaults] removeObserver:self forKeyPath:kAppleManagedConfigurationKey];
}

#pragma mark - Private Methods

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([keyPath isEqualToString:kAppleManagedConfigurationKey])
    {
        self.managedConfiguration = change;
        NSLog(@"KVO: %@ changed property %@ to value %@", object, keyPath, change);
    }
}

#pragma mark - Custom Getters and Setters

- (NSDictionary *)rootManagedDictionary
{
    return self.managedConfiguration;
}

#pragma mark - Public Methods

- (BOOL)isManaged
{
    return (self.managedConfiguration != nil);
}

- (id)valueForKey:(NSString *)key
{
    return [self.managedConfiguration valueForKey:key];
}

- (id)valueForKeyPath:(NSString *)keyPath
{
    return [self.managedConfiguration valueForKeyPath:keyPath];
}

// ONLY FOR TESTING PURPOSES, SHOULD BE REMOVED ONCE AIRWATCH IS SETUP
- (void)setManagedDictionary:(NSDictionary *)dictionary
{
    self.managedConfiguration = dictionary;
}

@end
