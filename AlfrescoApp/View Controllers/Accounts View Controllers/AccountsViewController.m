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
 
#import "AccountsViewController.h"
#import "AccountManager.h"
#import "AccountTypeSelectionViewController.h"
#import "NavigationViewController.h"
#import "AccountInfoViewController.h"
#import "LoginManager.h"
#import "AccountInfoViewController.h"
#import "UniversalDevice.h"
#import "CloudSignUpViewController.h"

static NSInteger const kAccountSelectionButtonWidth = 32;
static NSInteger const kAccountSelectionButtongHeight = 32;

static NSInteger const kAccountRowNumber = 0;
static NSInteger const kNetworksStartRowNumber = 1;

static CGFloat const kDefaultFontSize = 18.0f;

static CGFloat const kAccountCellHeight = 60.0f;
static CGFloat const kAccountNetworkCellHeight = 50.0f;

@interface AccountsViewController ()
@property (nonatomic, assign) NSInteger expandedSection;
@end

@implementation AccountsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.title = NSLocalizedString(@"accounts.title", @"Accounts");
    self.tableView.emptyMessage = NSLocalizedString(@"accounts.empty", @"No Accounts");
    [self updateAccountList];
    
    UIBarButtonItem *addAccount = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(addAccount:)];
    self.navigationItem.rightBarButtonItem = addAccount;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountAdded:) name:kAlfrescoAccountAddedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountRemoved:) name:kAlfrescoAccountRemovedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountListUpdated:) name:kAlfrescoAccountUpdatedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(accountListUpdated:) name:kAlfrescoAccountsListEmptyNotification object:nil];
}

- (void)updateAccountList
{
    self.tableViewData = [NSMutableArray array];
    NSArray *allAccounts = [[AccountManager sharedManager] allAccounts];
    
    for (UserAccount *account in allAccounts)
    {
        if (account.accountType == UserAccountTypeOnPremise)
        {
            [self.tableViewData addObject:@[account]];
        }
        else
        {
            NSMutableArray *accountData = [NSMutableArray array];
            [accountData addObject:account];
            [accountData addObjectsFromArray:account.accountNetworks];
            [self.tableViewData addObject:accountData];
        }
    }
    
    [self.tableView reloadData];
}

#pragma mark - Notification Methods

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
}

- (void)accountAdded:(NSNotification *)notification
{
    [self updateAccountList];
}

- (void)accountRemoved:(NSNotification *)notification
{
    [self updateAccountList];
}

