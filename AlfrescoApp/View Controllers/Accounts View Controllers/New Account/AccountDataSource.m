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
#import "AccountDataSource+Internal.h"
#import "Constants.h"
#import "AccountServerDataSource.h"
#import "AccountCredentialsDataSource.h"
#import "AccountSettingsDataSource.h"
#import "AccountSettingsSAMLDataSource.h"
#import "AccountCloudSettingsDataSource.h"
#import "AccountDetailsDataSource.h"
#import "AccountAIMSDataSource.h"
#import "AccountSettingsAIMSDataSource.h"
#import "UserAccount+FileHandling.h"

static NSString * const kServiceDocument = @"/alfresco";
static NSString * const kServerPlaceholder = @"www.example.com";

@interface AccountDataSource () <UITextFieldDelegate>

@property (nonatomic, assign) AccountDataSourceType dataSourceType;
@property (nonatomic, strong) UserAccount *formBackupAccount;

@end

@implementation AccountDataSource

#pragma mark - Class Methods

+ (Class)classForDataSourceType:(AccountDataSourceType)dataSourceType
{
    Class class = NULL;
    
    switch (dataSourceType)
    {
        case AccountDataSourceTypeNewAccountServer:
            class = [AccountServerDataSource class];
            break;
            
        case AccountDataSourceTypeNewAccountCredentials:
            class = [AccountCredentialsDataSource class];
            break;
            
        case AccountDataSourceTypeAccountSettings:
            class = [AccountSettingsDataSource class];
            break;
            
        case AccountDataSourceTypeAccountSettingSAML:
            class = [AccountSettingsSAMLDataSource class];
            break;
            
        case AccountDataSourceTypeCloudAccountSettings:
            class = [AccountCloudSettingsDataSource class];
            break;
            
        case AccountDataSourceTypeAccountDetails:
            class = [AccountDetailsDataSource class];
            break;
        
        case AccountDataSourceTypeNewAccountAIMS:
            class = [AccountAIMSDataSource class];
            break;
        
        case AccountDataSourceTypeAccountSettingAIMS:
            class = [AccountSettingsAIMSDataSource class];
            
        default:
            break;
    }
    
    return class;
}

#pragma mark - Custom Init Methods

- (instancetype)initWithDataSourceType:(AccountDataSourceType)dataSourceType account:(UserAccount *)account backupAccount:(UserAccount *)backupAccount configuration:(NSDictionary *)configuration
{
    Class class = [AccountDataSource classForDataSourceType:dataSourceType];
    self = [[class alloc] initWithAccount:account backupAccount:backupAccount configuration:configuration];
    
    if (self)
    {
        if (dataSourceType)
        {
            self.dataSourceType = dataSourceType;
        }
        
        if (self.dataSourceType != AccountDataSourceTypeAccountDetails)
        {
            [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
        }
    }
    
    return self;
}

- (instancetype)initWithAccount:(UserAccount *)account backupAccount:(UserAccount *)backupAccount configuration:(NSDictionary *)configuration
{
    if (self = [super init])
    {
        self.account = account;
        self.formBackupAccount = backupAccount;
        
        NSNumber *canReorderMenuItems = configuration[kAppConfigurationUserCanEditMainMenuKey];
        
        if (account == [AccountManager sharedManager].selectedAccount)
        {
            self.canReorderMainMenuItems = canReorderMenuItems.boolValue;
        }
        else
        {
            self.canReorderMainMenuItems = [account serverConfigurationExists] == NO;
        }
        
        [self setup];
    }
    
    return self;
}

#pragma mark - Public Methods

- (void)reloadWithAccount:(UserAccount *)account
{
    self.account = account;
    self.formBackupAccount = [account copy];
    
    [self setup];
}

#pragma mark - Setup Methods

- (void)setup
{
    [self setupTableViewData];
    [self setupHeaders];
    [self setupFooters];
    
    [self setAccessibilityIdentifiers];
}

- (void)setupTableViewData
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)setupHeaders
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)setupFooters
{
    [self doesNotRecognizeSelector:_cmd];
}

- (void)setAccessibilityIdentifiers
{
    [self doesNotRecognizeSelector:_cmd];
}

#pragma mark - Cells Methods

- (TextFieldCell *)serverAdressCell
{
    TextFieldCell *serverAddressCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    serverAddressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    serverAddressCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.hostname", @"Server Address");
    serverAddressCell.valueTextField.placeholder = kServerPlaceholder;
    serverAddressCell.valueTextField.returnKeyType = UIReturnKeyNext;
    serverAddressCell.valueTextField.delegate = self;
    serverAddressCell.valueTextField.keyboardType = UIKeyboardTypeURL;
    self.serverAddressTextField = serverAddressCell.valueTextField;
    self.serverAddressTextField.text = self.formBackupAccount.serverAddress;
    
    return serverAddressCell;
}

