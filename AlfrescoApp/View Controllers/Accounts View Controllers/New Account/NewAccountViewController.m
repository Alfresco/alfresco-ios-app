/*******************************************************************************
 * Copyright (C) 2005-2016 Alfresco Software Limited.
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

#import "NewAccountViewController.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "Constants.h"
#import "TextFieldCell.h"
#import "SwitchCell.h"
#import "LabelCell.h"
#import "CenterLabelCell.h"
#import "NavigationViewController.h"
#import "ClientCertificateViewController.h"
#import "UniversalDevice.h"
#import "ConnectionDiagnosticViewController.h"
#import "MainMenuReorderViewController.h"
#import "MainMenuLocalConfigurationBuilder.h"
#import "ProfileSelectionViewController.h"
#import "RealmSyncManager.h"
#import "UserAccount+FileHandling.h"
#import "AlfrescoProfileConfig.h"

static NSString * const kServiceDocument = @"/alfresco";

static NSInteger const kTagCertificateCell = 1;
static NSInteger const kTagReorderCell = 2;
static NSInteger const kTagProfileCell = 3;

@interface NewAccountViewController ()

@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;
@property (nonatomic, weak) UITextField *usernameTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UITextField *serverAddressTextField;
@property (nonatomic, weak) UITextField *descriptionTextField;
@property (nonatomic, weak) UITextField *portTextField;
@property (nonatomic, weak) UITextField *serviceDocumentTextField;
@property (nonatomic, weak) UILabel *certificateLabel;
@property (nonatomic, weak) UILabel *profileLabel;
@property (nonatomic, weak) UISwitch *protocolSwitch;
@property (nonatomic, weak) UISwitch *syncPreferenceSwitch;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UserAccount *formBackupAccount;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, assign) BOOL canEditAccounts;
@property (nonatomic, assign) BOOL canReorderMainMenuItems;

@end

@implementation NewAccountViewController

- (instancetype)initWithAccount:(UserAccount *)account configuration:(NSDictionary *)configuration
{
    return [self initWithAccount:account configuration:configuration session:nil];
}

- (instancetype)initWithAccount:(UserAccount *)account configuration:(NSDictionary *)configuration session:(id<AlfrescoSession>)session
{
    self = [super initWithSession:session];
    if (self)
    {
        if (account)
        {
            self.account = account;
        }
        else
        {
            self.account = [[UserAccount alloc] initWithAccountType:UserAccountTypeOnPremise];
        }
        self.formBackupAccount = [self.account copy];
        self.configuration = configuration;
        NSNumber *canEditAccounts = configuration[kAppConfigurationCanEditAccountsKey];
        self.canEditAccounts = (canEditAccounts) ? canEditAccounts.boolValue : YES;
        
        NSNumber *canReorderMenuItems = configuration[kAppConfigurationUserCanEditMainMenuKey];
        self.canReorderMainMenuItems = ((canReorderMenuItems.boolValue && account == [AccountManager sharedManager].selectedAccount) || [account serverConfigurationExists]) ? canReorderMenuItems.boolValue : YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonClicked:)];
    [self.navigationItem setRightBarButtonItem:self.saveButton];
    self.saveButton.enabled = NO;
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.allowsPullToRefresh = NO;
    [self constructTableCellsForAlfrescoServer];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.certificateLabel.text = self.formBackupAccount.accountCertificate.summary;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(textFieldDidChange:)
                                                 name:UITextFieldTextDidChangeNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWasShown:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(profileDidChange:)
                                                 name:kAlfrescoConfigProfileDidChangeNotification
                                               object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewAccountCreateCredentials];
    
    // A small delay is necessary in order for the keyboard animation not to clash with the appear animation
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.usernameTextField becomeFirstResponder];
    });
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self updateFormBackupAccount];
}

#pragma mark - private Methods

- (void)updateFormBackupAccount
{
    NSString *accountDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *defaultDescription = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    
    self.formBackupAccount.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.accountDescription = (accountDescription.length == 0) ? defaultDescription : accountDescription;
    self.formBackupAccount.serverAddress = [self.serverAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.serverPort = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    self.formBackupAccount.serviceDocument = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
}

/**
 validateAccountFieldsValues
 checks the validity of hostname, port and username in terms of characters entered.
 */
