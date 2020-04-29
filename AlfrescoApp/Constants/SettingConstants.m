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
 
#import "SettingConstants.h"

// Notifications
NSString * const kSettingsDidChangeNotification = @"SettingsDidChangeNotification";
NSString * const kSettingChangedFromKey = @"SettingChangedFromKey";
NSString * const kSettingChangedToKey = @"SettingChangedToKey";

// Plist keys
NSString * const kSettingsLocalizedTitleKey = @"LocalizedTitleKey";
NSString * const kSettingsRestrictionHasPaidAccount = @"HasPaidAccount";
NSString * const kSettingsRestrictionCanSendEmail = @"CanSendEmail";
NSString * const kSettingsRestrictionCanUseTouchID = @"CanUseTouchID";
NSString * const kSettingsTableViewData = @"SettingsTableViewData";
NSString * const kSettingsGroupHeaderLocalizedKey = @"GroupHeaderLocalizedKey";
NSString * const kSettingsGroupFooterLocalizedKey = @"GroupFooterLocalizedKey";
NSString * const kSettingsGroupCells = @"GroupCells";
NSString * const kSettingsCellPreferenceIdentifier = @"PreferenceIdentifier";
NSString * const kSettingsCellType = @"Type";
NSString * const kSettingsCellDefaultValue = @"DefaultValue";
NSString * const kSettingsCellLocalizedTitleKey = @"LocalizedCellTitleKey";
NSString * const kSettingsPasscodeLockTableViewData = @"PasscodeLockTableViewData";
NSString * const kSettingsPasscodeLockLocalizedTitleKey = @"PasscodeLockLocalizedTitleKey";

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
NSString * const kSettingsPasscodeLockIdentifier = @"SettingsPasscodeLockIdentifier";
NSString * const kSettingsChangePasscodeIdentifier = @"SettingsChangePasscodeIdentifier";
NSString * const kSettingsPasscodeTouchIDIdentifier = @"SettingsPasscodeTouchIDIdentifier";
NSString * const kSettingsSendDiagnosticsEnable = @"SettingsDiagnosticsEnable";
NSString * const kSettingsSendFeedbackAlfrescoRecipient = @"mobile@alfresco.com";

// Pin Screen strings
NSString * const kSettingsSecurityPasscodeMissmatchString = @"settings.security.passcode.missmatch"; // "Passcodes didn't match. Try again."
NSString * const kSettingsSecurityPasscodeEnterString = @"settings.security.passcode.enter"; // "Enter your Alfresco Passcode"
NSString * const kSettingsSecurityPasscodeReenterString = @"settings.security.passcode.re-enter"; // "Re-enter your Alfresco Passcode"
NSString * const kSettingsSecurityPasscodeAttemptsOne = @"settings.security.passcode.attempts.1"; // "1 attempt remaining. If this attempt is unsuccessful, Alfresco Mobile will be restarted and your account details, synced files, and local files will be wiped."
NSString * const kSettingsSecurityPasscodeAttemptsMany = @"settings.security.passcode.attempts.several"; // @"%d attempts remaining"
NSString * const kSettingsSecurityPasscodeSetTitle = @"settings.security.passcode.set.title"; // "Set Passcode"
NSString * const kSettingsSecurityPasscodeEnterTitle = @"settings.security.passcode.enter.title"; // "Enter Passcode"

NSString * const kSettingsSecurityPasscodeTurnOn = @"settings.security.passcode.turn.on"; // "Turn Passcode On"
NSString * const kSettingsSecurityPasscodeTurnOff = @"settings.security.passcode.turn.off"; // "Turn Passcode Off"
