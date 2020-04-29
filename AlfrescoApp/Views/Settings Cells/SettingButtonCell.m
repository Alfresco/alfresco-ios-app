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

#import "SettingButtonCell.h"
#import "SettingConstants.h"
#import "PreferenceManager.h"

@interface SettingButtonCell ()

@property (nonatomic, weak) IBOutlet UIButton *cellButton;

@end

@implementation SettingButtonCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    [super updateCellForCellInfo:cellInfo value:cellValue delegate:delegate];
    
    NSString *cellTitle = NSLocalizedString([cellInfo objectForKey:kSettingsCellLocalizedTitleKey], @"Cell text");
    
    if ([[cellInfo objectForKey:kSettingsCellPreferenceIdentifier] isEqualToString:kSettingsSecurityUsePasscodeLockIdentifier])
    {
        BOOL shouldUsePasscodeLock = [[PreferenceManager sharedManager] shouldUsePasscodeLock];
        cellTitle = shouldUsePasscodeLock ? NSLocalizedString(kSettingsSecurityPasscodeTurnOff, @"Turn Passcode Off") : NSLocalizedString(kSettingsSecurityPasscodeTurnOn, @"Turn Passcode On");
    }
    
    self.cellButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.cellButton setTitle:cellTitle forState:UIControlStateNormal];
}

- (void)setEnabled:(BOOL)enabled
{
    self.cellButton.enabled = enabled;
}

- (IBAction)didPressButton:(id)sender
{
    [self.delegate valueDidChangeForCell:self preferenceIdentifier:self.preferenceIdentifier value:nil];
}

@end