- (BOOL)validateAccountFieldsValuesForServer
{
    BOOL didChangeAndIsValid = YES;
    BOOL hasAccountPropertiesChanged = NO;
    
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
        BOOL usernameError = username.length == 0;
        BOOL passwordError = password.length == 0;
        BOOL serviceDocError = serviceDoc.length == 0;
        
        didChangeAndIsValid = !hostnameError && !portIsInvalid && !usernameError && !passwordError && !serviceDocError;
    }
    else
    {
        if (![self.formBackupAccount.accountDescription isEqualToString:self.descriptionTextField.text])
        {
            hasAccountPropertiesChanged = YES;
        }
        if (!(self.formBackupAccount.isSyncOn == self.syncPreferenceSwitch.isOn))
        {
            hasAccountPropertiesChanged = YES;
        }
        didChangeAndIsValid = hasAccountPropertiesChanged;
    }
    return didChangeAndIsValid;
}

- (void)validateAccountOnServerWithCompletionBlock:(void (^)(BOOL successful, id<AlfrescoSession> session))completionBlock
{
    [self updateFormBackupAccount];
    void (^updateAccountInfo)(UserAccount *) = ^(UserAccount *temporaryAccount)
    {
        self.account.username = temporaryAccount.username;
        self.account.password = temporaryAccount.password;
        self.account.accountDescription = temporaryAccount.accountDescription;
        self.account.serverAddress = temporaryAccount.serverAddress;
        self.account.serverPort = temporaryAccount.serverPort;
        self.account.protocol = temporaryAccount.protocol;
        self.account.serviceDocument = temporaryAccount.serviceDocument;
        self.account.accountCertificate = temporaryAccount.accountCertificate;
        self.account.paidAccount = temporaryAccount.isPaidAccount;
    };
    
    [self showHUD];
    [[LoginManager sharedManager] authenticateOnPremiseAccount:self.formBackupAccount password:self.formBackupAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        [self hideHUD];
        if (successful)
        {
            updateAccountInfo(self.formBackupAccount);
            completionBlock(successful, alfrescoSession);
        }
        else
        {
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account")
                                                                                     message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Login Failed Message")
                                                                              preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *doneAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                 style:UIAlertActionStyleCancel
                                                               handler:nil];
            [alertController addAction:doneAction];
            UIAlertAction *retryAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"connectiondiagnostic.button.retrywithdiagnostic", @"Retry with diagnostic")
                                                                  style:UIAlertActionStyleDefault
                                                                handler:^(UIAlertAction * _Nonnull action) {
                                                                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ConnectionDiagnosticStoryboard" bundle:[NSBundle mainBundle]];
                                                                    ConnectionDiagnosticViewController *viewController = (ConnectionDiagnosticViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ConnectionDiagnosticSBID"];
                                                                    [viewController setupWithParent:self andSelector:@selector(retryLoginForConnectionDiagnostic)];
                                                                    [self.navigationController pushViewController:viewController animated:YES];
                                                                }];
            [alertController addAction:retryAction];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }];
}

- (void)saveButtonClicked:(id)sender
{
    if (self.account.accountType == UserAccountTypeOnPremise)
    {
        [self validateAccountOnServerWithCompletionBlock:^(BOOL successful, id<AlfrescoSession> session) {
            if (successful)
            {
                [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryAccount
                                                                  action:kAnalyticsEventActionCreate
                                                                   label:kAnalyticsEventLabelOnPremise
                                                                   value:@1];
                
                AccountManager *accountManager = [AccountManager sharedManager];
                [[RealmSyncManager sharedManager] realmForAccount:self.account.accountIdentifier];
                
                if (accountManager.totalNumberOfAddedAccounts == 0)
                {
                    [accountManager selectAccount:self.account selectNetwork:nil alfrescoSession:session];
                }
                else if (accountManager.selectedAccount == self.account)
                {
                    [[RealmManager sharedManager] changeDefaultConfigurationForAccount:self.account completionBlock:^{
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:session userInfo:nil];
                    }];
                }
                
                if ([self.delegate respondsToSelector:@selector(newAccountViewController:willDismissAfterAddingAccount:)])
                {
                    [self.delegate newAccountViewController:self willDismissAfterAddingAccount:self.account];
                }
                
                [self dismissViewControllerAnimated:YES completion:^{
                    [accountManager addAccount:self.account];
                    
                    if ([self.delegate respondsToSelector:@selector(newAccountViewController:didDismissAfterAddingAccount:)])
                    {
                        [self.delegate newAccountViewController:self didDismissAfterAddingAccount:self.account];
                    }
                }];
            }
        }];
    }
    else
    {
        [self updateFormBackupAccount];
        
        self.account.accountDescription = self.formBackupAccount.accountDescription;
        [[AccountManager sharedManager] saveAccountsToKeychain];
        
        [self dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
        }];
    }
}

