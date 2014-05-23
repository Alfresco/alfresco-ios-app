//
//  NewVersionLabelCell.m
//  AlfrescoApp
//
//  Created by Tauseef Mughal on 23/05/2014.
//  Copyright (c) 2014 Alfresco. All rights reserved.
//

#import "NewVersionLabelCell.h"

@interface NewVersionLabelCell () <UITextFieldDelegate>

@end

@implementation NewVersionLabelCell

- (void)awakeFromNib
{
    self.valueTextField.textColor = [UIColor textDimmedColor];
    [self.valueTextField setValue:[UIColor textDimmedColor] forKeyPath:@"_placeholderLabel.textColor"];
}

#pragma mark - UITextFieldDelegate

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return NO;
}

@end
