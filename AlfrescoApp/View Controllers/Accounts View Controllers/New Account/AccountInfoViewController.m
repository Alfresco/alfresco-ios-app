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
#import "ProfileSelectionViewController.h"
#import "AppConfigurationManager.h"
#import "AccountInfoDetailsViewController.h"

static NSString * const kServiceDocument = @"/alfresco";

static NSInteger const kTagCertificateCell = 1;
static NSInteger const kTagReorderCell = 2;
static NSInteger const kTagProfileCell = 3;
static NSInteger const kTagAccountDetailsCell = 4;

@interface AccountInfoViewController () <AccountInfoDetailsDelegate>
@property (nonatomic, assign) AccountActivityType activityType;
@property (nonatomic, strong) NSArray *tableGroupHeaders;
@property (nonatomic, strong) NSArray *tableGroupFooters;
@property (nonatomic, weak) UITextField *descriptionTextField;
@property (nonatomic, weak) UILabel *profileLabel;
@property (nonatomic, weak) UISwitch *syncPreferenceSwitch;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UserAccount *formBackupAccount;
@property (nonatomic, strong) UITextField *activeTextField;
@property (nonatomic, assign) CGRect tableViewVisibleRect;
@property (nonatomic, strong) NSDictionary *configuration;
@property (nonatomic, assign) BOOL canEditAccounts;
@property (nonatomic, assign) BOOL canReorderMainMenuItems;

@property (nonatomic, strong) NSString *usernameString;
@property (nonatomic, strong) NSString *passwordString;
@property (nonatomic, strong) NSString *serverAddressString;
@property (nonatomic, strong) NSString *descriptionString;
@property (nonatomic, strong) NSString *portString;
@property (nonatomic, strong) NSString *serviceDocumentString;
@property (nonatomic, strong) NSString *protocolString;
@property (nonatomic, strong) NSString *certificateString;

@property (nonatomic) BOOL hasChangedAccountDetails;

@end

@implementation AccountInfoViewController

- (instancetype)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType
{
    return [self initWithAccount:account accountActivityType:activityType configuration:nil];
}

- (instancetype)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType configuration:(NSDictionary *)configuration
{
    return [self initWithAccount:account accountActivityType:activityType configuration:configuration session:nil];
}

- (instancetype)initWithAccount:(UserAccount *)account accountActivityType:(AccountActivityType)activityType configuration:(NSDictionary *)configuration session:(id<AlfrescoSession>)session
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
        self.activityType = activityType;
        self.formBackupAccount = [self.account copy];
        self.configuration = configuration;
        NSNumber *canEditAccounts = configuration[kAppConfigurationCanEditAccountsKey];
        self.canEditAccounts = (canEditAccounts) ? canEditAccounts.boolValue : YES;
        
        NSNumber *canReorderMenuItems = configuration[kAppConfigurationUserCanEditMainMenuKey];
        self.canReorderMainMenuItems = ((canReorderMenuItems.boolValue && account == [AccountManager sharedManager].selectedAccount) || [[AppConfigurationManager sharedManager] serverConfigurationExistsForAccount:account]) ? canReorderMenuItems.boolValue : YES;
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
    
    self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone
                                                                    target:self
                                                                    action:@selector(saveButtonClicked:)];
    [self.navigationItem setRightBarButtonItem:self.saveButton];
    
    self.usernameString = self.account.username;
    self.passwordString = self.account.password;
    self.serverAddressString = self.account.serverAddress;
    self.descriptionString = self.account.accountDescription;
    self.portString = self.account.serverPort;
    self.serviceDocumentString = self.account.serviceDocument;
    self.protocolString = self.account.protocol;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
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

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self updateFormBackupAccount];
}

