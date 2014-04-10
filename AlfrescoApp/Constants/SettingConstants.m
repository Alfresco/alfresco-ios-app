//
//  SettingConstants.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 27/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "SettingConstants.h"

// Notifications
NSString * const kSettingsDidChangeNotification = @"SettingsDidChangeNotification";
NSString * const kSettingChangedFromKey = @"SettingChangedFromKey";
NSString * const kSettingChangedToKey = @"SettingChangedToKey";

// Plist keys
NSString * const kSettingsLocalizedTitleKey = @"LocalizedTitleKey";
NSString * const kSettingsTableViewData = @"SettingsTableViewData";
NSString * const kSettingsGroupHeaderLocalizedKey = @"GroupHeaderLocalizedKey";
NSString * const kSettingsGroupCells = @"GroupCells";
NSString * const kSettingsCellPerferenceIdentifier = @"PreferenceIdentifier";
NSString * const kSettingsCellType = @"Type";
NSString * const kSettingsCellValue = @"Value";
NSString * const kSettingsCellLocalizedTitleKey = @"LocalizedCellTitleKey";

// Cell types
NSString * const kSettingsToggleCell = @"AlfrescoSettingsToggle";
NSString * const kSettingsTextFieldCell = @"AlfrescoSettingsTextField";
NSString * const kSettingsLabelCell = @"AlfrescoSettingsLabel";

// Reuse identifers
NSString * const kSettingsToggleCellReuseIdentifier = @"ToggleCell";
NSString * const kSettingsTextFieldCellReuseIdentifier = @"TextFieldCell";
NSString * const kSettingsLabelCellReuseIdentifier = @"LabelCell";

// Setting identifiers - Please note these are referenced in UserPreferences.plist
NSString * const kSettingsAboutIdentifier = @"SettingsAboutIdentifier";
NSString * const kSettingsSyncOnCellularIdentifier = @"SettingsSyncOnCellularIdentifier";
NSString * const kSettingsSendDiagnosticsIdentifier = @"SettingsSendDiagnosticsIdentifier";
