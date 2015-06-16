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
 
#import "AccountInfoViewController.h"
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

static NSString * const kServiceDocument = @"/alfresco";

static NSInteger const kTagCertificateCell = 1;
static NSInteger const kTagReorderCell = 2;

@interface AccountInfoViewController ()
@property (nonatomic, assign) AccountActivityType activityType;
@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *serverAddressTextField;
@property (nonatomic, strong) UITextField *descriptionTextField;
@property (nonatomic, strong) UITextField *portTextField;
@property (nonatomic, strong) UITextField *serviceDocumentTextField;
@property (nonatomic, strong) UILabel *certificateLabel;
@property (nonatomic, strong) UISwitch *protocolSwitch;
@property (nonatomic, strong) UISwitch *syncPreferenceSwitch;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UserAccount *formBackupAccount;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, assign) BOOL canEditAccounts;
@property (nonatomic, assign) BOOL canReorderMainMenuItems;
@end

@implementation AccountInfoViewController

- (instancetype)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType
{
    return [self initWithAccount:account accountActivityType:activityType configuration:nil];
}

- (instancetype)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType configuration:(NSDictionary *)configuration
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
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
        self.activityType = activityType;
        self.formBackupAccount = [self.account copy];
        self.configuration = configuration;
        NSNumber *canEditAccounts = configuration[kAppConfigurationCanEditAccountsKey];
        self.canEditAccounts = (canEditAccounts) ? canEditAccounts.boolValue : YES;
        
        NSNumber *canReorderMenuItems = configuration[kAppConfigurationUserCanEditMainMenuKey];
        self.canReorderMainMenuItems = (canReorderMenuItems && account == [AccountManager sharedManager].selectedAccount) ? canReorderMenuItems.boolValue : YES;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = self.account.accountDescription;
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.allowsPullToRefresh = NO;
    [self constructTableCellsForAlfrescoServer];
    
    if (self.activityType == AccountActivityTypeNewAccount)
    {
        self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    }
    
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                    target:self
                                                                    action:@selector(saveButtonClicked:)];
    [self.navigationItem setRightBarButtonItem:self.saveButton];
    self.saveButton.enabled = NO;
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    self.saveButton.enabled = [self validateAccountFieldsValuesForServer];
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
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.activityType == AccountActivityTypeNewAccount)
    {
        // A small delay is necessary in order for the keyboard animation not to clash with the appear animation
        double delayInSeconds = 0.1;
        dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
        dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
            [self.usernameTextField becomeFirstResponder];
        });
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self updateFormBackupAccount];
}

- (void)saveButtonClicked:(id)sender
{
    if (self.account.accountType == UserAccountTypeOnPremise)
    {
        [self validateAccountOnServerWithCompletionBlock:^(BOOL successful, id<AlfrescoSession> session) {
            if (successful)
            {
                AccountManager *accountManager = [AccountManager sharedManager];
                
                if (accountManager.totalNumberOfAddedAccounts == 0)
                {
                    [accountManager selectAccount:self.account selectNetwork:nil alfrescoSession:session];
                }
                else if (accountManager.selectedAccount == self.account)
                {
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:session userInfo:nil];
                }
                
                if ([self.delegate respondsToSelector:@selector(accountInfoViewController:willDismissAfterAddingAccount:)])
                {
                    [self.delegate accountInfoViewController:self willDismissAfterAddingAccount:self.account];
                }

                [self dismissViewControllerAnimated:YES completion:^{
                    if (self.activityType == AccountActivityTypeNewAccount)
                    {
                        [accountManager addAccount:self.account];
                    }
                    else
                    {
                        [accountManager saveAccountsToKeychain];
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
                    }
                    
                    if ([self.delegate respondsToSelector:@selector(accountInfoViewController:didDismissAfterAddingAccount:)])
                    {
                        [self.delegate accountInfoViewController:self didDismissAfterAddingAccount:self.account];
                    }
                }];
            }
        }];
    }
    else
    {
        [self updateFormBackupAccount];
        
        self.account.accountDescription = self.formBackupAccount.accountDescription;
        self.account.isSyncOn = self.formBackupAccount.isSyncOn;
        // If Sync is now enabled, suppress the prompt in the Favorites view
        if (self.account.isSyncOn)
        {
            self.account.didAskToSync = YES;
        }

        [[AccountManager sharedManager] saveAccountsToKeychain];

        [self dismissViewControllerAnimated:YES completion:^{
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
        }];
    }
}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(accountInfoViewControllerWillDismiss:)])
    {
        [self.delegate accountInfoViewControllerWillDismiss:self];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(accountInfoViewControllerDidDismiss:)])
        {
            [self.delegate accountInfoViewControllerDidDismiss:self];
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
        MainMenuLocalConfigurationBuilder *mainBuilder = [[MainMenuLocalConfigurationBuilder alloc] initWithAccount:self.account session:self.session];
        MainMenuReorderViewController *reorderController = [[MainMenuReorderViewController alloc] initWithAccount:self.account mainMenuBuilder:mainBuilder];
        [self.navigationController pushViewController:reorderController animated:YES];
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
        if (self.activityType == AccountActivityTypeNewAccount)
        {
            isHTTPSOn = YES;
        }
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
        if (self.activityType == AccountActivityTypeNewAccount)
        {
            self.portTextField.text = kAlfrescoDefaultHTTPSPortString;
        }
        
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
        
        LabelCell *configurationCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        configurationCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        configurationCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        configurationCell.tag = kTagReorderCell;
        configurationCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.configuration", @"Configuration");
        configurationCell.valueLabel.text = @"";
        if (!self.canReorderMainMenuItems)
        {
            configurationCell.userInteractionEnabled = self.canReorderMainMenuItems;
            configurationCell.titleLabel.textColor = [UIColor lightGrayColor];
        }
        
         /**
          * Selectively disable some controls if required
          */
        for (UIControl *control in @[self.usernameTextField, self.serverAddressTextField, self.descriptionTextField,
                                     self.protocolSwitch, self.portTextField, self.serviceDocumentTextField])
        {
            control.enabled = self.canEditAccounts;
            control.alpha = self.canEditAccounts ? 1.0f : 0.2f;
        }
        
        /**
         * Note: Additional account-specific settings should be in their own group with an empty header string.
         * This will allow a description footer to be added under each setting if required.
         */
        if (self.activityType == AccountActivityTypeNewAccount)
        {
            self.tableViewData = [NSMutableArray arrayWithArray:@[ @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell],
                                                                   @[portCell, serviceDocumentCell, certificateCell]]];
            self.tableGroupHeaders = @[@"accountdetails.header.authentication", @"accountdetails.header.advanced"];
            self.tableGroupFooters = @[@"", @""];
        }
        else
        {
            self.tableViewData = [NSMutableArray arrayWithArray:@[ @[configurationCell],
                                                                   @[syncPreferenceCell],
                                                                   @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell],
                                                                   @[portCell, serviceDocumentCell, certificateCell]]];
            self.tableGroupHeaders = @[@"accountdetails.header.main.menu.config", @"accountdetails.header.setting", @"accountdetails.header.authentication", @"accountdetails.header.advanced"];
            self.tableGroupFooters = @[(self.canReorderMainMenuItems) ? @"" : @"accountdetails.footer.main.menu.config.disabled", @"accountdetails.fields.syncPreference.footer", @"",  @""];
        }
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