- (SwitchCell *)protocolCell
{
    SwitchCell *protocolCell = (SwitchCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SwitchCell class]) owner:self options:nil] lastObject];
    protocolCell.selectionStyle = UITableViewCellSelectionStyleNone;
    protocolCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
    self.protocolSwitch = protocolCell.valueSwitch;
    [self.protocolSwitch addTarget:self action:@selector(protocolChanged:) forControlEvents:UIControlEventValueChanged];
    BOOL isHTTPSOn = self.formBackupAccount.protocol ? [self.formBackupAccount.protocol isEqualToString:kProtocolHTTPS] : YES;
    [self.protocolSwitch setOn:isHTTPSOn animated:YES];

    return protocolCell;
}

- (TextFieldCell *)portCell
{
    TextFieldCell *portCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    portCell.selectionStyle = UITableViewCellSelectionStyleNone;
    portCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.port", @"Port Cell Text");
    portCell.valueTextField.returnKeyType = UIReturnKeyNext;
    portCell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
    portCell.valueTextField.delegate = self;
    self.portTextField = portCell.valueTextField;
    self.portTextField.text = self.formBackupAccount.serverPort ? self.formBackupAccount.serverPort : kAlfrescoDefaultHTTPPortString;
    
    return portCell;
}

- (TextFieldCell *)serviceDocumentCell
{
    TextFieldCell *serviceDocumentCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    serviceDocumentCell.selectionStyle = UITableViewCellSelectionStyleNone;
    serviceDocumentCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
    serviceDocumentCell.valueTextField.text = kServiceDocument;
    serviceDocumentCell.valueTextField.returnKeyType = UIReturnKeyDone;
    serviceDocumentCell.valueTextField.delegate = self;
    self.serviceDocumentTextField = serviceDocumentCell.valueTextField;
    self.serviceDocumentTextField.text = self.formBackupAccount.serviceDocument ? self.formBackupAccount.serviceDocument : kServiceDocument;
    
    return serviceDocumentCell;
}

- (TextFieldCell *)usernameCell
{
    TextFieldCell *usernameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    usernameCell.selectionStyle = UITableViewCellSelectionStyleNone;
    usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    usernameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
    usernameCell.valueTextField.returnKeyType = UIReturnKeyNext;
    usernameCell.valueTextField.delegate = self;
    self.usernameTextField = usernameCell.valueTextField;
    self.usernameTextField.text = self.formBackupAccount.username;
    
    return usernameCell;
}

- (TextFieldCell *)passwordCell
{
    TextFieldCell *passwordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    passwordCell.selectionStyle = UITableViewCellSelectionStyleNone;
    passwordCell.titleLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
    passwordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Required");
    passwordCell.valueTextField.returnKeyType = UIReturnKeyNext;
    passwordCell.valueTextField.secureTextEntry = YES;
    passwordCell.valueTextField.delegate = self;
    self.passwordTextField = passwordCell.valueTextField;
    self.passwordTextField.text = self.formBackupAccount.password;
    
    return passwordCell;
}

- (LabelCell *)clientCertificateCell
{
    LabelCell *certificateCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
    certificateCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    certificateCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    certificateCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.client-certificate", @"Client Certificate");
    certificateCell.valueLabel.text = self.account.accountCertificate.summary;
    certificateCell.tag = kTagCertificateCell;
    self.certificateLabel = certificateCell.valueLabel;
    
    return certificateCell;
}

- (TextFieldCell *)descriptionCell
{
    TextFieldCell *descriptionCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    descriptionCell.selectionStyle = UITableViewCellSelectionStyleNone;
    descriptionCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.description", @"Description Cell Text");
    descriptionCell.valueTextField.delegate = self;
    descriptionCell.valueTextField.placeholder = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    descriptionCell.valueTextField.returnKeyType = UIReturnKeyNext;
    descriptionCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
    self.descriptionTextField = descriptionCell.valueTextField;
    self.descriptionTextField.text = self.formBackupAccount.accountDescription;
    
    return descriptionCell;
}

