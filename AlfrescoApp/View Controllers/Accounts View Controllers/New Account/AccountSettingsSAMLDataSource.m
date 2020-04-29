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

#import "AccountSettingsSAMLDataSource.h"
#import "AccountDataSource+Internal.h"

@implementation AccountSettingsSAMLDataSource

#pragma mark - Setup Methods

- (void)setup
{
    [super setup];
    
    self.title = @"";
}

- (void)setupTableViewData
{
    TextFieldCell *descriptionCell = [self descriptionCell];
    TextFieldCell *serverCell = [self serverAdressCell];
    SwitchCell *protocolCell = [self protocolCell];
    TextFieldCell *portCell = [self portCell];
    TextFieldCell *serviceDocumentCell = [self serviceDocumentCell];
    LabelCell *clientCertificateCell = [self clientCertificateCell];
    
    self.tableViewData = @[@[descriptionCell], @[serverCell, protocolCell], @[portCell, serviceDocumentCell, clientCertificateCell]];
}

- (void)setupHeaders
{
    self.tableGroupHeaders = @[@"", @"accountdetails.header.authentication", @"accountdetails.header.advanced"];
}

- (void)setupFooters
{
    self.tableGroupFooters = @[@"", @"", @""];
}

- (void)setAccessibilityIdentifiers
{
    
}

#pragma mark - UITextFieldDelegate Methods

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if ([self.delegate respondsToSelector:@selector(enableSaveBarButton:)])
    {
        [self.delegate enableSaveBarButton:[self validateAccountFieldsValues]];
    }
    
    if (textField == self.descriptionTextField)
    {
        [self.serverAddressTextField becomeFirstResponder];
    }
    else if (textField == self.serverAddressTextField)
    {
        [self.portTextField becomeFirstResponder];
    }
    else if (textField == self.portTextField)
    {
        [self.serviceDocumentTextField becomeFirstResponder];
    }
    else if (textField == self.serviceDocumentTextField)
    {
        [self.serviceDocumentTextField resignFirstResponder];
    }
    
    return YES;
}

#pragma mark - Validation Methods

- (BOOL)validateAccountFieldsValues
{
    BOOL valid = YES;
    
    AccountFormFieldValidation description = [self validateDescription];
    AccountFormFieldValidation hostname = [self validateHostname];
    AccountFormFieldValidation port = [self validatePort];
    AccountFormFieldValidation serviceDocument = [self validateServiceDocument];
    AccountFormFieldValidation protocol = [self validateProtocol];
    
    AccountFormFieldValidation validation = description | hostname | port | serviceDocument | protocol;
    
    if ((validation & AccountFormFieldInvalid) == AccountFormFieldInvalid)
    {
        valid = NO;
    }
    else
    {
        if ((validation & AccountFormFieldValidWithChanges) != AccountFormFieldValidWithChanges)
        {
            valid = NO;
        }
    }
    
    return valid;
}

@end