#pragma mark - private Methods

- (void)updateFormBackupAccount
{
    NSString *accountDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *defaultDescription = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    
    self.formBackupAccount.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.accountDescription = (!accountDescription || [accountDescription isEqualToString:@""]) ? defaultDescription : accountDescription;
    self.formBackupAccount.serverAddress = [self.serverAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.serverPort = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    self.formBackupAccount.serviceDocument = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    self.formBackupAccount.isSyncOn = self.syncPreferenceSwitch.isOn;
}

/**
 validateAccountFieldsValues
 checks the validity of hostname, port and username in terms of characters entered.
 */
- (BOOL)validateAccountFieldsValuesForServer
{
    BOOL didChangeAndIsValid = YES;
    BOOL hasAccountPropertiesChanged = (self.activityType == AccountActivityTypeLoginFailed);
    
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
        
        if (self.activityType == AccountActivityTypeEditAccount && didChangeAndIsValid)
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
            
            if (!(self.formBackupAccount.isSyncOn == self.syncPreferenceSwitch.isOn))
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
        self.account.isSyncOn = temporaryAccount.isSyncOn;
        // If Sync is now enabled, suppress the prompt in the Favorites view
        if (self.account.isSyncOn)
        {
            self.account.didAskToSync = YES;
        }
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
            UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account")
                                                                   message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Login Failed Message")
                                                                  delegate:self
                                                         cancelButtonTitle:NSLocalizedString(@"Done", @"Done")
                                                         otherButtonTitles:NSLocalizedString(@"connectiondiagnostic.button.retrywithdiagnostic", @"Retry with diagnostic"), nil];
            [failureAlert showWithCompletionBlock:^(NSUInteger buttonIndex, BOOL isCancelButton) {
                if (!isCancelButton)
                {
                    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:@"ConnectionDiagnosticStoryboard" bundle:[NSBundle mainBundle]];
                    ConnectionDiagnosticViewController *viewController = (ConnectionDiagnosticViewController *)[storyboard instantiateViewControllerWithIdentifier:@"ConnectionDiagnosticSBID"];
                    [viewController setupWithParent:self andSelector:@selector(retryLoginForConnectionDiagnostic)];
                    [self.navigationController pushViewController:viewController animated:YES];
                }
            }];
        }
    }];
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
    while (!foundTableViewCell)
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
        self.account.isSyncOn = temporaryAccount.isSyncOn;
        // If Sync is now enabled, suppress the prompt in the Favorites view
        if (self.account.isSyncOn)
        {
            self.account.didAskToSync = YES;
        }
        self.account.paidAccount = temporaryAccount.isPaidAccount;
    };
    
    [[LoginManager sharedManager] authenticateOnPremiseAccount:self.formBackupAccount password:self.formBackupAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        if (successful)
        {
            updateAccountInfo(self.formBackupAccount);
        }
    }];
}

@end
