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

static NSString * const kDefaultHTTPPort = @"80";
static NSString * const kDefaultHTTPSPort = @"443";
static NSString * const kServiceDocument = @"alfresco/service/cmis";

@interface AccountInfoViewController ()
@property (nonatomic, strong) NSArray *tableGroups;
@property (nonatomic, strong) UITextField *usernameTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *serverAddressTextField;
@property (nonatomic, strong) UITextField *descriptionTextField;
@property (nonatomic, strong) UITextField *portTextField;
@property (nonatomic, strong) UITextField *serviceDocumentTextField;
@property (nonatomic, strong) UISwitch *protocolSwitch;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) Account *account;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@end

@implementation AccountInfoViewController

- (id)initWithAccount:(Account *)account
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
            self.account = [[Account alloc] initWithAccountType:AccountTypeOnPremise];
        }
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    [self disablePullToRefresh];
    
    [self constructTableCellsForAlfrescoServer];
    
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave
                                                                    target:self
                                                                    action:@selector(saveButtonClicked:)];
    [self.navigationItem setRightBarButtonItem:self.saveButton];
    self.saveButton.enabled = NO;
    
    UIBarButtonItem *addAccount = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                                target:self
                                                                                action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = addAccount;
    
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

-(void)saveButtonClicked:(id)sender
{
    [self validateAccountOnServerWithCompletionBlock:^(BOOL successful) {
        
        AccountManager *accountManager = [AccountManager sharedManager];
        
        if (accountManager.totalNumberOfAddedAccounts == 0)
        {
            accountManager.selectedAccount = self.account;
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            [accountManager addAccount:self.account];
        }];
    }];
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
    if (section == 0)
    {
        return NSLocalizedString(@"accountdetails.header.authentication", @"Authenticate");
    }
    else
    {
        return NSLocalizedString(@"accountdetails.header.advanced", @"Advanced");
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
    UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
    selectedCell.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
}

- (void)constructTableCellsForAlfrescoServer
{
    // cells
    TextFieldCell *usernameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    usernameCell.titleLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    usernameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Optional");
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
    serverAddressCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Optional");
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
    portCell.valueTextField.delegate = self;
    self.portTextField = portCell.valueTextField;
    
    TextFieldCell *serviceDocumentCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
    serviceDocumentCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
    serviceDocumentCell.valueTextField.text = kServiceDocument;
    serviceDocumentCell.valueTextField.returnKeyType = UIReturnKeyDone;
    serviceDocumentCell.valueTextField.delegate = self;
    self.serviceDocumentTextField = serviceDocumentCell.valueTextField;
    
    NSArray *group1 = @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell];
    NSArray *group2 = @[portCell, serviceDocumentCell];
    self.tableGroups = @[group1, group2];
}

#pragma mark - private Methods

- (Account *)accountWithUserEnteredInfo
{
    Account *temporaryAccount = [[Account alloc] initWithAccountType:AccountTypeOnPremise];
    
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
    Account *temporaryAccount = [self accountWithUserEnteredInfo];
    void (^updateAccountInfo)(Account *) = ^(Account *temporaryAccount)
    {
        self.account.username = temporaryAccount.username;
        self.account.password = temporaryAccount.password;
        self.account.accountDescription = temporaryAccount.accountDescription;
        self.account.repositoryId = temporaryAccount.repositoryId;
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
