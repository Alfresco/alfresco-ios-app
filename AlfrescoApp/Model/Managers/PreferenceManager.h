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

@interface PreferenceManager : NSObject

+ (PreferenceManager *)sharedManager;

// Convenience Methods
- (BOOL)shouldSyncOnCellular;
- (BOOL)shouldSendDiagnostics;
- (BOOL)shouldCarryOutFullSearch;
- (BOOL)shouldProtectFiles;
- (BOOL)isSendDiagnosticsEnable;
- (BOOL)shouldUsePasscodeLock;

// Accessors and Modifiers
- (id)preferenceForIdentifier:(NSString *)preferenceIdentifier;
- (void)updatePreferenceToValue:(id)obj preferenceIdentifier:(NSString *)preferenceIdentifier;

- (id)settingsPreferenceForIdentifier:(NSString *)preferenceIdentifier;
- (void)updateSettingsPreferenceToValue:(id)object preferenceIdentifier:(NSString *)preferenceIdentifier;

@end
