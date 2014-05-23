//
//  SettingConstants.h
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 27/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

// Notifications
extern NSString * const kSettingsDidChangeNotification;
extern NSString * const kSettingChangedFromKey;
extern NSString * const kSettingChangedToKey;

// Plist keys
extern NSString * const kSettingsLocalizedTitleKey;
extern NSString * const kSettingsTableViewData;
extern NSString * const kSettingsGroupHeaderLocalizedKey;
extern NSString * const kSettingsGroupFooterLocalizedKey;
extern NSString * const kSettingsGroupCells;
extern NSString * const kSettingsCellPreferenceIdentifier;
extern NSString * const kSettingsCellType;
extern NSString * const kSettingsCellValue;
extern NSString * const kSettingsCellLocalizedTitleKey;

// Cell types
extern NSString * const kSettingsToggleCell;
extern NSString * const kSettingsTextFieldCell;
extern NSString * const kSettingsLabelCell;

// Cell reuse identifers
extern NSString * const kSettingsToggleCellReuseIdentifier;
extern NSString * const kSettingsTextFieldCellReuseIdentifier;
extern NSString * const kSettingsLabelCellReuseIdentifier;

// Setting identifiers - Please note these are referenced in UserPreferences.plist
extern NSString * const kSettingsAboutIdentifier;
extern NSString * const kSettingsSyncOnCellularIdentifier;
extern NSString * const kSettingsSendDiagnosticsIdentifier;
