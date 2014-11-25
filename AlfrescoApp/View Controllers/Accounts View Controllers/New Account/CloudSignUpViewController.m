/*******************************************************************************
 * Copyright (C) 2005-2014 Alfresco Software Limited.
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
 
#import "CloudSignUpViewController.h"
#import "TextFieldCell.h"
#import "ButtonCell.h"
#import "RequestHandler.h"
#import "UserAccount.h"
#import "AccountManager.h"
#import "CenterLabelCell.h"
#import "AttributedLabelCell.h"
#import "UniversalDevice.h"
#import "LoginManager.h"

static NSInteger const kCloudAwaitingVerificationTextSection = 0;
static NSInteger const kCloudRefreshSection = 1;
static NSInteger const kCloudReEmailSection = 2;
static NSInteger const kCloudCustomerCareSection = 3;

static NSInteger const kCloudTermsAndPolicySection = 1;
static NSInteger const kCloudTermsOfServiceRow = 0;
static NSInteger const kCloudPrivacyPolicyRow = 1;
static NSInteger const kCloudSignUpActionSection = 2;

static CGFloat const kAwaitingVerificationTextFontSize = 20.0f;

static CGFloat const kNormalRowHeight = 44.0f;

static NSString * const kFirstNameKey = @"firstName";
static NSString * const kLastNameKey = @"lastName";
static NSString * const kEmailKey = @"email";
static NSString * const kPasswordKey = @"password";
static NSString * const kSourceKey = @"source";
static NSString * const kSource = @"mobile";

@interface CloudSignUpViewController ()
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UITextField *firstNameTextField;
@property (nonatomic, strong) UITextField *LastNameTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *confirmPasswordTextField;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, strong) UIButton *signUpButton;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@property (nonatomic, strong) AttributedLabelCell *awaitingVerificationCell;
@end

@implementation CloudSignUpViewController

- (id)initWithAccount:(UserAccount *)account
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:nil];
    if (self)
    {
        self.account = account;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    if (self.account)
    {
        self.title = NSLocalizedString(@"awaitingverification.title", @"Alfresco Cloud");
    }
    else
    {
        self.title = NSLocalizedString(@"cloudsignup.title", @"New Account");
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(textFieldDidChange:) name:UITextFieldTextDidChangeNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWasShown:) name:UIKeyboardDidShowNotification object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyboardWillBeHidden:) name:UIKeyboardWillHideNotification object:nil];
    }
    
    UIBarButtonItem *cancel = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = cancel;
    
    self.allowsPullToRefresh = NO;
    [self constructTableCells];
    [self validateSignUpFields];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    // A small delay is necessary in order for the keyboard animation not to clash with the appear animation
    double delayInSeconds = 0.1;
    dispatch_time_t popTime = dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delayInSeconds * NSEC_PER_SEC));
    dispatch_after(popTime, dispatch_get_main_queue(), ^(void){
        [self.firstNameTextField becomeFirstResponder];
    });
}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(cloudSignupControllerWillDismiss:)])
    {
        [self.delegate cloudSignupControllerWillDismiss:self];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(cloudSignupControllerDidDismiss:)])
        {
            [self.delegate cloudSignupControllerDidDismiss:self];
        }
    }];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (!self.account && (section == kCloudSignUpActionSection))
    {
        return NSLocalizedString(@"cloudsignup.footer", @"By tapping 'Sign Up'...");
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat returnHeight = kNormalRowHeight;
    
    if ((self.account.accountStatus == UserAccountStatusAwaitingVerification) && (indexPath.section == kCloudAwaitingVerificationTextSection))
    {
        AttributedLabelCell *awaitingVerificationCell = [self awaitingVerificationCell];
        CGSize size = [awaitingVerificationCell.contentView systemLayoutSizeFittingSize:UILayoutFittingCompressedSize];
        returnHeight = size.height;
    }
    return returnHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return self.tableViewData[indexPath.section][indexPath.row];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.account && self.account.accountStatus == UserAccountStatusAwaitingVerification)
    {
        if (indexPath.section == kCloudRefreshSection)
        {
            [self refreshCloudAccountStatus];
        }
        else if (indexPath.section == kCloudReEmailSection)
        {
            [self resendCloudSignupEmail];
        }
        else if (indexPath.section == kCloudCustomerCareSection)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAlfrescoCloudCustomerCareUrl]];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else if (indexPath.section == kCloudTermsAndPolicySection)
    {
        if (indexPath.row == kCloudTermsOfServiceRow)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAlfrescoCloudTermOfServiceUrl]];
        }
        else if (indexPath.row == kCloudPrivacyPolicyRow)
        {
            [[UIApplication sharedApplication] openURL:[NSURL URLWithString:kAlfrescoCloudPrivacyPolicyUrl]];
        }
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
    else
    {
        UITableViewCell *selectedCell = [tableView cellForRowAtIndexPath:indexPath];
        selectedCell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
}

- (void)constructTableCells
{
    NSArray *group1 = nil;
    NSArray *group2 = nil;
    NSArray *group3 = nil;
    NSArray *group4 = nil;
    if (self.account == nil)
    {
        TextFieldCell *firstNameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        firstNameCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.firstName", @"First Name");
        firstNameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
        firstNameCell.valueTextField.returnKeyType = UIReturnKeyNext;
        firstNameCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        firstNameCell.valueTextField.delegate = self;
        self.firstNameTextField = firstNameCell.valueTextField;
        
        TextFieldCell *lastNameCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        lastNameCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.lastName", @"Last Name");
        lastNameCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
        lastNameCell.valueTextField.returnKeyType = UIReturnKeyNext;
        lastNameCell.valueTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
        lastNameCell.valueTextField.delegate = self;
        self.LastNameTextField = lastNameCell.valueTextField;
        
        TextFieldCell *emailCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        emailCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.email", @"Email address");
        emailCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.email", @"example@acme.com");
        emailCell.valueTextField.returnKeyType = UIReturnKeyNext;
        emailCell.valueTextField.keyboardType = UIKeyboardTypeEmailAddress;
        emailCell.valueTextField.delegate = self;
        self.emailTextField = emailCell.valueTextField;
        
        TextFieldCell *passwordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        passwordCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.password", @"Password");
        passwordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.password.requirement", @"password minimum characters");
        passwordCell.valueTextField.returnKeyType = UIReturnKeyNext;
        passwordCell.valueTextField.secureTextEntry = YES;
        passwordCell.valueTextField.delegate = self;
        self.passwordTextField = passwordCell.valueTextField;
        
        TextFieldCell *confirmPasswordCell = (TextFieldCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([TextFieldCell class]) owner:self options:nil] lastObject];
        confirmPasswordCell.titleLabel.text = NSLocalizedString(@"accountdetails.fields.confirmPassword", @"Confirm Password");
        confirmPasswordCell.valueTextField.placeholder = NSLocalizedString(@"accountdetails.placeholder.required", @"required");
        confirmPasswordCell.valueTextField.returnKeyType = UIReturnKeyDone;
        confirmPasswordCell.valueTextField.secureTextEntry = YES;
        confirmPasswordCell.valueTextField.delegate = self;
        self.confirmPasswordTextField = confirmPasswordCell.valueTextField;
        
        CenterLabelCell *termsCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        termsCell.titleLabel.text = NSLocalizedString(@"cloudsignup.label.termsOfService", @"");
        
        CenterLabelCell *policyCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        policyCell.titleLabel.text = NSLocalizedString(@"cloudsignup.label.privacyPolicy", @"");
        
        ButtonCell *signUpCell = (ButtonCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ButtonCell class]) owner:self options:nil] lastObject];
        [signUpCell.button setTitle:NSLocalizedString(@"cloudsignup.button.signup", @"Sign Up") forState:UIControlStateNormal];
        [signUpCell.button addTarget:self action:@selector(signUp:) forControlEvents:UIControlEventTouchUpInside];
        signUpCell.button.enabled = NO;
        self.signUpButton = signUpCell.button;
        
        group1 = @[firstNameCell, lastNameCell, emailCell, passwordCell, confirmPasswordCell];
        group2 = @[termsCell, policyCell];
        group3 = @[signUpCell];
        self.tableViewData = [NSMutableArray arrayWithArray:@[group1, group2, group3]];
    }
    else if (self.account.accountStatus == UserAccountStatusAwaitingVerification)
    {
        CenterLabelCell *refreshCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        refreshCell.titleLabel.text = NSLocalizedString(@"awaitingverification.buttons.refresh", @"Refresh");
        
        CenterLabelCell *resendEmailCell = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        resendEmailCell.titleLabel.text = NSLocalizedString(@"awaitingverification.buttons.resendEmail", @"Browse Documents");
        
        CenterLabelCell *customerCare = (CenterLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([CenterLabelCell class]) owner:self options:nil] lastObject];
        customerCare.titleLabel.text = NSLocalizedString(@"awaitingverification.buttons.customercare", @"Customer Care");
        
        group1 = @[[self awaitingVerificationCell]];
        group2 = @[refreshCell];
        group3 = @[resendEmailCell];
        group4 = @[customerCare];
        self.tableViewData = [NSMutableArray arrayWithArray:@[group1, group2, group3, group4]];
    }
}

- (AttributedLabelCell *)awaitingVerificationCell
{
    if (!_awaitingVerificationCell)
    {
        _awaitingVerificationCell = (AttributedLabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AttributedLabelCell class]) owner:self options:nil] lastObject];
        NSMutableAttributedString *awaitingVerificationText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:NSLocalizedString(@"awaitingverification.description", @"Account Awaiting Email Verification..."), self.account.username]];
        
        NSRange titleRange = [[awaitingVerificationText string] rangeOfString:NSLocalizedString(@"awaitingverification.description.title", @"email verification")];
        NSRange helpRange = [[awaitingVerificationText string] rangeOfString:NSLocalizedString(@"awaitingverification.description.subtitle", @"having trouble activating")];
        
        UIFont *boldSystemFont = [UIFont boldSystemFontOfSize:kAwaitingVerificationTextFontSize];
        
        [awaitingVerificationText setAttributes:@{NSFontAttributeName:boldSystemFont} range:titleRange];
        [awaitingVerificationText setAttributes:@{NSFontAttributeName:boldSystemFont} range:helpRange];
        
        _awaitingVerificationCell.attributedLabel.attributedText = awaitingVerificationText;
        [_awaitingVerificationCell.attributedLabel sizeThatFits:awaitingVerificationText.size];
        [_awaitingVerificationCell setNeedsLayout];
        [_awaitingVerificationCell layoutIfNeeded];
    }
    return _awaitingVerificationCell;
}

#pragma mark - private methods

- (void)refreshCloudAccountStatus
{
    AccountManager *accountManager = [AccountManager sharedManager];
    [self showHUD];
    [accountManager updateAccountStatusForAccount:self.account completionBlock:^(BOOL successful, NSError *error) {
        [self hideHUD];
        if (successful)
        {
            if (self.account.accountStatus == UserAccountStatusAwaitingVerification)
            {
                displayInformationMessage(NSLocalizedString(@"awaitingverification.alert.refresh.awaiting", @"Still waiting for verification"));
            }
            else
            {
                [UniversalDevice clearDetailViewController];
                [accountManager saveAccountsToKeychain];
                displayInformationMessage(NSLocalizedString(@"awaitingverification.alert.refresh.verified", @"The Account is now..."));
                
                [[LoginManager sharedManager] authenticateCloudAccount:self.account networkId:nil navigationController:nil completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                    if (successful)
                    {
                        AccountManager *accountManager = [AccountManager sharedManager];
                        [accountManager saveAccountsToKeychain];
                        
                        // select this account as selected Account if this is the only account configured
                        if (accountManager.totalNumberOfAddedAccounts == 1)
                        {
                            [accountManager selectAccount:self.account selectNetwork:[self.account.accountNetworks firstObject] alfrescoSession:alfrescoSession];
                        }
                        [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
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
        else
        {
            displayErrorMessage(NSLocalizedString(@"error.no.internet.access.title", "A connection couldn't be made"));
        }
    }];
}

- (void)resendCloudSignupEmail
{
    NSDictionary *headers = @{kCloudAPIHeaderKey : INTERNAL_CLOUD_API_KEY};
    NSData *accountInfoJsonData = jsonDataFromDictionary([self accountInfo]);
    
    RequestHandler *request = [[RequestHandler alloc] init];
    [self showHUD];
    [request connectWithURL:[NSURL URLWithString:kAlfrescoCloudAPISignUpUrl] method:kHTTPMethodPOST headers:headers requestBody:accountInfoJsonData completionBlock:^(NSData *data, NSError *error) {
        [self hideHUD];
        if (error)
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"awaitingverification.alert.resendEmail.error", @"The Email resend unsuccessful..."), NSLocalizedString(@"awaitingverification.alerts.title", @"Alfresco Cloud"));
        }
        else
        {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedString(@"awaitingverification.alert.resendEmail.title", @"Successfully Resent Email")
                                                            message:NSLocalizedString(@"awaitingverification.alert.resendEmail.success", @"The Email was...")
                                                           delegate:nil
                                                  cancelButtonTitle:NSLocalizedString(@"Done", @"Done")
                                                  otherButtonTitles:nil, nil];
            [alert show];
        }
    }];
}

- (void)signUp:(id)sender
{
    NSDictionary *headers = @{kCloudAPIHeaderKey : INTERNAL_CLOUD_API_KEY};
    NSData *accountInfoJsonData = jsonDataFromDictionary([self accountInfo]);
    
    RequestHandler *request = [[RequestHandler alloc] init];
    [self showHUD];
    [request connectWithURL:[NSURL URLWithString:kAlfrescoCloudAPISignUpUrl] method:kHTTPMethodPOST headers:headers requestBody:accountInfoJsonData completionBlock:^(NSData *data, NSError *error) {
        [self hideHUD];
        if (error)
        {
            displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.unsuccessful.message", @"The cloud sign up was unsuccessful, please try again later"), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
        }
        else
        {
            UserAccount *account = [[UserAccount alloc] initWithAccountType:UserAccountTypeCloud];
            account.accountStatus = UserAccountStatusAwaitingVerification;
            account.username = self.emailTextField.text;
            account.password = self.passwordTextField.text;
            account.firstName = self.firstNameTextField.text;
            account.lastName = self.LastNameTextField.text;
            account.accountDescription = NSLocalizedString(@"accounttype.cloud", @"Alfresco Cloud");
            
            NSError *jsonError = nil;
            NSDictionary *accountInfoReceived = [NSJSONSerialization JSONObjectWithData:data options:0 error:&jsonError];
            
            if (jsonError)
            {
                displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.unsuccessful.message", @"The cloud sign up was unsuccessful, please try again later"), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
            }
            else
            {
                account.cloudAccountId = [accountInfoReceived valueForKeyPath:kCloudAccountIdValuePath];
                account.cloudAccountKey = [accountInfoReceived valueForKeyPath:kCloudAccountKeyValuePath];
                
                // Check these keys - they're null if the user has already signed-up, for example
                if ([account.cloudAccountId isKindOfClass:[NSNull class]] || [account.cloudAccountKey isKindOfClass:[NSNull class]])
                {
                    displayErrorMessageWithTitle(NSLocalizedString(@"cloudsignup.already-registered.message", @"You already have an Alfresco account associated with this e-mail address"), NSLocalizedString(@"cloudsignup.alert.title", @"Alfresco Cloud Sign Up"));
                }
                else
                {
                    [[AccountManager sharedManager] addAccount:account];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            }
        }
    }];
}

- (NSDictionary *)accountInfo
{
    NSDictionary *accountInfo = nil;
    if (self.account)
    {
        accountInfo = @{kEmailKey : self.account.username,
                        kFirstNameKey : self.account.firstName,
                        kLastNameKey : self.account.lastName,
                        kPasswordKey : self.account.password,
                        kSourceKey : kSource};
    }
    else
    {
        accountInfo = @{kEmailKey : self.emailTextField.text,
                        kFirstNameKey : self.firstNameTextField.text,
                        kLastNameKey : self.LastNameTextField.text,
                        kPasswordKey : self.passwordTextField.text,
                        kSourceKey : kSource};
    }
    return accountInfo;
}

- (BOOL)validateSignUpFields
{
    NSString *firstName = [self.firstNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *lastName = [self.LastNameTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *email = [self.emailTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *password = [self.passwordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *confirmPassword = [self.confirmPasswordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    
    BOOL isValidName = (firstName.length > 0 && lastName.length > 0);
    BOOL isValidEmail = [Utility isValidEmail:email];
    BOOL isValidPassword = password.length >= 6;
    BOOL isValidPasswordConfirmation = [password isEqualToString:confirmPassword];
    
    BOOL isFormValid = isValidName && isValidEmail && isValidPassword && isValidPasswordConfirmation;
    
    self.signUpButton.enabled = isFormValid ? YES : NO;
    self.signUpButton.titleLabel.textColor = isFormValid ? [UIColor textDefaultColor] : [UIColor textDimmedColor];
    
    return isFormValid;
}

#pragma mark - UITextFieldDelegate Functions

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
    [self validateSignUpFields];
    
    if (textField == self.firstNameTextField)
    {
        [self.LastNameTextField becomeFirstResponder];
    }
    else if (textField == self.LastNameTextField)
    {
        [self.emailTextField becomeFirstResponder];
    }
    else if (textField == self.emailTextField)
    {
        [self.passwordTextField becomeFirstResponder];
    }
    else if (textField == self.passwordTextField)
    {
        [self.confirmPasswordTextField becomeFirstResponder];
    }
    else if (textField == self.confirmPasswordTextField)
    {
        [self.confirmPasswordTextField resignFirstResponder];
    }
    return YES;
}

- (void)textFieldDidChange:(NSNotification *)notification
{
    [self validateSignUpFields];
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
    UITableViewCell *cell = (UITableViewCell *)[self.activeTextField superview];
    
    while (cell)
    {
        if ([cell isKindOfClass:[UITableViewCell class]])
        {
            if (!CGRectContainsPoint(self.tableViewVisibleRect, cell.frame.origin))
            {
                [self.tableView scrollRectToVisible:cell.frame animated:YES];
            }
            break;
        }
        else
        {
            cell = (UITableViewCell *)cell.superview;
        }
    }
}

@end