- (void)saveButtonClicked:(id)sender
{
    if([self validateAccountFieldsValuesForServer])
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
    else
    {
        [self cancel:sender];
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
        MainMenuReorderViewController *reorderController = [[MainMenuReorderViewController alloc] initWithAccount:self.account session:self.session];
        [self.navigationController pushViewController:reorderController animated:YES];
    }
    else if (cell.tag == kTagProfileCell)
    {
        ProfileSelectionViewController *profileSelectionViewController = [[ProfileSelectionViewController alloc] initWithAccount:self.account session:self.session];
        [self.navigationController pushViewController:profileSelectionViewController animated:YES];
    }
    else if (cell.tag == kTagAccountDetailsCell)
    {
        AccountInfoDetailsViewController *accountInfoDetailsViewController = [[AccountInfoDetailsViewController alloc] initWithAccount:self.formBackupAccount configuration:self.configuration session:self.session delegate:self];
        [self.navigationController pushViewController:accountInfoDetailsViewController animated:YES];
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
    [self.syncPreferenceSwitch setOn:self.formBackupAccount.isSyncOn animated:YES];
    
    if (self.account.accountType == UserAccountTypeOnPremise)
    {
        /**
         * Note: Additional account-specific settings should be in their own group with an empty header string.
         * This will allow a description footer to be added under each setting if required.
         */
        LabelCell *profileCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        profileCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        profileCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        profileCell.tag = kTagProfileCell;
        profileCell.titleLabel.text = NSLocalizedString(@"accountdetails.buttons.profile", @"Profile");
        profileCell.valueLabel.text = self.account.selectedProfileName;
        profileCell.valueLabel.textColor = [UIColor lightGrayColor];
        self.profileLabel = profileCell.valueLabel;
        
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
        
        LabelCell *accountDetailsCell = (LabelCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([LabelCell class]) owner:self options:nil] lastObject];
        accountDetailsCell.selectionStyle = UITableViewCellSelectionStyleDefault;
        accountDetailsCell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        accountDetailsCell.tag = kTagAccountDetailsCell;
        accountDetailsCell.titleLabel.text = self.formBackupAccount.accountDescription;
        accountDetailsCell.valueLabel.text = self.formBackupAccount.username;
        accountDetailsCell.valueLabel.textColor = [UIColor lightGrayColor];
        
        self.tableViewData = [NSMutableArray arrayWithArray:@[ @[profileCell],
                                                               @[configurationCell],
                                                               @[syncPreferenceCell],
                                                               @[accountDetailsCell]
                                                               /*@[usernameCell, passwordCell, serverAddressCell, descriptionCell, protocolCell],
                                                                @[portCell, serviceDocumentCell, certificateCell]*/]];
        self.tableGroupHeaders = @[@"accountdetails.header.profile", @"accountdetails.header.main.menu.config", @"accountdetails.header.setting", @"accountdetails.header.authentication"/*, @"accountdetails.header.advanced"*/];
        self.tableGroupFooters = @[@"", (self.canReorderMainMenuItems) ? @"" : @"accountdetails.footer.main.menu.config.disabled", @"accountdetails.fields.syncPreference.footer", @""/*,  @""*/];
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

#pragma mark - private Methods

- (void)updateFormBackupAccount
{
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
        if (self.activityType == AccountActivityTypeEditAccount)
        {
            if (!(self.formBackupAccount.isSyncOn == self.syncPreferenceSwitch.isOn))
            {
                hasAccountPropertiesChanged = YES;
            }
            if(self.hasChangedAccountDetails)
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

#pragma mark - Notifictaions

-(void)profileDidChange:(NSNotification *)notifictaion
{
    AlfrescoProfileConfig *selectedProfile = notifictaion.object;
    self.profileLabel.text = selectedProfile.label;
    
    NSString *title = NSLocalizedString(@"main.menu.profile.selection.banner.title", @"Profile Changed Title");
    NSString *message = [NSString stringWithFormat:NSLocalizedString(@"main.menu.profile.selection.banner.message", @"Profile Changed"), selectedProfile.label];
    displayInformationMessageWithTitle(message, title);
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

#pragma mark - Account Info Details Delegate methods
- (void)accountInfoChanged:(UserAccount *)newAccount
{
    self.hasChangedAccountDetails = YES;
    self.formBackupAccount = [newAccount copy];
    
    self.title = self.formBackupAccount.accountDescription;
    [self constructTableCellsForAlfrescoServer];
    [self.tableView reloadData];
    
}

#pragma mark - UITextFieldDelegate Functions

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    return self.canEditAccounts;
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

@end