- (void)accountListUpdated:(NSNotification *)notification
{
    [self updateAccountList];
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self updateAccountList];
    [self hidePullToRefreshView];
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

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    CGFloat cellHeight = kAccountCellHeight;
    
    if (indexPath.row >= kNetworksStartRowNumber)
    {
        cellHeight = kAccountNetworkCellHeight;
    }
    
    return cellHeight;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AccountCellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (nil == cell)
    {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryView = [self createAccountSelectionButton];
    
    if (indexPath.row == kAccountRowNumber)
    {
        UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
        
        cell.textLabel.font = [UIFont systemFontOfSize:kDefaultFontSize];
        cell.textLabel.text = account.accountDescription;
        
        UIImage *accountTypeImage = [UIImage imageNamed:@"account-type-onpremise.png"];
        if (account.accountType == UserAccountTypeCloud)
        {
            accountTypeImage = [[UIImage imageNamed:@"account-type-cloud.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
            if (account.oauthData && ![account.oauthData.apiKey isEqualToString:CLOUD_OAUTH_KEY])
            {
                cell.imageView.tintColor = [UIColor redColor];
            }
            else
            {
                cell.imageView.tintColor = [UIColor appTintColor];
            }
        }
        
        cell.imageView.image = accountTypeImage;
        
        if (account.accountType != UserAccountTypeCloud)
        {
            [self updateAccountSelectionButtonImageForCell:cell isSelected:account.isSelectedAccount];
        }
        else
        {
            cell.accessoryView.hidden = YES;
        }
    }
    else
    {
        NSString *networkIdentifier = self.tableViewData[indexPath.section][indexPath.row];
        
        cell.textLabel.font = [UIFont systemFontOfSize:[UIFont systemFontSize]];
        cell.textLabel.text = networkIdentifier;
        cell.imageView.image = [UIImage imageNamed:@"empty_icon.png"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        
        UserAccount *account = self.tableViewData[indexPath.section][kAccountRowNumber];
        BOOL isSelectedNetwork = [account.selectedNetworkId isEqualToString:networkIdentifier];
        [self updateAccountSelectionButtonImageForCell:cell isSelected:isSelectedNetwork];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == kAccountRowNumber)
    {
        UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
        
        id viewController = nil;
        if (account.accountStatus == UserAccountStatusAwaitingVerification)
        {
            viewController = [[CloudSignUpViewController alloc] initWithAccount:account];
        }
        else if ((account.accountType == UserAccountTypeCloud) && (account.accountNetworks.count == 0))
        {
            [self showHUD];
            [[LoginManager sharedManager] attemptLoginToAccount:account networkId:nil completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
                [self hideHUD];
                if (successful)
                {
                    [[AccountManager sharedManager] selectAccount:account selectNetwork:account.accountNetworks.firstObject alfrescoSession:alfrescoSession];
                    [self updateAccountList];
                }
            }];
        }
        else
        {
            viewController = [[AccountInfoViewController alloc] initWithAccount:account accountActivityType:AccountActivityTypeEditAccount];
        }
        
        if (viewController)
        {
            NavigationViewController *accountInfoNavigationController = [[NavigationViewController alloc] initWithRootViewController:viewController];
            accountInfoNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
            [self presentViewController:accountInfoNavigationController animated:YES completion:nil];
        }
    }
    else
    {
        [tableView deselectRowAtIndexPath:indexPath animated:YES];
    }
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return (indexPath.row == kAccountRowNumber);
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountManager *accountManager = [AccountManager sharedManager];
    UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
    
    [accountManager removeAccount:account];
    [self updateAccountList];
}

#pragma mark - Add Account

- (void)addAccount:(id)sender
{
    AccountTypeSelectionViewController *accountTypeController = [[AccountTypeSelectionViewController alloc] init];
    NavigationViewController *addAccountNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountTypeController];
    addAccountNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:addAccountNavigationController animated:YES completion:nil];
}

#pragma mark - Private Methods

- (UIButton *)createAccountSelectionButton
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, kAccountSelectionButtonWidth, kAccountSelectionButtongHeight)];
    [button addTarget:self action:@selector(selectAccountButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    return button;
}

- (void)updateAccountSelectionButtonImageForCell:(UITableViewCell *)cell isSelected:(BOOL)isSelected
{
    UIImage *selectionImage = isSelected ? [UIImage imageNamed:@"green_selected_circle"] : [UIImage imageNamed:@"unselected_circle"];
    [(UIButton *)cell.accessoryView setBackgroundImage:selectionImage forState:UIControlStateNormal];
}

- (void)selectAccountButtonClicked:(UIButton *)sender
{
    UITableViewCell *selectedCell = (UITableViewCell *)sender.superview;
    
    BOOL foundAcccountCell = NO;
    while (!foundAcccountCell)
    {
        if (![selectedCell isKindOfClass:[UITableViewCell class]])
        {
            selectedCell = (UITableViewCell *)selectedCell.superview;
        }
        else
        {
            foundAcccountCell = YES;
        }
    }
    NSIndexPath *indexPathForSelectedCell = [self.tableView indexPathForCell:selectedCell];
    
    id item = self.tableViewData[indexPathForSelectedCell.section][indexPathForSelectedCell.row];
    UserAccount *account = nil;
    NSString *networkId = nil;
    
    if (indexPathForSelectedCell.row > kAccountRowNumber && [item isKindOfClass:[NSString class]])
    {
        account = self.tableViewData[indexPathForSelectedCell.section][kAccountRowNumber];
        networkId = (NSString *)item;
    }
    else
    {
        account = (UserAccount *)item;
    }
    
    if (account.accountType == UserAccountTypeOnPremise || networkId != nil)
    {
        [[LoginManager sharedManager] attemptLoginToAccount:account networkId:networkId completionBlock:^(BOOL successful, id<AlfrescoSession> alfrescoSession, NSError *error) {
            if (!successful)
            {
                displayErrorMessage([ErrorDescriptions descriptionForError:error]);
            }
            else
            {
                [[AccountManager sharedManager] selectAccount:account selectNetwork:networkId alfrescoSession:alfrescoSession];
                [self.tableView reloadData];
            }
        }];
    }
}

@end
