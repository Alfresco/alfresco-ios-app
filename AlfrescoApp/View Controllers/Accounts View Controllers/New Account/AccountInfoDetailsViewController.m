/*******************************************************************************
 * Copyright (C) 2005-2015 Alfresco Software Limited.
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

#import "AccountInfoDetailsViewController.h"
#import "TextFieldCell.h"
#import "SwitchCell.h"
#import "LabelCell.h"
#import "CenterLabelCell.h"
#import "UserAccount.h"
#import "ClientCertificateViewController.h"

static NSString * const kServiceDocument = @"/alfresco";
static NSInteger const kTagCertificateCell = 1;

@interface AccountInfoDetailsViewController ()

@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UserAccount *formBackupAccount;

@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;
@property (nonatomic, weak) UITextField *usernameTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UITextField *serverAddressTextField;
@property (nonatomic, weak) UITextField *descriptionTextField;
@property (nonatomic, weak) UITextField *portTextField;
@property (nonatomic, weak) UITextField *serviceDocumentTextField;
@property (nonatomic, weak) UISwitch *protocolSwitch;
@property (nonatomic, weak) UILabel *certificateLabel;
@property (nonatomic, assign) BOOL canEditAccounts;

@property (nonatomic, strong) UITextField *activeTextField;

@end

@implementation AccountInfoDetailsViewController

- (instancetype)initWithAccount:(UserAccount *)account session:(id<AlfrescoSession>)session
{
    self = [super init];
    if (self)
    {
        self.account = account;
        self.session = session;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self constructTableCellsForAlfrescoServer];
}

- (void)constructTableCellsForAlfrescoServer
{
    TextFieldCell *usernameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    usernameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
    usernameCell.valueTextField.returnKeyType = UIReturnKeyNext;
    usernameCell.valueTextField.delegate = self;
    self.usernameTextField = usernameCell.valueTextField;
    self.usernameTextField.text = self.formBackupAccount.username;
    
    TextFieldCell *passwordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
    passwordCell.titleLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
    passwordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Required");
    passwordCell.valueTextField.returnKeyType = UIReturnKeyNext;
    passwordCell.valueTextField.secureTextEntry = YES;
    passwordCell.valueTextField.delegate = self;
    self.passwordTextField = passwordCell.valueTextField;
    self.passwordTextField.text = self.formBackupAccount.password;
    
    TextFieldCell *serverAddressCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    serverAddressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    serverAddressCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.hostname", @"Server Address");
    serverAddressCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
    serverAddressCell.valueTextField.returnKeyType = UIReturnKeyNext;
    serverAddressCell.valueTextField.delegate = self;
    serverAddressCell.valueTextField.keyboardType = UIKeyboardTypeURL;
    self.serverAddressTextField = serverAddressCell.valueTextField;
    self.serverAddressTextField.text = self.formBackupAccount.serverAddress;
    
    SwitchCell *protocolCell = (SwitchCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SwitchCell class]) owner:self options:nil] lastObject];
    protocolCell.selectionStyle = UITableViewCellSelectionStyleNone;
    protocolCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
    self.protocolSwitch = protocolCell.valueSwitch;
    [self.protocolSwitch addTarget:self action:@selector(protocolChanged:) forControlEvents:UIControlEventValueChanged];
    BOOL isHTTPSOn = self.formBackupAccount.protocol ? [self.formBackupAccount.protocol isEqualToString:kProtocolHTTPS] : NO;
//    if (self.activityType == AccountActivityTypeNewAccount)
//    {
//        isHTTPSOn = YES;
//    }
    [self.protocolSwitch setOn:isHTTPSOn animated:YES];
    
    TextFieldCell *portCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    portCell.selectionStyle = UITableViewCellSelectionStyleNone;
    portCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.port", @"Port Cell Text");
    portCell.valueTextField.text = kAlfrescoDefaultHTTPPortString;
    portCell.valueTextField.returnKeyType = UIReturnKeyNext;
    portCell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
    portCell.valueTextField.delegate = self;
    self.portTextField = portCell.valueTextField;
    self.portTextField.text = self.formBackupAccount.serverPort ? self.formBackupAccount.serverPort : kAlfrescoDefaultHTTPPortString;
//    if (self.activityType == AccountActivityTypeNewAccount)
//    {
//        self.portTextField.text = kAlfrescoDefaultHTTPSPortString;
//    }
    
    TextFieldCell *serviceDocumentCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    serviceDocumentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    serviceDocumentCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
    serviceDocumentCell.valueTextField.text = kServiceDocument;
    serviceDocumentCell.valueTextField.returnKeyType = UIReturnKeyDone;
    serviceDocumentCell.valueTextField.delegate = self;
    self.serviceDocumentTextField = serviceDocumentCell.valueTextField;
    self.serviceDocumentTextField.text = self.formBackupAccount.serviceDocument ? self.formBackupAccount.serviceDocument : kServiceDocument;
    
    LabelCell *certificateCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
    certificateCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    certificateCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    certificateCell.tag = kTagCertificateCell;
    certificateCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.client-certificate", @"Client Certificate");
    certificateCell.valueLabel.text = self.account.accountCertificate.summary;
    self.certificateLabel = certificateCell.valueLabel;
    
    /**
     * Selectively disable some controls if required
     */
    for (UIControl *control in @[self.usernameTextField, self.serverAddressTextField, self.descriptionTextField,
                                 self.protocolSwitch, self.portTextField, self.serviceDocumentTextField])
    {
        control.enabled = self.canEditAccounts;
        control.alpha = self.canEditAccounts ? 1.0f : 0.2f;
    }
}

#pragma mark - TableView Datasource
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableViewData.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableViewData[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return NSLocalizedString(self.tableGroupHeaders[section], @"Section Header");
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    return NSLocalizedString(self.tableGroupFooters[section], @"Section Footer");
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableViewData[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.tag == kTagCertificateCell)
    {
        [self.activeTextField resignFirstResponder];
        ClientCertificateViewController *clientCertificate = [[ClientCertificateViewController alloc] initWithAccount:self.formBackupAccount];
        [self.navigationController pushViewController:clientCertificate animated:YES];
    }
}

@end
