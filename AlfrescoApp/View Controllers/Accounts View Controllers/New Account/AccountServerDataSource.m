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

#import "AccountServerDataSource.h"
#import "AccountDataSource+Internal.h"

@implementation AccountServerDataSource

#pragma mark - Setup Methods

- (void)setup
{
    [super setup];
    
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
}

- (void)setupTableViewData
{
    TextFieldCell *serverCell = [self serverAdressCell];
    SwitchCell *protocolCell = [self protocolCell];
    protocolCell.valueSwitch.on = YES;
    
    TextFieldCell *portCell = [self portCell];
    portCell.valueTextField.text = kAlfrescoDefaultHTTPSPortString;
    
    TextFieldCell *serviceDocumentCell = [self serviceDocumentCell];
    
    TextFieldCell *realmCell = [self realmCell];
    TextFieldCell *clientID = [self clientIDCell];
    CenterLabelCell *needHelpCell = [self needHelpCell];
    
    self.tableViewData = @[@[serverCell, protocolCell], @[portCell, serviceDocumentCell], @[realmCell, clientID, needHelpCell]];
}

- (void)setupHeaders
{
    self.tableGroupHeaders = @[@"accountdetails.header.authentication", @"accountdetails.header.advanced", @"accountdetails.title.aimssettings"];
}

- (void)setupFooters
{
    self.tableGroupFooters = @[@"", @"", @""];
}

- (void)setAccessibilityIdentifiers
{
    self.serverAddressTextField.accessibilityIdentifier = kNewAccountVCHostnameTextfieldIdentifier;
    self.protocolSwitch.accessibilityIdentifier = kNewAccountVCHTTPSSwitchIdentifier;
    self.portTextField.accessibilityIdentifier = kNewAccountVCPortTextfieldIdentifier;
    self.serviceDocumentTextField.accessibilityIdentifier = kNewAccountVCServiceTextfieldIdentifier;
    self.realmTextField.accessibilityIdentifier = kNewAccountVCRealmTextfieldIdentifier;
    self.clientIDTextField.accessibilityIdentifier = kNewAccountVCClientIDTextfieldIdentifier;
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(enableSaveBarButton:)])
    {
        [self.delegate enableSaveBarButton:[self validateAccountFieldsValues]];
    }
    
    if (textField == self.serverAddressTextField)
    {
        [self.portTextField becomeFirstResponder];
    }
    else if (textField == self.portTextField)
    {
        [self.serviceDocumentTextField becomeFirstResponder];
    }
    else if (textField == self.serviceDocumentTextField)
    {
        [self.realmTextField becomeFirstResponder];
    }
    else if (textField == self.realmTextField)
    {
        [self.clientIDTextField becomeFirstResponder];
    }
    else if (textField == self.clientIDTextField)
    {
        [self.clientIDTextField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - Validation Methods

- (BOOL)validateAccountFieldsValues
{
    BOOL valid = YES;
        
    AccountFormFieldValidation hostname = [self validateHostname];
    AccountFormFieldValidation port = [self validatePort];
    AccountFormFieldValidation serviceDocument = [self validateServiceDocument];
    
    AccountFormFieldValidation validation =  hostname | port | serviceDocument;
    
    if ((validation & AccountFormFieldInvalid) == AccountFormFieldInvalid)
    {
        valid = NO;
    }
    
    return valid;
}

@end
