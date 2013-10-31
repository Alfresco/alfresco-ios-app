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

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self)
    {
        
    }
    return self;
}

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
            self.account = [[Account alloc] initWithAccoutType:AccountTypeOnPremise];
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
    
    static CGFloat xPosition = 100.0f;
    static CGFloat topBottomPadding = 10.0f;
    static CGFloat labelFieldGap = 14.0f;
    static CGFloat rightPadding = 8.0f;
    
    UITableViewCell *usernameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"];
    usernameCell.textLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    UITextField *usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                   topBottomPadding,
                                                                                   usernameCell.frame.size.width - xPosition,
                                                                                   usernameCell.frame.size.height - (topBottomPadding * 2))];
    usernameTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Optional");
    usernameTextField.textAlignment = NSTextAlignmentRight;
    usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameTextField.returnKeyType = UIReturnKeyNext;
    usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    usernameTextField.delegate = self;
    self.usernameTextField = usernameTextField;
    [usernameCell.contentView addSubview:usernameTextField];
    
    UITableViewCell *passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"];
    passwordCell.textLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
    UITextField *passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                   topBottomPadding,
                                                                                   passwordCell.frame.size.width - xPosition,
                                                                                   passwordCell.frame.size.height - (topBottomPadding * 2))];
    passwordTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.optional", @"Optional");
    passwordTextField.textAlignment = NSTextAlignmentRight;
    passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    passwordTextField.returnKeyType = UIReturnKeyNext;
    passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    passwordTextField.secureTextEntry = YES;
    passwordTextField.delegate = self;
    self.passwordTextField = passwordTextField;
    [passwordCell.contentView addSubview:passwordTextField];
    
    UITableViewCell *descriptionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DescriptionCell"];
    descriptionCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.description", @"Description Cell Text");
    UITextField *descriptionTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                      topBottomPadding,
                                                                                      descriptionCell.frame.size.width - xPosition,
                                                                                      descriptionCell.frame.size.height - (topBottomPadding * 2))];
    descriptionTextField.textAlignment = NSTextAlignmentRight;
    descriptionTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    descriptionTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    descriptionTextField.delegate = self;
    descriptionTextField.placeholder = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    descriptionTextField.returnKeyType = UIReturnKeyNext;
    self.descriptionTextField = descriptionTextField;
    [descriptionCell.contentView addSubview:descriptionTextField];
    
    UITableViewCell *serverAddressCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ServerAddressCell"];
    serverAddressCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.hostname", @"Server Address");
    UITextField *serverAddressTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                        topBottomPadding,
                                                                                        serverAddressCell.frame.size.width - xPosition,
                                                                                        serverAddressCell.frame.size.height - (topBottomPadding * 2))];
    serverAddressTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"Optional");
    serverAddressTextField.textAlignment = NSTextAlignmentRight;
    serverAddressTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    serverAddressTextField.returnKeyType = UIReturnKeyNext;
    serverAddressTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    serverAddressTextField.delegate = self;
    self.serverAddressTextField = serverAddressTextField;
    [serverAddressCell.contentView addSubview:serverAddressTextField];
    
    UITableViewCell *protocolCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ProtocolCell"];
    protocolCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
    UISwitch *protocolSwitch = [[UISwitch alloc] initWithFrame:CGRectZero];
    CGRect switchFrame = protocolSwitch.frame;
    switchFrame.origin.x = protocolCell.frame.size.width - switchFrame.size.width - rightPadding;
    switchFrame.origin.y = topBottomPadding;
    protocolSwitch.frame = switchFrame;
    [protocolCell.contentView addSubview:protocolSwitch];
    self.protocolSwitch = protocolSwitch;
    [self.protocolSwitch addTarget:self action:@selector(protocolChanged:) forControlEvents:UIControlEventValueChanged];
    protocolSwitch.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    
    UITableViewCell *portCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PortCell"];
    portCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.port", @"Port Cell Text");
    UITextField *portTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                               topBottomPadding,
                                                                               portCell.frame.size.width - xPosition,
                                                                               portCell.frame.size.height - (topBottomPadding * 2))];
    portTextField.text = kDefaultHTTPPort;
    portTextField.textAlignment = NSTextAlignmentRight;
    portTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    portTextField.returnKeyType = UIReturnKeyNext;
    portTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    portTextField.delegate = self;
    self.portTextField = portTextField;
    [portCell.contentView addSubview:portTextField];
    
    UITableViewCell *serviceDocumentCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ServerAddressCell"];
    serviceDocumentCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.servicedocument", @"Service Document");
    
    NSInteger x = serviceDocumentCell.frame.size.width / 2 + labelFieldGap;
    UITextField *serviceDocumentTextField = [[UITextField alloc] initWithFrame:CGRectMake(x - rightPadding,
                                                                                          topBottomPadding,
                                                                                          serviceDocumentCell.frame.size.width - x,
                                                                                          serviceDocumentCell.frame.size.height - (topBottomPadding * 2))];
    serviceDocumentTextField.text = kServiceDocument;
    serviceDocumentTextField.textAlignment = NSTextAlignmentRight;
    serviceDocumentTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    serviceDocumentTextField.returnKeyType = UIReturnKeyDone;
    serviceDocumentTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    serviceDocumentTextField.delegate = self;
    self.serviceDocumentTextField = serviceDocumentTextField;
    [serviceDocumentCell.contentView addSubview:serviceDocumentTextField];
    
    NSArray *group1 = @[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell];
    NSArray *group2 = @[portCell, serviceDocumentCell];
    self.tableGroups = @[group1, group2];
}

#pragma mark - private Methods

- (Account *)accountWithUserEnteredInfo
{
    Account *temporaryAccount = [[Account alloc] initWithAccoutType:AccountTypeOnPremise];
    
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
        [[LoginManager sharedManager] authenticateOnPremiseAccount:temporaryAccount password:temporaryAccount.password temporarySession:useTemporarySession completionBlock:^(BOOL successful) {
            
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
