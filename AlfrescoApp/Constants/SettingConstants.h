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
  
// Notifications
extern NSString * const kSettingsDidChangeNotification;
extern NSString * const kSettingChangedFromKey;
extern NSString * const kSettingChangedToKey;

// Plist keys
extern NSString * const kSettingsLocalizedTitleKey;
extern NSString * const kSettingsRestrictionHasPaidAccount;
extern NSString * const kSettingsRestrictionCanSendEmail;
extern NSString * const kSettingsRestrictionCanUseTouchID;
extern NSString * const kSettingsTableViewData;
extern NSString * const kSettingsGroupHeaderLocalizedKey;
extern NSString * const kSettingsGroupFooterLocalizedKey;
extern NSString * const kSettingsGroupCells;
extern NSString * const kSettingsCellPreferenceIdentifier;
extern NSString * const kSettingsCellType;
extern NSString * const kSettingsCellDefaultValue;
extern NSString * const kSettingsCellLocalizedTitleKey;
extern NSString * const kSettingsPasscodeLockTableViewData;
extern NSString * const kSettingsPasscodeLockLocalizedTitleKey;

// Cell types
extern NSString * const kSettingsToggleCell;
extern NSString * const kSettingsTextFieldCell;
extern NSString * const kSettingsLabelCell;
extern NSString * const kSettingsButtonCell;

// Cell reuse identifers
extern NSString * const kSettingsToggleCellReuseIdentifier;
extern NSString * const kSettingsTextFieldCellReuseIdentifier;
extern NSString * const kSettingsLabelCellReuseIdentifier;
extern NSString * const kSettingsButtonCellReuseIdentifier;

// Setting identifiers: Note these are referenced in UserPreferences.plist
extern NSString * const kSettingsAboutIdentifier;
extern NSString * const kSettingsSyncOnCellularIdentifier;
extern NSString * const kSettingsSendDiagnosticsIdentifier;
extern NSString * const kSettingsFileProtectionIdentifier;
extern NSString * const kSettingsResetAccountsIdentifier;
extern NSString * const kSettingsResetEntireAppIdentifier;
extern NSString * const kSettingsFullTextSearchIdentifier;
extern NSString * const kSettingsSendFeedbackIdentifier;
extern NSString * const kSettingsPasscodeLockIdentifier;
extern NSString * const kSettingsChangePasscodeIdentifier;
extern NSString * const kSettingsPasscodeTouchIDIdentifier;
extern NSString * const kSettingsSendDiagnosticsEnable;
extern NSString * const kSettingsSendFeedbackAlfrescoRecipient;

static NSUInteger const kCellLeftInset = 10;

// Pin Screen strings
extern NSString * const kSettingsSecurityPasscodeMissmatchString; // "Passcodes didn't match. Try again."
extern NSString * const kSettingsSecurityPasscodeEnterString; // "Enter your Alfresco Passcode"
extern NSString * const kSettingsSecurityPasscodeReenterString; // "Re-enter your Alfresco Passcode"
extern NSString * const kSettingsSecurityPasscodeAttemptsOne; // "1 attempt remaining. If this attempt is unsuccessful, Alfresco Mobile will be restarted and your account details, synced files, and local files will be wiped."
extern NSString * const kSettingsSecurityPasscodeAttemptsMany; // "%d attempts remaining"
extern NSString * const kSettingsSecurityPasscodeSetTitle; // "Set Passcode"
extern NSString * const kSettingsSecurityPasscodeEnterTitle; // "Enter Passcode"

extern NSString * const kSettingsSecurityPasscodeTurnOn; //"Turn Passcode On"
extern NSString * const kSettingsSecurityPasscodeTurnOff; //"Turn Passcode Off"

typedef NS_ENUM(NSUInteger, SettingsType)
{
    SettingsTypeGeneral,
    SettingsTypePasscode,
};
