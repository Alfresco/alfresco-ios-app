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

#import "AccountDataSource.h"
#import "UserAccount.h"
#import "TextFieldCell.h"
#import "SwitchCell.h"
#import "LabelCell.h"
#import "CenterLabelCell.h"
#import "ButtonCell.h"
#import "AccountManager.h"

@interface AccountDataSource ()

@property (nonatomic, strong) UserAccount *account;

@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;

@property (nonatomic, weak) UITextField *serverAddressTextField;
@property (nonatomic, weak) UITextField *contentAddressTextField;
@property (nonatomic, weak) UITextField *portTextField;
@property (nonatomic, weak) UITextField *serviceDocumentTextField;
@property (nonatomic, weak) UITextField *realmTextField;
@property (nonatomic, weak) UITextField *clientIDTextField;
@property (nonatomic, weak) UISwitch *protocolSwitch;

@property (nonatomic, weak) UITextField *usernameTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UITextField *descriptionTextField;
@property (nonatomic, weak) UILabel *certificateLabel;

@property (nonatomic, weak) UILabel *profileLabel;
@property (nonatomic, assign) BOOL canReorderMainMenuItems;

- (instancetype)initWithAccount:(UserAccount *)account backupAccount:(UserAccount *)backupAccount configuration:(NSDictionary *)configuration;

- (void)setup;
- (void)setupTableViewData;
- (void)setupHeaders;
- (void)setupFooters;
- (void)setAccessibilityIdentifiers;

- (TextFieldCell *)serverAdressCell;
- (TextFieldCell *)serviceDocumentCell;
- (TextFieldCell *)portCell;
- (TextFieldCell *)usernameCell;
- (TextFieldCell *)passwordCell;
- (TextFieldCell *)descriptionCell;
- (TextFieldCell *)contentAdressCell;
- (TextFieldCell *)clientIDCell;
- (TextFieldCell *)realmCell;
- (SwitchCell *)protocolCell;
- (LabelCell *)clientCertificateCell;
- (LabelCell *)profileCell;
- (LabelCell *)editMainMenuCell;
- (LabelCell *)accountDetailsCell;
- (CenterLabelCell *)logoutCell;
- (CenterLabelCell *)needHelpCell;

- (BOOL)validateAccountFieldsValues;
- (AccountFormFieldValidation)validateDescription;
- (AccountFormFieldValidation)validateHostname;
- (AccountFormFieldValidation)validatePort;
- (AccountFormFieldValidation)validateServiceDocument;
- (AccountFormFieldValidation)validateRealm;
- (AccountFormFieldValidation)validateContent;
- (AccountFormFieldValidation)validateClientID;
- (AccountFormFieldValidation)validateUsername;
- (AccountFormFieldValidation)validatePassword;
- (AccountFormFieldValidation)validateProtocol;

@end
