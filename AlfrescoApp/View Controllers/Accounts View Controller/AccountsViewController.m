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
#import "MainMenuViewController.h"

static NSInteger const kCellIndentationLevel = 2;
static NSInteger const kCellIndentationWidth = 30;

static NSInteger const kAccountRowNumber = 0;
static NSInteger const kNetworksStartRowNumber = 1;

@interface AccountsViewController ()
@property (nonatomic, assign) NSInteger expandedSection;
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
    
    self.title = NSLocalizedString(@"accounts.title", @"Accounts");
    [self updateAccountList];
    
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

- (void)updateAccountList
{
    self.tableViewData = [NSMutableArray array];
    NSArray *allAccounts = [[AccountManager sharedManager] allAccounts];
    
    for (UserAccount *account in allAccounts)
    {
        if (account.accountType == AccountTypeOnPremise)
        {
            [self.tableViewData addObject:@[account]];
        }
        else
        {
            [self.tableViewData addObject:[@[account] mutableCopy]];
        }
    }
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
    [self.tableView reloadData];
}

- (void)accountRemoved:(NSNotification *)notification
{
    [self updateAccountList];
    [self.tableView reloadData];
}

#pragma mark - UIRefreshControl Functions

- (void)refreshTableView:(UIRefreshControl *)refreshControl
{
    [self showLoadingTextInRefreshControl:refreshControl];
    [self updateAccountList];
    [self.tableView reloadData];
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

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *cellIdentifier = @"AccountCell";
    AccountCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (nil == cell)
    {
        cell = (AccountCell *)[[[NSBundle mainBundle] loadNibNamed:NSStringFromClass([AccountCell class]) owner:self options:nil] lastObject];
    }
    
    if (indexPath.row == kAccountRowNumber)
    {
        UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
        
        cell.textLabel.text = account.accountDescription;
        cell.imageView.image = (account.accountType == AccountTypeOnPremise) ? [UIImage imageNamed:@"server.png"] : [UIImage imageNamed:@"cloud.png"];
        
        if (account.isSelectedAccount)
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        else
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    else
    {
        NSString *identifier = self.tableViewData[indexPath.section][indexPath.row];
        cell.textLabel.text = identifier;
        cell.indentationWidth = kCellIndentationWidth;
        cell.indentationLevel = kCellIndentationLevel;
        cell.accessoryType = UITableViewCellAccessoryNone;
        
        UserAccount *account = self.tableViewData[indexPath.section][kAccountRowNumber];
        if ([account.selectedNetworkId isEqualToString:identifier])
        {
            [self.tableView selectRowAtIndexPath:indexPath animated:NO scrollPosition:UITableViewScrollPositionNone];
        }
        else
        {
            [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        }
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    id item = self.tableViewData[indexPath.section][indexPath.row];
    UserAccount *account = nil;
    NSString *networkId = nil;
    
    if (indexPath.row > kAccountRowNumber && [item isKindOfClass:[NSString class]])
    {
        account = self.tableViewData[indexPath.section][kAccountRowNumber];
        networkId = (NSString *)item;
        account.selectedNetworkId = (NSString *)item;
    }
    else
    {
        account = (UserAccount *)item;
    }
    
    [[AccountManager sharedManager] setSelectedAccount:account];
    
    if (account.accountType == AccountTypeCloud && networkId == nil)
    {
        if ([self.tableViewData[indexPath.section] count] > 1)
        {
            [self hideAccountNetworks];
        }
        else
        {
            // temporary calling this service until bug on AlfrescoCloudSession  is resolved connectWithOAuthData:networkIdentifer:completionBlock: does not hit completion block
            // unless it first authenticate cloud account using connectWithOAuthData:completionBlock:
            [self showHUD];
            [[LoginManager sharedManager] authenticateCloudAccount:account networkId:nil temporarySession:YES navigationConroller:self.navigationController completionBlock:^(BOOL successful) {
                [self hideHUD];
                if (successful)
                {
                    [self showAccountNetworksForAccount:account atIndexPath:(NSIndexPath *)indexPath];
                }
            }];
        }
    }
    else
    {
        [self showHUD];
        [[LoginManager sharedManager] attemptLoginToAccount:account networkId:networkId completionBlock:^(BOOL successful) {
            
            [self hideHUD];
            
            //[self showAccountNetworksForAccount:account atIndexPath:(NSIndexPath *)indexPath];
            if (account.accountType == AccountTypeOnPremise)
            {
                [self hideAccountNetworks];
            }
        }];
    }
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
    UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
    
    AccountInfoViewController *accountInfoController = [[AccountInfoViewController alloc] initWithAccount:account accountActivityType:AccountActivityTypeViewAccount];
    [UniversalDevice pushToDisplayViewController:accountInfoController usingNavigationController:self.navigationController animated:YES];
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    return YES;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    AccountManager *accountManager = [AccountManager sharedManager];
    UserAccount *account = self.tableViewData[indexPath.section][indexPath.row];
    
    [accountManager removeAccount:account];
    [self updateAccountList];
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

- (void)showAccountNetworksForAccount:(UserAccount *)account atIndexPath:(NSIndexPath *)indexPath
{
    [self hideAccountNetworks];
    self.expandedSection = indexPath.section;
    
    if (account.accountNetworks)
    {
        [self.tableViewData[indexPath.section] addObjectsFromArray:account.accountNetworks];
        
        NSMutableArray *indexPaths = [NSMutableArray array];
        for (int i = kNetworksStartRowNumber; i < [self.tableViewData[indexPath.section] count]; i++)
        {
            [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:indexPath.section]];
        }
        
        [self.tableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationTop];
    }
}

- (void)hideAccountNetworks
{
    if (self.expandedSection != NSNotFound && self.expandedSection < self.tableViewData.count)
    {
        NSMutableArray *tenants = self.tableViewData[self.expandedSection];
        
        if (tenants.count > 0)
        {
            NSMutableArray *indexPaths = [NSMutableArray array];
            for (int i = kNetworksStartRowNumber; i < tenants.count; i++)
            {
                [indexPaths addObject:[NSIndexPath indexPathForRow:i inSection:self.expandedSection]];
            }
            
            tenants = [@[tenants[0]] mutableCopy];
            
            [self.tableViewData replaceObjectAtIndex:self.expandedSection withObject:tenants];
            [self.tableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationLeft];
            self.expandedSection = NSNotFound;
        }
    }
}

@end
