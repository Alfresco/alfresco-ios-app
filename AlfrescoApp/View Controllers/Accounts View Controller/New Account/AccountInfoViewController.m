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
@end

@implementation AccountInfoViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    if (!self.account)
    {
        self.account = [[Account alloc] init];
    }
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
}

-(void)saveButtonClicked:(id)sender
{
    [self validateAccountOnStandardServerWithCompletionBlock:^(BOOL successful) {
        
        AccountManager *accountManager = [AccountManager sharedManager];
        
        if (accountManager.totalNumberOfAddedAccounts == 0)
        {
            accountManager.selectedAccount = self.account;
        }
        
        [self dismissViewControllerAnimated:YES completion:^{
            [accountManager addAccount:self.account];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountAddedNotification object:nil];
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
    
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
}

- (void)constructTableCellsForAlfrescoServer
{
    // cells
    CGFloat xPosition = 100.0f;
    CGFloat topBottomPadding = 10.0f;
    
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
    
    UITableViewCell *descriptionCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DescriptionCell"];
    descriptionCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.description", @"Description Cell Text");
    UITextField *descriptionTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                      topBottomPadding,
                                                                                      descriptionCell.frame.size.width - xPosition,
                                                                                      descriptionCell.frame.size.height - (topBottomPadding * 2))];
    descriptionTextField.placeholder = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
    descriptionTextField.textAlignment = NSTextAlignmentRight;
    descriptionTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    descriptionTextField.returnKeyType = UIReturnKeyNext;
    descriptionTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    descriptionTextField.delegate = self;
    self.descriptionTextField = descriptionTextField;
    [descriptionCell.contentView addSubview:descriptionTextField];
    
    UITableViewCell *protocolCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"ProtocolCell"];
    protocolCell.textLabel.text = NSLocalizedString(@"accountdetails.fields.protocol", @"HTTPS protocol");
    UISwitch *protocolSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(self.view.frame.size.width,
                                                                          topBottomPadding,
                                                                          protocolCell.frame.size.width - xPosition,
                                                                          protocolCell.frame.size.height - (topBottomPadding * 2))];
    [protocolCell.contentView addSubview:protocolSwitch];
    self.protocolSwitch = protocolSwitch;
    [self.protocolSwitch addTarget:self action:@selector(protocolChanged:) forControlEvents:UIControlEventValueChanged];
    
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
    UITextField *serviceDocumentTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                          topBottomPadding,
                                                                                          serviceDocumentCell.frame.size.width - xPosition,
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

- (void)validateAccountOnStandardServerWithCompletionBlock:(void (^)(BOOL successful))completionBlock
{
    Account *temporaryAccount = [[Account alloc] init];
    temporaryAccount.username = [self.usernameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.serverAddress = [self.serverAddressTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.serverPort = [self.portTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *accountDescription = [self.descriptionTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    temporaryAccount.accountDescription = ([accountDescription isEqualToString:@""]) ? NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server") : accountDescription;
    temporaryAccount.protocol = self.protocolSwitch.isOn ? kProtocolHTTPS : kProtocolHTTP;
    temporaryAccount.serviceDocument = [self.serviceDocumentTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    void (^updateAccountInfo)(Account *) = ^(Account *temporaryAccount)
    {
        self.account.username = temporaryAccount.username;
        self.account.password = temporaryAccount.password;
        self.account.serverAddress = temporaryAccount.serverAddress;
        self.account.serverPort = temporaryAccount.serverPort;
        self.account.accountDescription = temporaryAccount.accountDescription;
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
        [[LoginManager sharedManager] loginToAccount:temporaryAccount username:temporaryAccount.username password:temporaryAccount.password temporarySession:useTemporarySession completionBlock:^(BOOL successful) {
            
            if (successful)
            {
                updateAccountInfo(temporaryAccount);
                completionBlock(YES);
            }
        }];
    }
}

- (BOOL)validateAccountFieldsValuesForCloud
{
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    if (password == nil || [password isEqualToString:@""])
    {
        return YES;
    }
    
    int statusCode = 0; // [self requestToCloud]; needs updating
    if (200 <= statusCode && 299 >= statusCode)
    {
        return YES;
    }
    return NO;
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

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    [self.saveButton setEnabled:[self validateAccountFieldsValuesForStandardServer]];
    
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
    [self.saveButton setEnabled:[self validateAccountFieldsValuesForStandardServer]];
}

@end
