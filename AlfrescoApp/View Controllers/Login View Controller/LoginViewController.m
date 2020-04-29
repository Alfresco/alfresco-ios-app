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
 
#import "LoginViewController.h"
#import "UserAccount.h"

@interface LoginViewController ()

@property (nonatomic, strong) NSArray *cells;
@property (nonatomic, weak) UITableView *tableView;
@property (nonatomic, weak) UITextField *usernameTextField;
@property (nonatomic, weak) UITextField *passwordTextField;
@property (nonatomic, weak) UILabel *serverAddressTextLabel;
@property (nonatomic, strong) NSString *serverAddress;
@property (nonatomic, strong) NSString *serverDisplayName;
@property (nonatomic, strong) NSString *username;
@property (nonatomic, strong) NSString *password;
@property (nonatomic, weak) id<LoginViewControllerDelegate>delegate;
@property (nonatomic, weak) UIBarButtonItem *loginButton;
@property (nonatomic, strong) UIView *sectionHeaderContainerView;
@property (nonatomic, strong) UserAccount *loginToAccount;

@end

@implementation LoginViewController

- (id)initWithAccount:(UserAccount *)account delegate:(id<LoginViewControllerDelegate>)delegate
{
    self = [self initWithServer:[Utility serverURLStringFromAccount:account] serverDisplayName:account.accountDescription username:account.username delegate:delegate];
    if (self)
    {
        self.password = account.password;
        self.loginToAccount = account;
    }
    return self;
}

- (id)initWithServer:(NSString *)serverURLString serverDisplayName:(NSString *)serverDisplayName username:(NSString *)username delegate:(id<LoginViewControllerDelegate>)delegate
{
    self = [super init];
    if (self)
    {
        self.serverAddress = serverURLString;
        self.username = username;
        self.delegate = delegate;
        [self validateAndSetDisplayNameWithName:serverDisplayName];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(alfrescoApplicationPolicyUpdated:)
                                                     name:kAlfrescoApplicationPolicyUpdatedNotification
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(textFieldDidChange:)
                                                     name:UITextFieldTextDidChangeNotification
                                                   object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    // table view
    UITableView *tableView = [[UITableView alloc] initWithFrame:view.frame style:UITableViewStyleGrouped];
    tableView.delegate = self;
    tableView.dataSource = self;
    tableView.autoresizesSubviews = YES;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth  | UIViewAutoresizingFlexibleBottomMargin | UIViewAutoresizingFlexibleTopMargin
    | UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
    [view addSubview:tableView];
    self.tableView = tableView;
    
    // section header
    CGFloat sectionHeaderHeight = 40.0f;
    CGFloat serverLabelPadding = 10.0f;
    
    UIView *serverSectionHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, sectionHeaderHeight)];
    serverSectionHeaderView.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    serverSectionHeaderView.autoresizesSubviews = YES;
    serverSectionHeaderView.backgroundColor = [UIColor clearColor];
    
    UILabel *serverLabel = [[UILabel alloc] initWithFrame:CGRectMake(serverLabelPadding,
                                                                     serverLabelPadding,
                                                                     tableView.frame.size.width - (serverLabelPadding * 2),
                                                                     sectionHeaderHeight - (serverLabelPadding * 2))];
    serverLabel.backgroundColor = [UIColor clearColor];
    serverLabel.text = [self serverDisplayString];
    serverLabel.textAlignment = NSTextAlignmentCenter;
    serverLabel.textColor = [UIColor darkGrayColor];
    serverLabel.font = [UIFont systemFontOfSize:14.0f];
    serverLabel.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    self.serverAddressTextLabel = serverLabel;
    [serverSectionHeaderView addSubview:serverLabel];
    self.sectionHeaderContainerView = serverSectionHeaderView;
    
    // cells
    CGFloat xPosition = 100.0f;
    CGFloat topBottomPadding = 10.0f;
    
    UITableViewCell *usernameCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"UsernameCell"];
    usernameCell.textLabel.text = NSLocalizedString(@"login.username.cell.label", @"Username Cell Text");
    UITextField *usernameTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                  topBottomPadding,
                                                                                  usernameCell.frame.size.width - xPosition,
                                                                                  usernameCell.frame.size.height - (topBottomPadding * 2))];
    usernameTextField.placeholder = NSLocalizedString(@"login.username.textfield.placeholder", @"Username Placeholder Text");
    usernameTextField.text = self.username;
    usernameTextField.textAlignment = NSTextAlignmentRight;
    usernameTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    usernameTextField.autocorrectionType = UITextAutocorrectionTypeNo;
    usernameTextField.returnKeyType = UIReturnKeyNext;
    usernameTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    usernameTextField.delegate = self;
    usernameTextField.enabled = (self.username.length == 0);
    self.usernameTextField = usernameTextField;
    [usernameCell.contentView addSubview:usernameTextField];
    
    UITableViewCell *passwordCell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"PasswordCell"];
    passwordCell.textLabel.text = NSLocalizedString(@"login.password.cell.label", @"Password Cell Text");
    UITextField *passwordTextField = [[UITextField alloc] initWithFrame:CGRectMake(xPosition - topBottomPadding,
                                                                                   topBottomPadding,
                                                                                   passwordCell.frame.size.width - xPosition,
                                                                                   passwordCell.frame.size.height - (topBottomPadding * 2))];
    passwordTextField.placeholder = NSLocalizedString(@"login.password.textfield.placeholder", @"Password Placeholder Text");
    passwordTextField.text = self.password;
    passwordTextField.textAlignment = NSTextAlignmentRight;
    passwordTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    passwordTextField.returnKeyType = UIReturnKeyDone;
    passwordTextField.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleLeftMargin;
    passwordTextField.secureTextEntry = YES;
    passwordTextField.delegate = self;
    self.passwordTextField = passwordTextField;
    [passwordCell.contentView addSubview:passwordTextField];
    
    self.cells = @[usernameCell, passwordCell];
    
    view.autoresizesSubviews = YES;
    view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"login.title", @"Login Title");
	
    UIBarButtonItem *loginBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Done", @"Bar Button Title")
                                                                       style:UIBarButtonItemStyleDone
                                                                      target:self
                                                                      action:@selector(login:)];
    
    UIBarButtonItem *cancelBarButton = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Cancel", @"Cancel Button Title")
                                                                       style:UIBarButtonItemStylePlain
                                                                      target:self
                                                                      action:@selector(cancel:)];
    loginBarButton.enabled = (self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0);
    [self.navigationItem setRightBarButtonItem:loginBarButton];
    [self.navigationItem setLeftBarButtonItem:cancelBarButton];
    self.loginButton = loginBarButton;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.usernameTextField.text.length > 0)
        {
            [self.passwordTextField becomeFirstResponder];
        }
        else
        {
            [self.usernameTextField becomeFirstResponder];
        }
    });
}

