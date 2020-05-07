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

#import "AccountAIMSDataSource.h"
#import "AccountDataSource+Internal.h"

@implementation AccountAIMSDataSource

#pragma mark - Setup Methods

- (void)setup
{
    [super setup];
    
    self.title = NSLocalizedString(@"accountdetails.title.aims", @"SSO");
}

- (void)setupTableViewData
{
    TextFieldCell *contentCell = [self contentAdressCell];
    TextFieldCell *descriptionCell = [self descriptionCell];
    
    self.tableViewData = @[@[contentCell, descriptionCell]];
}

- (void)setupHeaders
{
    self.tableGroupHeaders = @[@"accountdetails.header.authentication", @"accountdetails.header.advanced"];
}

- (void)setupFooters
{
    self.tableGroupFooters = @[@"", @"",];
}

- (void)setAccessibilityIdentifiers
{
    self.contentAddressTextField.accessibilityIdentifier = kNewAccountVCContentTextfieldIdentifier;
    self.descriptionTextField.accessibilityIdentifier = kNewAccountVCDescriptionTextfieldIdentifier;
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(enableSaveBarButton:)])
    {
        [self.delegate enableSaveBarButton:[self validateAccountFieldsValues]];
    }
    
    if (textField == self.contentAddressTextField)
    {
        [self.descriptionTextField becomeFirstResponder];
    }
    else if (textField == self.descriptionTextField)
    {
        [self.descriptionTextField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - Validation Methods

- (BOOL)validateAccountFieldsValues
{
    BOOL valid = YES;
        
    AccountFormFieldValidation content = [self validateContent];
    
    AccountFormFieldValidation validation =  content;
    
    if ((validation & AccountFormFieldInvalid) == AccountFormFieldInvalid)
    {
        valid = NO;
    }
    
    return valid;
}

@end
