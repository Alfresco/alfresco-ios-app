//
//  AccountInfoViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 25/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountInfoViewController.h"
#import "AccountManager.h"
#import "LoginManager.h"
#import "Constants.h"
#import "TextFieldCell.h"
#import "SwitchCell.h"
#import "LabelCell.h"
#import "CenterLabelCell.h"
#import "NavigationViewController.h"

static NSString * const kDefaultHTTPPort = @"80";
static NSString * const kDefaultHTTPSPort = @"443";
static NSString * const kServiceDocument = @"/alfresco";

typedef NS_ENUM(NSInteger, AccountInfoTableSection)
{
    AccountInfoTableSectionAuthentication = 0,
    AccountInfoTableSectionAdvanced,
    AccountInfoTableSectionBrowse,
    AccountInfoTableSectionDelete
};

@interface AccountInfoViewController ()
@property (nonatomic, assign) AccountActivityType activityType;
@property (nonatomic, strong) NSArray *tableGroups;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *serverAddressTextField;
@property (nonatomic, strong) UITextField *descriptionTextField;
@property (nonatomic, strong) UITextField *portTextField;
@property (nonatomic, strong) UITextField *serviceDocumentTextField;
@property (nonatomic, strong) UISwitch *protocolSwitch;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@end

@implementation AccountInfoViewController

- (id)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType
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
            self.account = [[UserAccount alloc] initWithAccountType:AccountTypeOnPremise];
        }
        self.activityType = activityType;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = self.account.accountDescription;
    [self disablePullToRefresh];
    
    
    
    if (self.activityType == AccountActivityTypeViewAccount)
    {
        UIBarButtonItem *editButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemEdit
                                                                                    target:self
                                                                                    action:@selector(editButtonClicked:)];
        [self.navigationItem setRightBarButtonItem:editButton];
    }
    else
    {
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
    
    [self constructTableCellsForAlfrescoServer];
    self.saveButton.enabled = [self validateAccountFieldsValuesForStandardServer];
}

-(void)saveButtonClicked:(id)sender
{
    [self validateAccountOnServerWithCompletionBlock:^(BOOL successful) {
        
        AccountManager *accountManager = [AccountManager sharedManager];
        
        if (accountManager.totalNumberOfAddedAccounts == 0)
        {
            accountManager.selectedAccount = self.account;
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            if (self.activityType == AccountActivityTypeNewAccount)
            {
                [accountManager addAccount:self.account];
            }
            else
            {
                [accountManager saveAccountsToKeychain];
            }
        }];
    }];
}

-(void)editButtonClicked:(id)sender
{
    AccountInfoViewController *accountInfoController = [[AccountInfoViewController alloc] initWithAccount:self.account accountActivityType:AccountActivityTypeEditAccount];
    NavigationViewController *editAccountNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountInfoController];
    editAccountNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:editAccountNavigationController animated:YES completion:nil];
}

