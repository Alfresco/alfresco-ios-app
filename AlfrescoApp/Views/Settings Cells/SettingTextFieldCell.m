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
 
#import "SettingTextFieldCell.h"

@interface SettingTextFieldCell () <UITextFieldDelegate>

@property (nonatomic, weak) IBOutlet UITextField *textField;

@end

@implementation SettingTextFieldCell

- (void)updateCellForCellInfo:(NSDictionary *)cellInfo value:(id)cellValue delegate:(id<SettingsCellProtocol>)delegate
{
    [super updateCellForCellInfo:cellInfo value:cellValue delegate:delegate];
    
    if ([cellValue isKindOfClass:[NSString class]])
    {
        self.textField.text = (NSString *)cellValue;
    }
    else
    {
        @throw ([NSException exceptionWithName:@"Invalue cell value"
                                        reason:[NSString stringWithFormat:@"Invaild cell value in class %@", NSStringFromClass([self class])]
                                      userInfo:nil]);
    }
}

#pragma mark - UITextFieldDelegate Functions

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self.delegate valueDidChangeForCell:self preferenceIdentifier:self.preferenceIdentifier value:self.textField.text];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.textField)
    {
        [textField resignFirstResponder];
        return NO;
    }
    return YES;
}

@end
