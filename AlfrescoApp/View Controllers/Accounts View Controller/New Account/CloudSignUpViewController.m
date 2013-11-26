//
//  CloudSignUpViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 06/11/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "CloudSignUpViewController.h"
#import "TextFieldCell.h"
#import "ButtonCell.h"
#import "Utility.h"

static NSInteger const kCloudSignUpActionSectionNumber = 1;

@interface CloudSignUpViewController ()
@property (nonatomic, strong) NSArray *tableGroups;
@property (nonatomic, strong) UITextField *firstNameTextField;
@property (nonatomic, strong) UITextField *LastNameTextField;
@property (nonatomic, strong) UITextField *emailTextField;
@property (nonatomic, strong) UITextField *passwordTextField;
@property (nonatomic, strong) UITextField *confirmPasswordTextField;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, strong) UIButton *signUpButton;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@end

@implementation CloudSignUpViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:nil];
    if (self)
    {
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	
    self.title = NSLocalizedString(@"cloudsignup.title", @"New Account");
    [self disablePullToRefresh];
    
    [self constructTableCells];
    [self validateSignUpFields];
    
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

#pragma mark - TableView Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return self.tableGroups.count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.tableGroups[section] count];
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    if (section == kCloudSignUpActionSectionNumber)
    {
        return [self cloudAccountFooter];
    }
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

- (void)constructTableCells
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
    
    ButtonCell *signUpCell = (ButtonCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([ButtonCell class]) owner:self options:nil] lastObject];
    [signUpCell.button setTitle:NSLocalizedString(@"cloudsignup.button.signup", @"Sign Up") forState:UIControlStateNormal];
    [signUpCell.button addTarget:self action:@selector(signUp:) forControlEvents:UIControlEventTouchUpInside];
    signUpCell.button.enabled = NO;
    self.signUpButton = signUpCell.button;
    
    NSArray *group1 = @[firstNameCell, lastNameCell, emailCell, passwordCell, confirmPasswordCell];
    NSArray *group2 = @[signUpCell];
    self.tableGroups = @[group1, group2];
}

#pragma mark - private methods

- (void)signUp:(id)sender
{
    NSLog(@"signup button pressed");
}

- (void)attributedLabel:(TTTAttributedLabel *)label didSelectLinkWithURL:(NSURL *)url
{
    [[UIApplication sharedApplication] openURL:url];
}

- (UIView *)cloudAccountFooter
{
    CGFloat footerWidth = IS_IPAD ? 540 : (UIInterfaceOrientationIsLandscape([UIApplication sharedApplication].statusBarOrientation) ? 480 : 320);
    NSString *footerText = NSLocalizedString(@"cloudsignup.footer.firstLine", @"By tapping 'Sign Up'...");
    NSString *signupText = NSLocalizedString(@"cloudsignup.footer.secondLine", @"Alfresco Terms of ...");
    UIView *footerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, footerWidth, 0)];
    [footerView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth];
    
    UILabel *footerTextView = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, footerWidth, 0)];
    footerTextView.backgroundColor = [UIColor clearColor];
    footerTextView.numberOfLines = 0;
    footerTextView.textAlignment = NSTextAlignmentCenter;
    footerTextView.textColor = [UIColor colorWithRed:76/255.0 green:86/255.0 blue:108/255.0 alpha:1.0];
    footerTextView.font = [UIFont systemFontOfSize:15];
    footerTextView.text = footerText;
    [footerTextView sizeToFit];
    footerTextView.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth;
    
    // Restore width after sizeToFit
    CGRect footerTextFrame = footerTextView.frame;
    footerTextFrame.size.width = footerWidth;
    footerTextView.frame = footerTextFrame;
    
    TTTAttributedLabel *signupLabel = [[TTTAttributedLabel alloc] initWithFrame:CGRectMake(0, footerTextView.frame.size.height, footerWidth, 0)];
    signupLabel.backgroundColor = [UIColor clearColor];
    signupLabel.numberOfLines = 0;
    signupLabel.textAlignment = NSTextAlignmentCenter;
    signupLabel.textColor = [UIColor colorWithRed:76.0/255.0 green:86.0/255.0 blue:108.0/255.0 alpha:1.0];
    signupLabel.font = [UIFont systemFontOfSize:15];
    signupLabel.userInteractionEnabled = YES;
    signupLabel.verticalAlignment = TTTAttributedLabelVerticalAlignmentTop;
    signupLabel.delegate = self;
    signupLabel.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    [signupLabel setText:signupText afterInheritingLabelAttributesAndConfiguringWithBlock:
     ^NSMutableAttributedString *(NSMutableAttributedString *mutableAttributedString)
     {
         return mutableAttributedString;
     }];
    
    [self addLink:[NSURL URLWithString:kAlfrescoCloudTermOfServiceUrl] toText:NSLocalizedString(@"cloudsignup.footer.termsOfService", @"") inString:signupText label:signupLabel];
    [self addLink:[NSURL URLWithString:kAlfrescoCloudPrivacyPolicyUrl] toText:NSLocalizedString(@"cloudsignup.footer.privacyPolicy", @"") inString:signupText label:signupLabel];
    
    [signupLabel sizeToFit];
    
    CGRect signupFrame = signupLabel.frame;
    signupFrame.size.width = footerWidth;
    signupLabel.frame = signupFrame;
    
    [footerView addSubview:footerTextView];
    [footerView addSubview:signupLabel];
    return footerView;
}

- (void)addLink:(NSURL *)url toText:(NSString *)text inString:(NSString *)completeString label:(TTTAttributedLabel *)label
{
    NSRange textRange = [completeString rangeOfString:text];
    if (textRange.length > 0)
    {
        [label addLinkToURL:url withRange:textRange];
        [label setDelegate:self];
    }
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
    self.signUpButton.titleLabel.textColor = isFormValid ? [UIColor blackColor] : [UIColor grayColor];
    
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

- (void)textFieldDidChange:(NSNotification *)note
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