- (void)cancel:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableGroups[section] count];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    if (section == AccountInfoTableSectionAuthentication)
    {
        return NSLocalizedString(@"accountdetails.header.authentication", @"Authenticate");
    }
    else if (section == AccountInfoTableSectionAdvanced)
    {
        return NSLocalizedString(@"accountdetails.header.advanced", @"Advanced");
    }
    else
    {
        return nil;
    }
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableGroups[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == AccountInfoTableSectionBrowse)
    {
        
    }
    else if (indexPath.section == AccountInfoTableSectionDelete)
    {
        AccountManager *accountManager = [AccountManager sharedManager];
        [accountManager removeAccount:self.account];
        
    }
    else
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        selectedCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)constructTableCellsForAlfrescoServer
{
    NSArray *group1 = nil;
    NSArray *group2 = nil;
    if (self.activityType == AccountActivityTypeNewAccount || self.activityType == AccountActivityTypeEditAccount)
    {
        TextFieldCell *usernameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
        usernameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
        usernameCell.valueTextField.returnKeyType = UIReturnKeyNext;
        usernameCell.valueTextField.delegate = self;
        self.usernameTextField = usernameCell.valueTextField;
        
        TextFieldCell *passwordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        passwordCell.titleLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
        passwordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.optional", @"Optional");
        passwordCell.valueTextField.returnKeyType = UIReturnKeyNext;
        passwordCell.valueTextField.secureTextEntry = YES;
        passwordCell.valueTextField.delegate = self;
        self.passwordTextField = passwordCell.valueTextField;
        
        TextFieldCell *descriptionCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        descriptionCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.description", @"Description Cell Text");
        descriptionCell.valueTextField.delegate = self;
        descriptionCell.valueTextField.placeholder = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
        descriptionCell.valueTextField.returnKeyType = UIReturnKeyNext;
        self.descriptionTextField = descriptionCell.valueTextField;
        
        TextFieldCell *serverAddressCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        serverAddressCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.hostname", @"Server Address");
        serverAddressCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
        serverAddressCell.valueTextField.returnKeyType = UIReturnKeyNext;
        serverAddressCell.valueTextField.delegate = self;
        self.serverAddressTextField = serverAddressCell.valueTextField;
        
        SwitchCell *protocolCell = (SwitchCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([SwitchCell class]) owner:self options:nil] lastObject];
        protocolCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
        self.protocolSwitch = protocolCell.valueSwitch;
        [self.protocolSwitch addTarget:self action:@selector(protocolChanged:) forControlEvents:UIControlEventValueChanged];
        
        TextFieldCell *portCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        portCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.port", @"Port Cell Text");
        portCell.valueTextField.text = kDefaultHTTPPort;
        portCell.valueTextField.returnKeyType = UIReturnKeyNext;
        portCell.valueTextField.keyboardType = UIKeyboardTypeNumberPad;
        portCell.valueTextField.delegate = self;
        self.portTextField = portCell.valueTextField;
        
        TextFieldCell *serviceDocumentCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        serviceDocumentCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
        serviceDocumentCell.valueTextField.text = kServiceDocument;
        serviceDocumentCell.valueTextField.returnKeyType = UIReturnKeyDone;
        serviceDocumentCell.valueTextField.delegate = self;
        self.serviceDocumentTextField = serviceDocumentCell.valueTextField;
        
        if (self.activityType == AccountActivityTypeEditAccount)
        {
            self.usernameTextField.text = self.account.username;
            self.passwordTextField.text = self.account.password;
            self.serverAddressTextField.text = self.account.serverAddress;
            self.descriptionTextField.text = self.account.accountDescription;
            BOOL isHTTPSOn = [self.account.protocol isEqualToString:kProtocolHTTP] ? NO : YES;
            [self.protocolSwitch setOn:isHTTPSOn animated:YES];
            self.portTextField.text = self.account.serverPort;
            self.serviceDocumentTextField.text = self.account.serviceDocument;
        }
        
        group1 = (self.account.accountType == AccountTypeOnPremise) ? @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell] : @[descriptionCell];
        group2 = (self.account.accountType == AccountTypeOnPremise) ? @[portCell, serviceDocumentCell] : nil;
    }
    else if (self.activityType == AccountActivityTypeViewAccount)
    {
        LabelCell *usernameCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
        usernameCell.valueLabel.text = self.account.username;
        
        LabelCell *passwordCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        passwordCell.titleLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
        passwordCell.valueLabel.text = @"**************";
        
        LabelCell *descriptionCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        descriptionCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.description", @"Description Cell Text");
        descriptionCell.valueLabel.text = self.account.accountDescription;
        
        LabelCell *serverAddressCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        serverAddressCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.hostname", @"Server Address");
        serverAddressCell.valueLabel.text = self.account.serverAddress;
        
        LabelCell *protocolCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        protocolCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
        protocolCell.valueLabel.text = self.account.protocol;
        
        LabelCell *portCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        portCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.port", @"Port Cell Text");
        portCell.valueLabel.text = self.account.serverPort;
        
        LabelCell *serviceDocumentCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        serviceDocumentCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
        serviceDocumentCell.valueLabel.text = self.account.serviceDocument;
        
        group1 = (self.account.accountType == AccountTypeOnPremise) ? @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell] : @[descriptionCell];
        group2 = (self.account.accountType == AccountTypeOnPremise) ? @[portCell, serviceDocumentCell] : nil;
    }
    self.tableGroups = (self.account.accountType == AccountTypeOnPremise) ? @[group1, group2] : @[group1];
}

#pragma mark - private Methods