- (TextFieldCell *)contentAdressCell
{
    TextFieldCell *contentAdressCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    contentAdressCell.selectionStyle = UITableViewCellSelectionStyleNone;
    contentAdressCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.contentAdress", @"Content URL");
    contentAdressCell.valueTextField.placeholder = kServerPlaceholder;
    contentAdressCell.valueTextField.returnKeyType = UIReturnKeyNext;
    contentAdressCell.valueTextField.delegate = self;
    contentAdressCell.valueTextField.keyboardType = UIKeyboardTypeURL;
    self.contentAddressTextField = contentAdressCell.valueTextField;
    self.contentAddressTextField.text = self.formBackupAccount.contentAddress;
    
    return contentAdressCell;
}

- (TextFieldCell *)clientIDCell
{
    TextFieldCell *clientIDCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    clientIDCell.selectionStyle = UITableViewCellSelectionStyleNone;
    clientIDCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.clientID", @"Client ID");
    clientIDCell.valueTextField.text = self.formBackupAccount.clientID;
    clientIDCell.valueTextField.returnKeyType = UIReturnKeyDone;
    clientIDCell.valueTextField.delegate = self;
    self.clientIDTextField = clientIDCell.valueTextField;
    self.clientIDTextField.text = self.formBackupAccount.clientID;
    
    return clientIDCell;
}

- (TextFieldCell *)realmCell
{
    TextFieldCell *realmCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    realmCell.selectionStyle = UITableViewCellSelectionStyleNone;
    realmCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.realm", @"Realm");
    realmCell.valueTextField.text = self.formBackupAccount.realm;
    realmCell.valueTextField.returnKeyType = UIReturnKeyDone;
    realmCell.valueTextField.delegate = self;
    self.realmTextField = realmCell.valueTextField;
    self.realmTextField.text = self.formBackupAccount.realm;
    
    return realmCell;
}

- (LabelCell *)profileCell
{
    LabelCell *profileCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
    profileCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    profileCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    profileCell.tag = kTagProfileCell;
    profileCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.profile", @"Profile");
    profileCell.valueLabel.text = self.account.selectedProfileName;
    profileCell.valueLabel.textColor = [UIColor lightGrayColor];
    self.profileLabel = profileCell.valueLabel;
    
    return profileCell;
}

- (LabelCell *)editMainMenuCell
{
    LabelCell *editMainMenuCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
    editMainMenuCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    editMainMenuCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    editMainMenuCell.tag = kTagReorderCell;
    editMainMenuCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.configuration", @"Edit Main Menu");
    editMainMenuCell.valueLabel.text = @"";
    if (!self.canReorderMainMenuItems)
    {
        editMainMenuCell.userInteractionEnabled = NO;
        editMainMenuCell.titleLabel.textColor = [UIColor lightGrayColor];
    }
    
    return editMainMenuCell;
}

- (LabelCell *)accountDetailsCell
{
    LabelCell *accountDetailsCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
    accountDetailsCell.selectionStyle = UITableViewCellSelectionStyleDefault;
    accountDetailsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    accountDetailsCell.tag = kTagAccountDetailsCell;
    accountDetailsCell.titleLabel.text = self.formBackupAccount.accountDescription;
    accountDetailsCell.valueLabel.text = self.formBackupAccount.username;
    accountDetailsCell.valueLabel.textColor = [UIColor lightGrayColor];
    
    return accountDetailsCell;
}

- (CenterLabelCell *)logoutCell
{
    CenterLabelCell *logoutCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
    logoutCell.selectionStyle = UITableViewCellSelectionStyleNone;
    logoutCell.accessoryType = UITableViewCellAccessoryNone;
    logoutCell.tag = kTagLogOutCell;
    logoutCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.logout", @"Log out");
    [logoutCell.titleLabel setTextColor:UIColor.redColor];
    
    return logoutCell;
}

- (CenterLabelCell *)needHelpCell
{
    CenterLabelCell *needHelpCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
    needHelpCell.selectionStyle = UITableViewCellSelectionStyleNone;
    needHelpCell.accessoryType = UITableViewCellAccessoryNone;
    needHelpCell.tag = kTagNeedHelpCell;
    needHelpCell.titleLabel.text = NSLocalizedString(@"help.title", @"Need help");
    [needHelpCell.titleLabel setTextColor:[UIColor colorWithRed:0.22 green:0.67 blue:0.85 alpha:1]];
    return needHelpCell;
}

#pragma mark - UITableViewDataSource Methods

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

#pragma mark - Action Methods

- (void)protocolChanged:(id)sender
{
    NSString *portNumber = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (portNumber.length == 0 || [portNumber isEqualToString:kAlfrescoDefaultHTTPPortString] || [portNumber isEqualToString:kAlfrescoDefaultHTTPSPortString])
    {
        if (self.protocolSwitch.isOn && self.portTextField.text)
        {
            self.portTextField.text = kAlfrescoDefaultHTTPSPortString;
        }
        else
        {
            self.portTextField.text = kAlfrescoDefaultHTTPPortString;
        }
    }
    
    if ([self.delegate respondsToSelector:@selector(enableSaveBarButton:)])
    {
        [self.delegate enableSaveBarButton:[self validateAccountFieldsValues]];
    }
}

