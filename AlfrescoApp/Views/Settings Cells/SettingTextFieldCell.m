//
//  SettingTextFieldCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 25/09/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

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
    [self.delegate valueDidChangeForCell:self perferenceIdentifier:self.preferenceIdentifier value:self.textField.text];
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