#pragma mark - Public Functions

- (void)updateUIForFailedLogin
{
    [self.passwordTextField becomeFirstResponder];
}

#pragma mark - Private Functions

- (void)login:(id)sender
{
    if (self.loginToAccount && [self.delegate respondsToSelector:@selector(loginViewController:didPressRequestLoginToAccount:username:password:)])
    {
        [self.delegate loginViewController:self didPressRequestLoginToAccount:self.loginToAccount username:self.usernameTextField.text password:self.passwordTextField.text];
    }
    else if ([self.delegate respondsToSelector:@selector(loginViewController:didPressRequestLoginToServer:username:password:)])
    {
        [self.delegate loginViewController:self didPressRequestLoginToServer:self.serverAddress username:self.usernameTextField.text password:self.passwordTextField.text];
    }
}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(loginViewController:didPressCancel:)])
    {
        [self.delegate loginViewController:self didPressCancel:sender];
    }
    else
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

- (void)alfrescoApplicationPolicyUpdated:(NSNotification *)notification
{
    // update the server address
    NSDictionary *policySettings = (NSDictionary *)[notification object];
    NSString *serverAddress = [[policySettings objectForKey:kApplicationPolicySettings] objectForKey:kApplicationPolicyServer];
    NSString *serverDisplayName = [[policySettings objectForKey:kApplicationPolicySettings] objectForKey:kApplicationPolicyServerDisplayName];
    self.serverAddress = serverAddress;
    [self validateAndSetDisplayNameWithName:serverDisplayName];
    self.serverAddressTextLabel.text = [self serverDisplayString];
}

- (void)validateAndSetDisplayNameWithName:(NSString *)proposedDisplayName
{
    self.serverDisplayName = (proposedDisplayName.length > 0) ? proposedDisplayName : self.serverAddress;
}

- (NSString *)serverDisplayString
{
    return [NSString stringWithFormat:@"%@: %@", NSLocalizedString(@"login.server.cell.label", @"Server Label"), self.serverDisplayName];
}

#pragma mark - UITableViewDelegate Functions

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return self.sectionHeaderContainerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return self.sectionHeaderContainerView.frame.size.height;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.cells.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [self.cells objectAtIndex:indexPath.row];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    return cell;
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == self.usernameTextField)
    {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField)
    {
        [self.passwordTextField resignFirstResponder];
        
        if (self.loginButton.enabled)
        {
            [self login:self.loginButton];
        }
    }
    return YES;
}

- (void)textFieldDidChange:(NSNotification *)notification
{
    if (self.usernameTextField.text.length > 0 && self.passwordTextField.text.length > 0)
    {
        self.loginButton.enabled = YES;
    }
    else
    {
        self.loginButton.enabled = NO;
    }    
}

@end
