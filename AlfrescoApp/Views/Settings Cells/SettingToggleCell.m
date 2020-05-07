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
 
#import "SettingToggleCell.h"

@interface SettingToggleCell ()

@property (nonatomic, weak) IBOutlet UISwitch *toggle;

- (IBAction)switchToggled:(id)sender;

@end

@implementation SettingToggleCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    [super updateCellForCellInfo:cellInfo value:cellValue delegate:delegate];

    if ([cellValue isKindOfClass:[NSNumber class]])
    {
        BOOL isOn = [(NSNumber *)cellValue boolValue];
        [self.toggle setOn:isOn animated:NO];
    }
    else
    {
        @throw ([NSException exceptionWithName:@"Invalue cell value"
                                        reason:[NSString stringWithFormat:@"Invaild cell value in class %@", NSStringFromClass([self class])]
                                      userInfo:nil]);
    }
}

- (void)setEnabled:(BOOL)enabled
{
    if (enabled)
    {
        self.cellTitle.textColor = [UIColor blackColor];
        self.toggle.enabled = YES;
    }
    else
    {
        self.cellTitle.textColor = [UIColor lightGrayColor];
        self.toggle.enabled = NO;
        self.toggle.on = NO;
    }
}

- (IBAction)switchToggled:(id)sender
{
    NSNumber *isOn = [NSNumber numberWithBool:[self.toggle isOn]];
    [self.delegate valueDidChangeForCell:self preferenceIdentifier:self.preferenceIdentifier value:isOn];
}

@end