- (void)cancel:(id)sender
{
    SEL newAccountViewControllerWillDismissSelector = NSSelectorFromString(@"accountInfoViewControllerWillDismiss:");
    if ([self.delegate respondsToSelector:newAccountViewControllerWillDismissSelector])
    {
        [self.delegate newAccountViewControllerWillDismiss:self];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        SEL newAccountViewControllerDidDismissSelector = NSSelectorFromString(@"accountInfoViewControllerDidDismiss:");
        if ([self.delegate respondsToSelector:newAccountViewControllerDidDismissSelector])
        {
            [self.delegate newAccountViewControllerDidDismiss:self];
        }
    }];
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
    else if (cell.tag == kTagReorderCell)
    {
        MainMenuReorderViewController *reorderController = [[MainMenuReorderViewController alloc] initWithAccount:self.account session:self.session];
        [self.navigationController pushViewController:reorderController animated:YES];
    }
    else if (cell.tag == kTagProfileCell)
    {
        ProfileSelectionViewController *profileSelectionViewController = [[ProfileSelectionViewController alloc] initWithAccount:self.account session:self.session];
        [self.navigationController pushViewController:profileSelectionViewController animated:YES];
    }
}

- (void)constructTableCellsForAlfrescoServer
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
    
    SwitchCell *syncPreferenceCell = (SwitchCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SwitchCell class]) owner:self options:nil] lastObject];
    syncPreferenceCell.selectionStyle = UITableViewCellSelectionStyleNone;
    syncPreferenceCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.syncPreference", @"Sync Favorite Content");
    self.syncPreferenceSwitch = syncPreferenceCell.valueSwitch;
    [self.syncPreferenceSwitch addTarget:self action:@selector(syncPreferenceChanged:) forControlEvents:UIControlEventValueChanged];
    [self.syncPreferenceSwitch setOn:self.formBackupAccount.isSyncOn animated:YES];
    
    if (self.account.accountType == UserAccountTypeOnPremise)
    {
        /**
         * Note: Additional account-specific settings should be in their own group with an empty header string.
         * This will allow a description footer to be added under each setting if required.
         */
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
        BOOL isHTTPSOn = self.formBackupAccount.protocol ? [self.formBackupAccount.protocol isEqualToString:kProtocolHTTPS] : YES;
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
        self.portTextField.text = kAlfrescoDefaultHTTPSPortString;
        
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
        
        self.tableViewData = [NSMutableArray arrayWithArray:@[ @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell],
                                                               @[portCell, serviceDocumentCell, certificateCell]]];
        self.tableGroupHeaders = @[@"accountdetails.header.authentication", @"accountdetails.header.advanced"];
        self.tableGroupFooters = @[@"", @""];
    }
    else
    {
        /**
         * Note: Additional account-specific settings should be in their own group with an empty header string.
         * This will allow a description footer to be added under each setting if required.
         */
        self.tableViewData = [NSMutableArray arrayWithArray:@[ @[descriptionCell], @[syncPreferenceCell]]];
        self.tableGroupHeaders = @[@"accountdetails.header.authentication", @"accountdetails.header.setting"];
        self.tableGroupFooters = @[@"", @"accountdetails.fields.syncPreference.footer"];
    }
}

#pragma mark - UITextFieldDelegate Functions

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
    
    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
}

- (void)syncPreferenceChanged:(id)sender
{
    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
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
    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
    
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
    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
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

#pragma mark - Retry method for login with diagnostic

- (void)retryLoginForConnectionDiagnostic
{
    void (^updateAccountInfo)(UserAccount *) = ^(UserAccount *temporaryAccount)
    {
        self.account.username = temporaryAccount.username;
        self.account.password = temporaryAccount.password;
        self.account.accountDescription = temporaryAccount.accountDescription;
        self.account.serverAddress = temporaryAccount.serverAddress;
        self.account.serverPort = temporaryAccount.serverPort;
        self.account.protocol = temporaryAccount.protocol;
        self.account.serviceDocument = temporaryAccount.serviceDocument;
        self.account.accountCertificate = temporaryAccount.accountCertificate;
        self.account.paidAccount = temporaryAccount.isPaidAccount;
    };
    
    [[LoginManager sharedManager] authenticateOnPremiseAccount:self.formBackupAccount password:self.formBackupAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        if (successful)
        {
            updateAccountInfo(self.formBackupAccount);
        }
    }];
}

#pragma mark - Notifictaions

-(void)profileDidChange:(NSNotification *)notifictaion
{
    AlfrescoProfileConfig *selectedProfile = notifictaion.object;
    self.profileLabel.text = selectedProfile.label;
    
    NSString *title = NSLocalizedString(@"main.menu.profile.selection.banner.title", @"Profile Changed Title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"main.menu.profile.selection.banner.message", @"Profile Changed"), selectedProfile.label];
    displayInformationMessageWithTitle(message, title);
}

@end
