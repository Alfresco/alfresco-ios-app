//
//  AccountsViewController.m
//  AlfrescoApp
//
//  Created by Mohamad Saeedi on 24/10/2013.
//  Copyright (c) 2013 Alfresco. All rights reserved.
//

#import "AccountsViewController.h"
#import "AccountManager.h"
#import "AccountCell.h"
#import "AccountTypeSelectionViewController.h"
#import "NavigationViewController.h"
#import "AccountInfoViewController.h"
#import "LoginManager.h"
#import "AccountInfoViewController.h"
#import "UniversalDevice.h"

@interface AccountsViewController ()

@end

@implementation AccountsViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:NSStringFromClass([self class]) bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
    
    self.title = NSLocalizedString(@"accounts.title", @"Accounts");
    self.tableViewData = [[[AccountManager sharedManager] allAccounts] mutableCopy];
    
    UIBarButtonItem *addAccount = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd
                                                                                target:self
                                                                                action:@selector(addAccount:)];
    self.navigationItem.rightBarButtonItem = addAccount;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountAdded:)
                                                 name:kAlfrescoAccountAddedNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(accountRemoved:)
                                                 name:kAlfrescoAccountRemovedNotification
                                               object:nil];
}

#pragma mark - Notification Methods

- (void)sessionReceived:(NSNotification *)notification
{
    id<AlfrescoSession> session = notification.object;
    self.session = session;
}

- (void)accountAdded:(NSNotification *)notification
{
    self.tableViewData = [[[AccountManager sharedManager] allAccounts] mutableCopy];
    [self.tableView reloadData];
}

- (void)accountRemoved:(NSNotification *)notification
{
    self.tableViewData = [[[AccountManager sharedManager] allAccounts] mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    self.tableViewData = [[[AccountManager sharedManager] allAccounts] mutableCopy];
    [self.tableView reloadData];
    [self hidePullToRefreshView];
}

#pragma mark - TableView Datasource

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.tableViewData.count;
}

-(UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AccountCell";
    AccountCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = (AccountCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AccountCell class]) owner:self options:nil] lastObject];
    }

    Account *account = self.tableViewData[indexPath.row];
    
    cell.textLabel.text = account.accountDescription;
    cell.imageView.image = (account.accountType == AccountTypeOnPremise) ? [UIImage imageNamed:@"server.png"] : [UIImage imageNamed:@"cloud.png"];
    
    if (account.isSelectedAccount)
    {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    else
    {
        cell.accessoryType = UITableViewCellAccessoryNone;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    Account *account = self.tableViewData[indexPath.row];
    [[AccountManager sharedManager] setSelectedAccount:account];
    
    [self.tableView reloadData];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    [[LoginManager sharedManager] attemptLoginToAccount:[[AccountManager sharedManager] selectedAccount]];
    
    AccountInfoViewController *accountInfoController = [[AccountInfoViewController alloc] initWithAccount:account accountActivityType:AccountActivityViewAccount];
    [UniversalDevice pushToDisplayViewController:accountInfoController usingNavigationController:self.navigationController animated:YES];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountManager *accountManager = [AccountManager sharedManager];
    Account *account = self.tableViewData[indexPath.row];
    
    [accountManager removeAccount:account];
    self.tableViewData = [[[AccountManager sharedManager] allAccounts] mutableCopy];
    [self.tableView reloadData];
}

#pragma mark - Add Account

- (void)addAccount:(id)sender
{
    AccountTypeSelectionViewController *accountTypeController = [[AccountTypeSelectionViewController alloc] init];
    NavigationViewController *addAccountNavigationController = [[NavigationViewController alloc] initWithRootViewController:accountTypeController];
    addAccountNavigationController.modalPresentationStyle = UIModalPresentationFormSheet;
    [self presentViewController:addAccountNavigationController animated:YES completion:nil];
}

@end
