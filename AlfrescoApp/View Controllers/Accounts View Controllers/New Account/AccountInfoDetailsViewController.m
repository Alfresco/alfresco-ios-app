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
#import "UniversalDevice.h"

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
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation AccountInfoDetailsViewController

- (instancetype)initWithAccount:(UserAccount *)account configuration:(NSDictionary *)configuration session:(id<AlfrescoSession>)session delegate:(id<AccountInfoDetailsDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.account = account;
        self.session = session;
        self.formBackupAccount = [self.account copy];
        self.delegate = delegate;
        
        NSNumber *canEditAccounts = configuration[kAppConfigurationCanEditAccountsKey];
        self.canEditAccounts = (canEditAccounts) ? canEditAccounts.boolValue : YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self constructTableCellsForAlfrescoServer];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    self.formBackupAccount.username = self.usernameTextField.text;
    self.formBackupAccount.password = self.passwordTextField.text;
    self.formBackupAccount.serverAddress = self.serverAddressTextField.text;
    self.formBackupAccount.accountDescription = self.descriptionTextField.text;
    self.formBackupAccount.serverPort = self.portTextField.text;
    self.formBackupAccount.serviceDocument = self.serviceDocumentTextField.text;
    self.formBackupAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    
    [self.delegate accountInfoChanged:self.formBackupAccount];
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
    for (UIControl *control in @[self.usernameTextField, self.serverAddressTextField, self.protocolSwitch, self.portTextField, self.serviceDocumentTextField])
    {
        control.enabled = self.canEditAccounts;
        control.alpha = self.canEditAccounts ? 1.0f : 0.2f;
    }
    
    self.tableViewData = [NSMutableArray arrayWithArray:@[ @[usernameCell, passwordCell, serverAddressCell, protocolCell],
                                                            @[portCell, serviceDocumentCell, certificateCell]]];
    self.tableGroupHeaders = @[@"",@"accountdetails.header.advanced"];
    self.tableGroupFooters = @[@"",@""];
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

#pragma mark - UITextFieldDelegate Functions

- (void)protocolChanged:(id)sender
{
    NSString *portNumber = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([portNumber isEqualToString:@""] || [portNumber isEqualToString:kAlfrescoDefaultHTTPPortString] || [portNumber isEqualToString:kAlfrescoDefaultHTTPSPortString])
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
    
//    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
}

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.canEditAccounts || textField == self.passwordTextField;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    self.activeTextField = textField;
    
    [self showActiveTextField];
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    self.activeTextField = nil;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
//    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
    
    if (textField == self.usernameTextField)
    {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField)
    {
        [self.serverAddressTextField becomeFirstResponder];
    }
    else if (textField == self.serverAddressTextField)
    {
        [self.descriptionTextField becomeFirstResponder];
    }
    else if (textField == self.descriptionTextField)
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

- (void)textFieldDidChange:(NSNotification *)notification
{
//    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
}

#pragma mark - UIKeyboard Notifications

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary *info = [aNotification userInfo];
    CGRect keyBoardFrame = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    CGFloat height = [self.view convertRect:keyBoardFrame fromView:self.view.window].size.height;
    
    if (IS_IPAD)
    {
        height = [self calculateBottomInsetForTextViewUsingKeyboardFrame:keyBoardFrame];
    }
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height -= keyBoardFrame.size.height;
    self.tableViewVisibleRect = tableViewFrame;
    [self showActiveTextField];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
}

- (CGFloat)calculateBottomInsetForTextViewUsingKeyboardFrame:(CGRect)keyboardFrame
{
    CGRect keyboardRectForView = [self.view convertRect:keyboardFrame fromView:self.view.window];
    CGSize kbSize = keyboardRectForView.size;
    UIView *mainAppView = [[UniversalDevice revealViewController] view];
    CGRect viewFrame = self.view.frame;
    CGRect viewFrameRelativeToMainController = [self.view convertRect:viewFrame toView:mainAppView];
    
    return (viewFrameRelativeToMainController.origin.y + viewFrame.size.height) - (mainAppView.frame.size.height - kbSize.height);
}

- (void)showActiveTextField
{
    UITableViewCell *cell = (UITableViewCell*)[self.activeTextField superview];
    
    BOOL foundTableViewCell = NO;
    while (cell && !foundTableViewCell)
    {
        if (![cell isKindOfClass:[UITableViewCell class]])
        {
            cell = (UITableViewCell *)cell.superview;
        }
        else
        {
            foundTableViewCell = YES;
        }
    }
    
    if (!CGRectContainsPoint(self.tableViewVisibleRect, cell.frame.origin) )
    {
        [self.tableView scrollRectToVisible:cell.frame animated:YES];
    }
}

/**
 validateAccountFieldsValues
 checks the validity of hostname, port and username in terms of characters entered.
 */
- (BOOL)validateAccountFieldsValuesForServer
{
    BOOL didChangeAndIsValid = YES;
    BOOL hasAccountPropertiesChanged = NO;//(self.activityType == AccountActivityTypeLoginFailed);
    
    if (self.account.accountType == UserAccountTypeOnPremise)
    {
        // User input validations
        NSString *hostname = self.serverAddressTextField.text;
        NSString *port = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        NSString *password = self.passwordTextField.text;
        NSString *serviceDoc = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
        
        BOOL hostnameError = ( !hostname || (hostnameRange.location == NSNotFound) );
        BOOL portIsInvalid = ([port rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location == NSNotFound);
        BOOL usernameError = [username isEqualToString:@""];
        BOOL passwordError = [password isEqualToString:@""] || password == nil;
        BOOL serviceDocError = [serviceDoc isEqualToString:@""];
        
        didChangeAndIsValid = !hostnameError && !portIsInvalid && !usernameError && !passwordError && !serviceDocError;
        
        if (didChangeAndIsValid)
        {
            if (![self.formBackupAccount.username isEqualToString:self.usernameTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            if (![self.formBackupAccount.password isEqualToString:self.passwordTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            if (![self.formBackupAccount.serverAddress isEqualToString:self.serverAddressTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            if (![self.formBackupAccount.accountDescription isEqualToString:self.descriptionTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            if (![self.formBackupAccount.serverPort isEqualToString:self.portTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            if (![self.formBackupAccount.serviceDocument isEqualToString:self.serviceDocumentTextField.text])
            {
                hasAccountPropertiesChanged = YES;
            }
            
            NSString *protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
            if (![self.formBackupAccount.protocol isEqualToString:protocol])
            {
                hasAccountPropertiesChanged = YES;
            }
            
            NSString *certificateSummary = self.formBackupAccount.accountCertificate.summary ? self.formBackupAccount.accountCertificate.summary : @"";
            NSString *certificateLabelText = self.certificateLabel.text ? self.certificateLabel.text : @"";
            if (![certificateSummary isEqualToString:certificateLabelText])
            {
                hasAccountPropertiesChanged = YES;
            }
            
            didChangeAndIsValid = hasAccountPropertiesChanged;
        }
    }
    else
    {
        if (![self.formBackupAccount.accountDescription isEqualToString:self.descriptionTextField.text])
        {
            hasAccountPropertiesChanged = YES;
        }
        didChangeAndIsValid = hasAccountPropertiesChanged;
    }
    return didChangeAndIsValid;
}

@end