#pragma mark - Public Methods

- (void)updateFormBackupAccount
{
    if (self.usernameTextField)
    {
        self.formBackupAccount.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (self.passwordTextField)
    {
        self.formBackupAccount.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (self.descriptionTextField)
    {
        NSString *accountDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *defaultDescription = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
        self.formBackupAccount.accountDescription = (accountDescription.length == 0) ? defaultDescription : accountDescription;
    }
    
    if (self.serverAddressTextField)
    {
        self.formBackupAccount.serverAddress = [self.serverAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (self.portTextField)
    {
        self.formBackupAccount.serverPort = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (self.protocolSwitch)
    {
        self.formBackupAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    }
    
    if (self.serviceDocumentTextField)
    {
        self.formBackupAccount.serviceDocument = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        if (![[self.formBackupAccount.serviceDocument substringToIndex:1] isEqual: @"/"])
        {
            self.formBackupAccount.serviceDocument = [NSString stringWithFormat:@"/%@", self.formBackupAccount.serviceDocument];
        }
    }
    
    if (self.contentAddressTextField) {
        self.formBackupAccount.contentAddress = [self.contentAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
    
    if (self.realmTextField) {
        self.formBackupAccount.realm = [self.realmTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        self.formBackupAccount.realm = ([self.formBackupAccount.realm isEqual:@""]) ? kAlfrescoDefaultAIMSRealmString : self.formBackupAccount.realm;
    }
    
    if (self.clientIDTextField) {
        self.formBackupAccount.clientID = [self.clientIDTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    }
}

#pragma mark - Validation Methods

- (BOOL)validateAccountFieldsValues
{
    [self doesNotRecognizeSelector:_cmd];
    
    return NO;
}

- (AccountFormFieldValidation)validateDescription
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *descriptionString = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (descriptionString.length)
    {
        if ([self.formBackupAccount.accountDescription isEqualToString:self.descriptionTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateHostname
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *hostname = self.serverAddressTextField.text;
    NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
    
    if (hostname && hostnameRange.location != NSNotFound)
    {
        if ([self.formBackupAccount.serverAddress isEqualToString:self.serverAddressTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validatePort
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *port = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([port rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location != NSNotFound)
    {
        if ([self.formBackupAccount.serverPort isEqualToString:self.portTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateServiceDocument
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *serviceDoc = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (serviceDoc.length)
    {
        if ([self.formBackupAccount.serviceDocument isEqualToString:self.serviceDocumentTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateContent
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *hostname = self.contentAddressTextField.text;
    NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
    
    if (hostname && hostnameRange.location != NSNotFound)
    {
        if ([self.formBackupAccount.contentAddress isEqualToString:self.contentAddressTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateRealm
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *serviceDoc = [self.realmTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (serviceDoc.length)
    {
        if ([self.formBackupAccount.realm isEqualToString:self.realmTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateClientID
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *serviceDoc = [self.clientIDTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (serviceDoc.length)
    {
        if ([self.formBackupAccount.clientID isEqualToString:self.clientIDTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateUsername
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if (username.length)
    {
        if ([self.formBackupAccount.username isEqualToString:self.usernameTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validatePassword
{
    AccountFormFieldValidation validation = AccountFormFieldInvalid;
    NSString *password = self.passwordTextField.text;
    
    if (password.length)
    {
        if ([self.formBackupAccount.password isEqualToString:self.passwordTextField.text])
        {
            validation = AccountFormFieldValidWithoutChanges;
        }
        else
        {
            validation = AccountFormFieldValidWithChanges;
        }
    }
    
    return validation;
}

- (AccountFormFieldValidation)validateProtocol
{
    AccountFormFieldValidation validation = AccountFormFieldValidWithChanges;
    
    NSString *protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    if ([self.formBackupAccount.protocol isEqualToString:protocol])
    {
        validation = AccountFormFieldValidWithoutChanges;
    }

    return validation;
}

#pragma mark - Notifications Handlers

- (void)textFieldDidChange:(NSNotification *)notification
{
    if ([self.delegate respondsToSelector:@selector(enableSaveBarButton:)])
    {
        [self.delegate enableSaveBarButton:[self validateAccountFieldsValues]];
    }
}

@end
