/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "SettingConstants.h"

// Notifications
NSString * const kSettingsDidChangeNotification = @"SettingsDidChangeNotification";
NSString * const kSettingChangedFromKey = @"SettingChangedFromKey";
NSString * const kSettingChangedToKey = @"SettingChangedToKey";

// Plist keys
NSString * const kSettingsLocalizedTitleKey = @"LocalizedTitleKey";
NSString * const kSettingsPaidAccountsOnly = @"PaidAccountsOnly";
NSString * const kSettingsTableViewData = @"SettingsTableViewData";
NSString * const kSettingsGroupHeaderLocalizedKey = @"GroupHeaderLocalizedKey";
NSString * const kSettingsGroupFooterLocalizedKey = @"GroupFooterLocalizedKey";
NSString * const kSettingsGroupCells = @"GroupCells";
NSString * const kSettingsCellPreferenceIdentifier = @"PreferenceIdentifier";
NSString * const kSettingsCellType = @"Type";
NSString * const kSettingsCellDefaultValue = @"DefaultValue";
NSString * const kSettingsCellLocalizedTitleKey = @"LocalizedCellTitleKey";

// Cell types
NSString * const kSettingsToggleCell = @"AlfrescoSettingsToggle";
NSString * const kSettingsTextFieldCell = @"AlfrescoSettingsTextField";
NSString * const kSettingsLabelCell = @"AlfrescoSettingsLabel";
NSString * const kSettingsButtonCell = @"AlfrescoSettingsButton";

// Reuse identifers
NSString * const kSettingsToggleCellReuseIdentifier = @"ToggleCell";
NSString * const kSettingsTextFieldCellReuseIdentifier = @"TextFieldCell";
NSString * const kSettingsLabelCellReuseIdentifier = @"LabelCell";
NSString * const kSettingsButtonCellReuseIdentifier = @"ButtonCell";

// Setting identifiers: Note these are referenced in UserPreferences.plist
NSString * const kSettingsAboutIdentifier = @"SettingsAboutIdentifier";
NSString * const kSettingsSyncOnCellularIdentifier = @"SettingsSyncOnCellularIdentifier";
NSString * const kSettingsSendDiagnosticsIdentifier = @"SettingsSendDiagnosticsIdentifier";
NSString * const kSettingsFileProtectionIdentifier = @"SettingsFileProtectionIdentifier";
NSString * const kSettingsResetAccountsIdentifier = @"SettingsResetAccountsIdentifier";
NSString * const kSettingsResetEntireAppIdentifier = @"SettingsResetEntireAppIdentifier";
NSString * const kSettingsFullTextSearchIdentifier = @"SettingsFullTextSearchIdentifier";
NSString * const kSettingsSendFeedbackIdentifier = @"SettingsSendFeedbackIdentifier";

NSString * const kSettingsSendDiagnosticsEnable = @"SettingsDiagnosticsEnable";
NSString * const kSettingsSendFeedbackAlfrescoRecipient = @"mobile@alfresco.com";