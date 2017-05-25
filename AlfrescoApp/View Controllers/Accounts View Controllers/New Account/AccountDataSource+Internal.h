/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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
#import "AccountManager.h"

@interface AccountDataSource ()

@property (nonatomic, strong) UserAccount *account;

@property (nonatomic, strong) NSArray *tableViewData;
@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;

@property (nonatomic, weak) UITextField *serverAddressTextField;
@property (nonatomic, weak) UITextField *portTextField;
@property (nonatomic, weak) UITextField *serviceDocumentTextField;
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
- (SwitchCell *)protocolCell;
- (LabelCell *)clientCertificateCell;
- (LabelCell *)profileCell;
- (LabelCell *)editMainMenuCell;
- (LabelCell *)accountDetailsCell;

- (BOOL)validateAccountFieldsValues;
- (AccountFormFieldValidation)validateDescription;
- (AccountFormFieldValidation)validateHostname;
- (AccountFormFieldValidation)validatePort;
- (AccountFormFieldValidation)validateServiceDocument;
- (AccountFormFieldValidation)validateUsername;
- (AccountFormFieldValidation)validatePassword;
- (AccountFormFieldValidation)validateProtocol;

@end
