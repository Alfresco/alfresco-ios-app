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
 
#import "PreferenceManager.h"
#import "SettingConstants.h"
#import "SharedConstants.h"

static NSString * const kPreferenceKey = @"kAlfrescoPreferencesKey";

@interface PreferenceManager ()
@property (nonatomic, strong) NSUserDefaults *settingPreferences;
@property (nonatomic, strong) NSMutableDictionary *preferences;
@end

@implementation PreferenceManager

+ (PreferenceManager *)sharedManager
{
    static dispatch_once_t onceToken;
    static PreferenceManager *sharedPreferenceManager = nil;
    dispatch_once(&onceToken, ^{
        sharedPreferenceManager = [[self alloc] init];
    });
    return sharedPreferenceManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        [self loadPreferences];
        [self registerDefaultsFromSettingsBundle];
    }
    return self;
}

- (BOOL)shouldSyncOnCellular
{
    return [[self preferenceForIdentifier:kSettingsSyncOnCellularIdentifier] boolValue];
}

- (BOOL)shouldSendDiagnostics
{
    return [[self preferenceForIdentifier:kSettingsSendDiagnosticsIdentifier] boolValue];
}

- (BOOL)shouldCarryOutFullSearch
{
    return [[self preferenceForIdentifier:kSettingsFullTextSearchIdentifier] boolValue];
}

- (BOOL)shouldProtectFiles
{
    return [[self preferenceForIdentifier:kSettingsFileProtectionIdentifier] boolValue];
}

- (BOOL)isSendDiagnosticsEnable
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    return [defaults boolForKey:kSettingsSendDiagnosticsEnable];
}

- (BOOL)shouldUsePasscodeLock
{
    return [[self preferenceForIdentifier:kSettingsSecurityUsePasscodeLockIdentifier] boolValue];
}

- (id)preferenceForIdentifier:(NSString *)preferenceIdentifier
{
    return [self.preferences valueForKey:preferenceIdentifier];
}

- (void)updatePreferenceToValue:(id)obj preferenceIdentifier:(NSString *)preferenceIdentifier
{
    id existingValue = self.preferences[preferenceIdentifier];
    
    // MOBILE-3045: Devices running iOS 8 refuse to recognise the preferences property as mutable so re-create
    self.preferences = [NSMutableDictionary dictionaryWithDictionary:self.preferences];
    self.preferences[preferenceIdentifier] = obj;
    
    if ([preferenceIdentifier isEqualToString:kSettingsSecurityUsePasscodeLockIdentifier])
    {
        if ([obj boolValue] == NO)
        {
            self.preferences[kSettingsPasscodeTouchIDIdentifier] = @NO;
        }
    }
    
    [self savePreferences];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingsDidChangeNotification object:preferenceIdentifier userInfo:@{kSettingChangedFromKey : existingValue, kSettingChangedToKey : obj}];
}

- (id)settingsPreferenceForIdentifier:(NSString *)preferenceIdentifier
{
    return [self.settingPreferences valueForKey:preferenceIdentifier];
}

- (void)updateSettingsPreferenceToValue:(id)object preferenceIdentifier:(NSString *)preferenceIdentifier
{
    [self.settingPreferences setObject:object forKey:preferenceIdentifier];
    [self.settingPreferences synchronize];
}

#pragma mark - Private Functions

- (void)loadPreferences
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    if ([userDefaults objectForKey:kIsAppFirstLaunch] == nil)
    {
        [defaults removeObjectForKey:kPreferenceKey];
    }
    
    NSMutableDictionary *savedPreferenceData = [defaults valueForKey:kPreferenceKey];
    self.preferences = savedPreferenceData ?: [NSMutableDictionary dictionary];

    NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"UserPreferences" ofType:@"plist"];
    NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:pListPath];
    
    __weak typeof(self) weakSelf = self;
    
    void (^addPreferences)(NSArray *) = ^void(NSArray *settingsArray){
        for (NSDictionary *sectionDictionary in settingsArray)
        {
            NSArray *allCellsInfo = sectionDictionary[kSettingsGroupCells];
            for (NSDictionary *cellInfo in allCellsInfo)
            {
                NSString *preferenceIdentifier = cellInfo[kSettingsCellPreferenceIdentifier];
                
                // Check for missing preferences, or preferences of the wrong type
                if (weakSelf.preferences[preferenceIdentifier] == nil ||
                    ![weakSelf.preferences[preferenceIdentifier] isKindOfClass:[cellInfo[kSettingsCellDefaultValue] class]])
                {
                    // Set the default value
                    // MOBILE-3045: Devices running iOS 8 refuse to recognise the preferences property as mutable so re-create
                    weakSelf.preferences = [NSMutableDictionary dictionaryWithDictionary:self.preferences];
                    weakSelf.preferences[preferenceIdentifier] = cellInfo[kSettingsCellDefaultValue];
                }
            }
        }
    };

    NSArray *allSettings = dictionary[kSettingsTableViewData];
    addPreferences(allSettings);
    
    // Add Passcode preferences
    NSArray *passcodeSettingsArray = dictionary[kSettingsPasscodeLockTableViewData];
    addPreferences(passcodeSettingsArray);

    [defaults setObject:self.preferences forKey:kPreferenceKey];
    [defaults synchronize];
}

- (void)savePreferences
{
    NSUserDefaults *defaults = [[NSUserDefaults alloc] initWithSuiteName:kAlfrescoMobileGroup];
    [defaults setObject:self.preferences forKey:kPreferenceKey];
    [defaults synchronize];
}

- (void)registerDefaultsFromSettingsBundle
{
    NSString *settingsBundle = [[NSBundle mainBundle] pathForResource:@"Settings" ofType:@"bundle"];
    
    if(!settingsBundle)
    {
        AlfrescoLogError(@"Could not find Settings.bundle");
        return;
    }
    
    NSDictionary *settings = [NSDictionary dictionaryWithContentsOfFile:[settingsBundle stringByAppendingPathComponent:@"Root.plist"]];
    NSArray *preferences = [settings objectForKey:@"PreferenceSpecifiers"];
    
    NSMutableDictionary *defaultsToRegister = [[NSMutableDictionary alloc] initWithCapacity:[preferences count]];
    for(NSDictionary *prefSpecification in preferences)
    {
        NSString *key = prefSpecification[@"key"];
        
        if(key)
        {
            defaultsToRegister[key] = prefSpecification[@"DefaultValue"];
        }
    }
    
    self.settingPreferences = [[NSUserDefaults alloc] init];
    [self.settingPreferences registerDefaults:defaultsToRegister];
    [self.settingPreferences synchronize];
}

@end
