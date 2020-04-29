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
 
#import "AccountTypeSelectionViewController.h"
#import "LoginManager.h"
#import "AccountManager.h"
#import "RealmSyncManager.h"
#import "AccountDetailsViewController.h"

static NSInteger const kNumberAccountTypes = 2;
static NSInteger const kNumberOfTypesPerSection = 1;

static NSInteger const kCloudSectionNumber = 0;

static CGFloat const kAccountTypeTitleFontSize = 18.0f;
static CGFloat const kAccountTypeCellRowHeight = 66.0f;

@interface AccountTypeSelectionViewController () <AccountFlowDelegate>

@property (nonatomic, strong) UIBarButtonItem *cancelButton;

@end

@implementation AccountTypeSelectionViewController

- (id)init
{
    self = [super initWithNibName:NSStringFromClass([self class]) andSession:nil];
    if (self)
    {
    }
    return self;
}

- (instancetype)initWithDelegate:(id<AccountFlowDelegate>)delegate
{
    self = [self init];
    if (self)
    {
        self.delegate = delegate;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.allowsPullToRefresh = NO;
    self.title = NSLocalizedString(@"accountdetails.title.newaccount", @"New Account");
    
    self.cancelButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel
                                                                            target:self
                                                                            action:@selector(cancel:)];
    self.navigationItem.leftBarButtonItem = self.cancelButton;
    [self setAccessibilityIdentifiers];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [[AnalyticsManager sharedManager] trackScreenWithName:kAnalyticsViewAccountCreateTypePicker];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return kNumberAccountTypes;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return kNumberOfTypesPerSection;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *CellIdentifier = @"AccountTypeCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }
    
    cell.textLabel.font = [UIFont boldSystemFontOfSize:kAccountTypeTitleFontSize];
    if (indexPath.section == 0)
    {
        cell.imageView.image = [[UIImage imageNamed:@"account-type-cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        cell.textLabel.text = NSLocalizedString(@"accounttype.cloud", @"Alfresco in the Cloud");
        cell.accessibilityIdentifier = kAccountTypeSelectionVCCloudCellIdentifier;
    }
    else
    {
        cell.imageView.image = [UIImage imageNamed:@"account-type-onpremise.png"];
        cell.textLabel.text = NSLocalizedString(@"accounttype.alfrescoServer", @"Alfresco Server");
        cell.accessoryView = nil;
        cell.accessibilityIdentifier = kAccountTypeSelectionVCOnPremiseCellIdentifier;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == kCloudSectionNumber)
    {
        __weak typeof(self) weakSelf = self;
        [[AccountManager sharedManager] presentCloudTerminationAlertControllerOnViewController:self completionBlock:^{
            __strong typeof(self) strongSelf = weakSelf;
            UserAccount *account = [[UserAccount alloc] initWithAccountType:UserAccountTypeCloud];
            account.accountDescription = NSLocalizedString(@"accounttype.cloud", @"Alfresco in the Cloud");
            
            [[LoginManager sharedManager] authenticateCloudAccount:account networkId:nil navigationController:strongSelf.navigationController completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                if (successful)
                {
                    [[AnalyticsManager sharedManager] trackEventWithCategory:kAnalyticsEventCategoryAccount
                                                                      action:kAnalyticsEventActionCreate
                                                                       label:kAnalyticsEventLabelCloud
                                                                       value:@1];
                    
                    AccountManager *accountManager = [AccountManager sharedManager];
                    [[RealmSyncManager sharedManager] realmForAccount:account.accountIdentifier];
                    
                    if (accountManager.totalNumberOfAddedAccounts == 0)
                    {
                        [accountManager selectAccount:account selectNetwork:[account.accountNetworks firstObject] alfrescoSession:alfrescoSession];
                    }
                    
                    if ([strongSelf.delegate respondsToSelector:@selector(accountFlowWillDismiss:accountAdded:)])
                    {
                        [strongSelf.delegate accountFlowWillDismiss:strongSelf accountAdded:account];
                    }
                    
                    [strongSelf dismissViewControllerAnimated:YES completion:^{
                        if ([strongSelf.delegate respondsToSelector:@selector(accountFlowDidDismiss:accountAdded:)])
                        {
                            [strongSelf.delegate accountFlowDidDismiss:strongSelf accountAdded:account];
                        }
                    }];
                    
                    [accountManager addAccount:account];
                }
                else
                {
                    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:NSLocalizedString(@"accountdetails.alert.save.title", @"Save Account")
                                                                                             message:NSLocalizedString(@"accountdetails.alert.save.validationerror", @"Login Failed Message")
                                                                                      preferredStyle:UIAlertControllerStyleAlert];
                    UIAlertAction *doneAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Done", @"Done")
                                                                         style:UIAlertActionStyleCancel
                                                                       handler:nil];
                    [alertController addAction:doneAction];
                    [strongSelf presentViewController:alertController animated:YES completion:nil];
                }
            }];
        }];
    }
    else
    {
        AccountDetailsViewController *accountDetailsViewController = [[AccountDetailsViewController alloc] initWithDataSourceType:AccountDataSourceTypeNewAccountServer account:nil configuration:nil session:nil];
        accountDetailsViewController.delegate = self;
        [self.navigationController pushViewController:accountDetailsViewController animated:YES];
    }

}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    NSString *titleKey = (section == kCloudSectionNumber) ? @"accounttype.footer.alfrescoCloud" : @"accounttype.footer.alfrescoServer";
    return NSLocalizedString(titleKey, @"Access Alfresco Account");
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return kAccountTypeCellRowHeight;
}

#pragma mark - private functions

- (void)setAccessibilityIdentifiers
{
    self.view.accessibilityIdentifier = kAccountTypeSelectionVCViewIdentifier;
    self.cancelButton.accessibilityIdentifier = kAccountTypeSelectionVCCancelButtonIdentifier;
}

- (void)cancel:(id)sender
{
    if ([self.delegate respondsToSelector:@selector(accountFlowWillDismiss:accountAdded:)])
    {
        [self.delegate accountFlowWillDismiss:self accountAdded:nil];
    }
    [self dismissViewControllerAnimated:YES completion:^{
        if ([self.delegate respondsToSelector:@selector(accountFlowDidDismiss:accountAdded:)])
        {
            [self.delegate accountFlowDidDismiss:self accountAdded:nil];
        }
    }];
}

@end
