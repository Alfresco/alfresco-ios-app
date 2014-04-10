//
//  PreferenceManager.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 26/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "PreferenceManager.h"
#import "SettingConstants.h"

static NSString * const kPreferenceKey = @"kAlfrescoPreferencesKey";

@interface PreferenceManager ()

@property (nonatomic, strong) NSMutableDictionary *preferences;

@end

@implementation PreferenceManager

+ (instancetype)sharedManager
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
        self.preferences = [NSMutableDictionary dictionary];
        [self loadPreferences];
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

- (id)preferenceForIdentifier:(NSString *)preferenceIdentifier
{
    return [self.preferences valueForKey:preferenceIdentifier];
}

- (void)updatePreferenceToValue:(id)obj preferenceIdentifier:(NSString *)preferenceIdentifier
{
    id existingValue = self.preferences[preferenceIdentifier];
    self.preferences[preferenceIdentifier] = obj;
    [self savePreferences];
    [[NSNotificationCenter defaultCenter] postNotificationName:kSettingsDidChangeNotification object:preferenceIdentifier userInfo:@{kSettingChangedFromKey : existingValue, kSettingChangedToKey : obj}];
}

#pragma mark - Private Functions

- (void)loadPreferences
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    NSMutableDictionary *savedPreferenceData = [defaults valueForKey:kPreferenceKey];
    
    if (savedPreferenceData)
    {
        self.preferences = savedPreferenceData;
    }
    else
    {
        NSString *pListPath = [[NSBundle mainBundle] pathForResource:@"UserPreferences" ofType:@"plist"];
        NSDictionary *dictionary = [NSDictionary dictionaryWithContentsOfFile:pListPath];
        
        NSArray *allSettings = [dictionary objectForKey:kSettingsTableViewData];
        
        for (NSDictionary *sectionDictionary in allSettings)
        {
            NSArray *allCellsInfo = [sectionDictionary valueForKey:kSettingsGroupCells];
            for (NSDictionary *cellInfo in allCellsInfo)
            {
                NSString *preferenceIdentifier = [cellInfo valueForKey:kSettingsCellPerferenceIdentifier];
                id defaultValue = [cellInfo valueForKey:kSettingsCellValue];
                
                [self.preferences setObject:defaultValue forKey:preferenceIdentifier];
            }
        }
        [defaults setObject:self.preferences forKey:kPreferenceKey];
        [defaults synchronize];
    }
}

- (void)savePreferences
{
    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
    [defaults setObject:self.preferences forKey:kPreferenceKey];
    [defaults synchronize];
}

@end