- (UserAccount *)accountWithUserEnteredInfo
{
    UserAccount *temporaryAccount = [[UserAccount alloc] initWithAccountType:AccountTypeOnPremise];
    
    temporaryAccount.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *accountDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *defaultDescription = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    temporaryAccount.accountDescription = (!accountDescription || [accountDescription isEqualToString:@""]) ? defaultDescription : accountDescription;
    
    temporaryAccount.serverAddress = [self.serverAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.serverPort = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    temporaryAccount.serviceDocument = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    return temporaryAccount;
}

/**
 validateAccountFieldsValues
 checks the validity of hostname, port and username in terms of characters entered.
 */
- (BOOL)validateAccountFieldsValuesForStandardServer
{
    //User input validations
    NSString *hostname = self.serverAddressTextField.text;
    NSString *port = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *serviceDoc = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    NSRange hostnameRange = [hostname rangeOfString:@"^[a-zA-Z0-9_\\-\\.]+$" options:NSRegularExpressionSearch];
    
    BOOL hostnameError = ( !hostname || (hostnameRange.location == NSNotFound) );
    BOOL portIsInvalid = ([port rangeOfString:@"^[0-9]*$" options:NSRegularExpressionSearch].location == NSNotFound);
    BOOL usernameError = [username isEqualToString:@""];
    BOOL serviceDocError = [serviceDoc isEqualToString:@""];
    
    return !hostnameError && !portIsInvalid && !usernameError && !serviceDocError;
}

- (void)validateAccountOnServerWithCompletionBlock:(void (^)(BOOL successful))completionBlock
{
    UserAccount *temporaryAccount = [self accountWithUserEnteredInfo];
    void (^updateAccountInfo)(UserAccount *) = ^(UserAccount *temporaryAccount)
    {
        self.account.username = temporaryAccount.username;
        self.account.password = temporaryAccount.password;
        self.account.accountDescription = temporaryAccount.accountDescription;
        self.account.serverAddress = temporaryAccount.serverAddress;
        self.account.serverPort = temporaryAccount.serverPort;
        self.account.protocol = temporaryAccount.protocol;
        self.account.serviceDocument = temporaryAccount.serviceDocument;
    };
    
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if ((password == nil || [password isEqualToString:@""]))
    {
        updateAccountInfo(temporaryAccount);
        completionBlock(YES);
    }
    else
    {
        BOOL useTemporarySession = !([[AccountManager sharedManager] totalNumberOfAddedAccounts] == 0);
        
        [self showHUD];
        [[LoginManager sharedManager] authenticateOnPremiseAccount:temporaryAccount password:temporaryAccount.password temporarySession:useTemporarySession completionBlock:^(BOOL successful) {
            
            [self hideHUD];
            if (successful)
            {
                updateAccountInfo(temporaryAccount);
                completionBlock(YES);
            }
            else
            {
                UIAlertView *failureAlert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account")
                                                                       message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Login Failed Message")
                                                                      delegate:nil cancelButtonTitle:NSLocalizedString(@"Done", @"Done")
                                                             otherButtonTitles:nil, nil];
                [failureAlert show];
            }
        }];
    }
}

#pragma mark - UITextFieldDelegate Functions

- (void)protocolChanged:(id)sender
{
    NSString *portNumber = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    if ([portNumber isEqualToString:@""] || [portNumber isEqualToString:kDefaultHTTPPort] || [portNumber isEqualToString:kDefaultHTTPSPort])
    {
        if (self.protocolSwitch.isOn && self.portTextField.text )
        {
            self.portTextField.text = kDefaultHTTPSPort;
        }
        else
        {
            self.portTextField.text = kDefaultHTTPPort;
        }
    }
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
    self.saveButton.enabled = [self validateAccountFieldsValuesForStandardServer];
    
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

- (void)textFieldDidChange:(NSNotification *)note
{
    self.saveButton.enabled = [self validateAccountFieldsValuesForStandardServer];
}

#pragma mark - UIKeyboard Notifications

- (void)keyboardWasShown:(NSNotification*)aNotification
{
    NSDictionary* info = [aNotification userInfo];
    CGSize kbSize = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue].size;
    
    BOOL isPortrait = UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]);
    
    CGFloat height = isPortrait ? kbSize.height : kbSize.width;
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(0.0, 0.0, height, 0.0);
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
    
    CGRect tableViewFrame = self.tableView.frame;
    tableViewFrame.size.height -= kbSize.height;
    self.tableViewVisibleRect = tableViewFrame;
    [self showActiveTextField];
}

- (void)keyboardWillBeHidden:(NSNotification*)aNotification
{
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.tableView.contentInset = contentInsets;
    self.tableView.scrollIndicatorInsets = contentInsets;
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

@end
