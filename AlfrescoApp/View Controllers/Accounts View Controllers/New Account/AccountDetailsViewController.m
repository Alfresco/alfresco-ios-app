/*******************************************************************************
 * Copyright (C) 2005-2017 Alfresco Software Limited.
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

#import "AccountDetailsViewController.h"
#import "TextFieldCell.h"
#import "UserAccount.h"
#import "ClientCertificateViewController.h"
#import "LoginManager.h"
#import "ConnectionDiagnosticViewController.h"
#import "AccountManager.h"
#import "RealmSyncManager.h"
#import "MainMenuReorderViewController.h"
#import "ProfileSelectionViewController.h"

@interface AccountDetailsViewController () <AccountDataSourceDelegate, AccountDetailsViewControllerDelegate>

@property (nonatomic, strong) UserAccount *account;
@property (nonatomic, strong) UserAccount *formBackupAccount;
@property (nonatomic, assign) AccountDataSourceType dataSourcetype;
@property (nonatomic, strong) AccountDataSource *dataSource;
@property (nonatomic, strong) UIBarButtonItem *saveButton;
@property (nonatomic, strong) UIBarButtonItem *cancelButton;
@property (nonatomic, strong, readwrite) MBProgressHUD *progressHUD;
@property (nonatomic, strong) id<AlfrescoSession> session;
@property (nonatomic, strong) NSDictionary *configuration;

@end

@implementation AccountDetailsViewController

#pragma mark - View Life Cycle Methods

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupBarButtonItems];
    [self setAccessibilityIdentifiers];
    
    self.tableView.dataSource = self.dataSource;
    self.title = self.dataSource.title;
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self trackScreenName];
    
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountServer:
        case AccountDataSourceTypeNewAccountCredentials:
        {
            UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
            
            if ([cell isKindOfClass:[TextFieldCell class]])
            {
                TextFieldCell *textFieldCell = (TextFieldCell *)cell;
                [textFieldCell.valueTextField becomeFirstResponder];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

#pragma mark - Setup

- (void)setupBarButtonItems
{
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountServer:
        {
            NSString *rightBarButtonTitle =  NSLocalizedString(@"Next", @"Next");
            self.saveButton = [[UIBarButtonItem alloc] initWithTitle:rightBarButtonTitle style:UIBarButtonItemStylePlain target:self action:@selector(saveButtonPressed:)];
            self.saveButton.enabled = NO;
        }
            break;
            
        case AccountDataSourceTypeAccountDetails:
        {
            self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:self action:@selector(saveButtonPressed:)];
        }
            break;
            
        default:
        {
            self.saveButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSave target:self action:@selector(saveButtonPressed:)];
            self.saveButton.enabled = NO;
        }
            break;
    }
    
    [self.navigationItem setRightBarButtonItem:self.saveButton];
    
    if (self.dataSourcetype != AccountDataSourceTypeAccountDetails)
    {
        self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(cancelButtonPressed:)];
        self.navigationItem.leftBarButtonItem = self.cancelButton;
    }
}

#pragma mark - Custom Init Methods

- (instancetype)initWithDataSourceType:(AccountDataSourceType)dataSourceType account:(UserAccount *)account configuration:(NSDictionary *)configuration session:(id<AlfrescoSession>)session
{
    if (self = [super init])
    {
        self.dataSourcetype = dataSourceType;
        self.session = session;
        self.configuration = configuration;
        
        switch (dataSourceType)
        {
            case AccountDataSourceTypeNewAccountServer:
                self.account = [[UserAccount alloc] initWithAccountType:UserAccountTypeOnPremise];
                self.formBackupAccount = [self.account copy];
                break;
                
            case AccountDataSourceTypeNewAccountCredentials:
                self.formBackupAccount = account;
                self.account = [[UserAccount alloc] initWithAccountType:UserAccountTypeOnPremise];
                break;
                
            default:
                self.account = account;
                self.formBackupAccount = [self.account copy];
                self.formBackupAccount.samlData = self.account.samlData;
                break;
        }
        
        self.dataSource = [[AccountDataSource alloc] initWithDataSourceType:dataSourceType account:self.account backupAccount:self.formBackupAccount configuration:configuration];
        self.dataSource.delegate = self;
    }
    
    return self;
}

#pragma mark - Bar Buttons Actions

- (void)saveButtonPressed:(id)sender
{
    if (self.dataSourcetype == AccountDataSourceTypeAccountDetails)
    {
        [self cancelButtonPressed:nil];
        return;
    }
    
    [self.dataSource updateFormBackupAccount];
    
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountServer:
        {
            [self checkIfSamlIsEnabled];
        }
            break;
            
        case AccountDataSourceTypeNewAccountCredentials:
        {
            [self addNewAccount];
        }
            break;
            
        case AccountDataSourceTypeAccountSettings:
        case AccountDataSourceTypeAccountSettingSAML:
        {
            [self changeAccount];
        }
            break;
            
        case AccountDataSourceTypeCloudAccountSettings:
        {
            self.account.accountDescription = self.formBackupAccount.accountDescription;
            
            [[AccountManager sharedManager] saveAccountsToKeychain];
            [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
            
            [self cancelButtonPressed:nil];
        }
            break;
            
        default:
            break;
    }
}

- (void)cancelButtonPressed:(id)sender
{
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeAccountSettings:
        case AccountDataSourceTypeAccountSettingSAML:
            [self.navigationController popViewControllerAnimated:YES];
            break;
            
        default:
            [self dismissViewControllerAnimated:YES completion:nil];
            break;
    }
}

#pragma mark - AccountDataSourceDelegate Methods

- (void)enableSaveBarButton:(BOOL)enable
{
    self.saveButton.enabled = enable;
}

#pragma mark - AccountDetailsViewControllerDelegate methods

- (void)accountInfoChanged:(UserAccount *)newAccount
{
    self.formBackupAccount = [newAccount copy];
    [self.dataSource reloadWithAccount:self.formBackupAccount];
    self.title = self.dataSource.title;
    [self.tableView reloadData];
    
    [[AccountManager sharedManager] saveAccountsToKeychain];
    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];

    if ([self.delegate respondsToSelector:@selector(accountInfoChanged:)])
    {
        [self.delegate accountInfoChanged:self.formBackupAccount];
    }
}

#pragma mark - UITableViewDelegate Methods

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if (cell.tag == kTagCertificateCell)
    {
        ClientCertificateViewController *clientCertificate = [[ClientCertificateViewController alloc] initWithAccount:self.account];
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
        AccountDataSourceType type = [self.account.samlData isSamlEnabled] ? AccountDataSourceTypeAccountSettingSAML : AccountDataSourceTypeAccountSettings;
        AccountDetailsViewController *accountDetailsViewController = [[AccountDetailsViewController alloc] initWithDataSourceType:type account:self.account configuration:self.configuration session:self.session];
        accountDetailsViewController.delegate = self;
        [self.navigationController pushViewController:accountDetailsViewController animated:YES];
    }
}

#pragma mark - Private Methods

- (void)trackScreenName
{
    NSString *screenName = nil;
    
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountServer:
            screenName = kAnalyticsViewAccountCreateServer;
            break;
        
        case AccountDataSourceTypeNewAccountCredentials:
            screenName = kAnalyticsViewAccountCreateCredentials;
            break;
            
        case AccountDataSourceTypeAccountDetails:
            screenName = kAnalyticsViewAccountEdit;
            break;
            
        case AccountDataSourceTypeAccountSettings:
        case AccountDataSourceTypeAccountSettingSAML:
        case AccountDataSourceTypeCloudAccountSettings:
            screenName = kAnalyticsViewAccountEditAccountDetails;
            break;
            
        default:
            break;
    }
    
    [[AnalyticsManager sharedManager] trackScreenWithName:screenName];
}

- (void)setAccessibilityIdentifiers
{
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountServer:
        {
            self.view.accessibilityIdentifier = kNewAccountVCServerViewIdentifier;
            self.cancelButton.accessibilityIdentifier = kNewAccountVCServerCancelButtonIdentifier;
            self.saveButton.accessibilityIdentifier = kNewAccountVCNextButtonIdentifier;
        }
            break;
            
        case AccountDataSourceTypeNewAccountCredentials:
        {
            self.view.accessibilityIdentifier = kNewAccountVCCredentialsViewIdentifier;
            self.cancelButton.accessibilityIdentifier = kNewAccountVCCredentialsCancelButtonIdentifier;
            self.saveButton.accessibilityIdentifier = kNewAccountVCSaveButtonIdentifier;
        }
            break;
            
        default:
            break;
    }
}

- (void)checkIfSamlIsEnabled
{
    [self showHUD];
    NSString *urlString = [Utility serverURLStringFromAccount:self.formBackupAccount];
    
    [AlfrescoSAMLAuthHelper checkIfSAMLIsEnabledForServerWithUrlString:urlString completionBlock:^(AlfrescoSAMLData *samlData, NSError *error) {
        [self hideHUD];
        
        if (error || [samlData isSamlEnabled] == NO)
        {
            [self goToEnterCredentialsScreen];
        }
        else
        {
            self.formBackupAccount.samlData = samlData;
            [self goToLoginWithSamlScreen];
        }
    }];
}

- (void)goToEnterCredentialsScreen
{
    AccountDetailsViewController *accountDetailsViewController = [[AccountDetailsViewController alloc] initWithDataSourceType:AccountDataSourceTypeNewAccountCredentials account:self.formBackupAccount configuration:nil session:nil];
    accountDetailsViewController.delegate = self.delegate;
    [self.navigationController pushViewController:accountDetailsViewController animated:YES];
}

- (void)goToLoginWithSamlScreen
{
    void (^receivedSessionBlock)(BOOL, id<AlfrescoSession>, NSError *) = ^void(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error){
        if (alfrescoSession)
        {
            [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryAccount
                                                              action:kAnalyticsEventActionCreate
                                                               label:kAnalyticsEventLabelOnPremiseSAML
                                                               value:@1];
            
            [self updateAccountInfoFromAccount:self.formBackupAccount];
            self.account.accountDescription = NSLocalizedString(@"accounttype.alfrescoServer", @"Content Services");
            
            AccountManager *accountManager = [AccountManager sharedManager];
            [[RealmSyncManager sharedManager] realmForAccount:self.account.accountIdentifier];
            
            if (accountManager.totalNumberOfAddedAccounts == 0)
            {
                [accountManager selectAccount:self.account selectNetwork:nil alfrescoSession:alfrescoSession];
            }
            else if (accountManager.selectedAccount == self.account)
            {
                [[RealmManager sharedManager] changeDefaultConfigurationForAccount:self.account completionBlock:^{
                    [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:alfrescoSession userInfo:nil];
                }];
            }
            
            [self dismiss];
        }
    };
    
    void (^obtainedSamlDataBlock)(AlfrescoSAMLData *, NSError *) = ^void(AlfrescoSAMLData *samlData, NSError *error){
        if (samlData)
        {
            self.formBackupAccount.samlData.samlTicket = samlData.samlTicket;
            
            [[LoginManager sharedManager] authenticateWithSAMLOnPremiseAccount:self.formBackupAccount
                                                          navigationController:self.navigationController
                                                               completionBlock:receivedSessionBlock];
        }
    };
    
    [[LoginManager sharedManager] showSAMLWebViewForAccount:self.formBackupAccount
                                       navigationController:self.navigationController
                                            completionBlock:obtainedSamlDataBlock];
}

- (void)addNewAccount
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
            
            [self dismiss];
        }
    }];
}

- (void)changeAccount
{
    [self validateAccountOnServerWithCompletionBlock:^(BOOL successful, id<AlfrescoSession> session) {
        if (successful)
        {
            AccountManager *accountManager = [AccountManager sharedManager];
            [accountManager saveAccountsToKeychain];
            
            if(self.account == accountManager.selectedAccount)
            {
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoSessionReceivedNotification object:session userInfo:nil];
                [[NSNotificationCenter defaultCenter] postNotificationName:kAlfrescoAccountUpdatedNotification object:self.account];
            }

            [self.navigationController popViewControllerAnimated:YES];
        }
    }];
}

- (void)validateAccountOnServerWithCompletionBlock:(void (^)(BOOL successful, id<AlfrescoSession> session))completionBlock
{
    void (^authenticationCompletionBlock)(BOOL, id<AlfrescoSession>) = ^void(BOOL successful, id<AlfrescoSession>alfrescoSession){
        [self hideHUD];
        if (successful)
        {
            [self updateAccountInfoFromAccount:self.formBackupAccount];
            completionBlock(successful, alfrescoSession);
        }
        else
        {
            [self presentLoginForConnectionDiagnostic];
        }
    };
    
    [self showHUD];
    
    switch (self.dataSourcetype)
    {
        case AccountDataSourceTypeNewAccountCredentials:
        case AccountDataSourceTypeAccountSettings:
        {
            [[LoginManager sharedManager] authenticateOnPremiseAccount:self.formBackupAccount
                                                              password:self.formBackupAccount.password
                                                       completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                                           authenticationCompletionBlock(successful, alfrescoSession);
                                                       }];
        }
            break;
        
        case AccountDataSourceTypeAccountSettingSAML:
        {
            
            [[LoginManager sharedManager] authenticateWithSAMLOnPremiseAccount:self.formBackupAccount
                                                          navigationController:self.navigationController
                                                               completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                                                   if (successful)
                                                                   {
                                                                       authenticationCompletionBlock(successful, alfrescoSession);
                                                                   }
                                                                   else
                                                                   {
                                                                       [[LoginManager sharedManager] showSAMLWebViewForAccount:self.formBackupAccount navigationController:self.navigationController completionBlock:^(AlfrescoSAMLData *samlData, NSError *error) {
                                                                           if (samlData)
                                                                           {
                                                                               self.formBackupAccount.samlData.samlTicket = samlData.samlTicket;
                                                                               [self.navigationController popViewControllerAnimated:YES];
                                                                               
                                                                               [[LoginManager sharedManager] authenticateWithSAMLOnPremiseAccount:self.formBackupAccount navigationController:self.navigationController completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                                                                                   authenticationCompletionBlock(successful, alfrescoSession);
                                                                               }];
                                                                           }
                                                                           else
                                                                           {
                                                                               authenticationCompletionBlock(NO, nil);
                                                                           }
                                                                       }];
                                                                   }
                                                       }];
        }
            
        default:
            break;
    }
}

- (void)presentLoginForConnectionDiagnostic
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

- (void)retryLoginForConnectionDiagnostic
{
    [[LoginManager sharedManager] authenticateOnPremiseAccount:self.formBackupAccount password:self.formBackupAccount.password completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
        if (successful)
        {
            [self updateAccountInfoFromAccount:self.formBackupAccount];
        }
    }];
}

- (void)updateAccountInfoFromAccount:(UserAccount *)temporaryAccount
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
    self.account.samlData = temporaryAccount.samlData;
    
    if ([self.delegate respondsToSelector:@selector(accountInfoChanged:)])
    {
        [self.delegate accountInfoChanged:self.account];
    }
}

- (void)dismiss
{
    if ([self.delegate respondsToSelector:@selector(accountDetailsViewController:willDismissAfterAddingAccount:)])
    {
        [self.delegate accountDetailsViewController:self willDismissAfterAddingAccount:self.account];
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        [[AccountManager sharedManager] addAccount:self.account];
        
        if ([self.delegate respondsToSelector:@selector(accountDetailsViewController:didDismissAfterAddingAccount:)])
        {
            [self.delegate accountDetailsViewController:self didDismissAfterAddingAccount:self.account];
        }
    }];
}

#pragma mark - HUD Methods

- (void)showHUD
{
    [self showHUDWithMode:MBProgressHUDModeIndeterminate];
}

- (void)showHUDWithMode:(MBProgressHUDMode)mode
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!self.progressHUD)
        {
            self.progressHUD = [[MBProgressHUD alloc] initWithView:self.view];
            [self.tableView addSubview:self.progressHUD];
        }
        self.progressHUD.mode = mode;
        [self.progressHUD showAnimated:YES];
    });
}

- (void)hideHUD
{
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.progressHUD hideAnimated:YES];
        self.progressHUD.mode = MBProgressHUDModeIndeterminate;
    });
}

@end
